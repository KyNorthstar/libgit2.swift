//
// crlf functionality.swift
//
// Written by Ky on 2025-01-04.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

import SafeCollectionAccess
import StringIntegerAccess



@inline(__always) public let GIT_CONFIG_FILENAME_SYSTEM = "gitconfig"
@inline(__always) public let GIT_CONFIG_BACKEND_VERSION: UInt = 1



public extension Config {
    
    /**
     * Allocate & initialize a new configuration object
     *
     * This object is empty, so you have to add a file to it before you
     * can do anything with it.
     *
     * - Throws: Nothing or an error
     */
    init() throws(GitError) {
        var config: Config
        
        config.readers = try .init(comparator: reader_cmp)
        
        if (git_vector_init(&config->readers, 8, reader_cmp) < 0 ||
            git_vector_init(&config->writers, 8, writer_cmp) < 0) {
            config_free(config);
            return -1;
        }

        GIT_REFCOUNT_INC(config);

        self = config
    }
}



// MARK: Parsing

public extension Config {
    
    /// Parse a string value as a bool.
    ///
    /// Valid values for true:
    /// - "true", "yes", "on"
    /// - 1 or any non-zero number
    ///
    /// Valid values for false:
    /// - "false", "no", "off"
    /// - 0
    ///
    /// When parsing as a number, this also follows the same rules as ``FixedWidthInteger/parse(gitNumberString:base:)``.
    ///
    /// - Parameter value: The string to parse
    /// - Returns: The parsed boolean value
    /// - Throws: `GitError` if the string cannot be parsed as a boolean
    // Analogous to `git_config_parse_bool`
    static func parseBool(_ value: String) throws(GitError) -> Bool {
        do {
            return try (try? .parse(gitBoolString: value))
                ?? (try (parseInt32(value) != 0))
        }
        catch {
            throw .init(message: "failed to parse '\(value)' as a boolean value", kind: .config, code: .__generic)
        }
        
        // The above code translates this original C code:
        //
        // int git_config_parse_bool(int *out, const char *value)
        // {
        //     if (git__parse_bool(out, value) == 0)
        //         return 0;
        //
        //     if (git_config_parse_int32(out, value) == 0) {
        //         *out = !!(*out);
        //         return 0;
        //     }
        //
        //     git_error_set(GIT_ERROR_CONFIG, "failed to parse '%s' as a boolean value", value);
        //     return -1;
        // }
    }
    
    
    /// Parse a string value as an `Int64`.
    ///
    /// An optional value suffix of `'k'`, `'m'`, or `'g'` will cause the value to be multiplied by `1024`, `1048576`, or `1073741824` prior to output.
    ///
    /// For example, `"123k"` parses as `125952`.
    ///
    /// This also follows the same rules as ``FixedWidthInteger/parse(gitNumberString:base:)``.
    ///
    /// - Parameter value: value to parse
    /// - Returns: the result of the parsing
    /// - Throws: an error if parsing failed
    // Analogous to `git_config_parse_int64`
    static func parseInt64(_ value: String) throws(GitError) -> __int64_t { // TODO: Test
        @inline(__always)
        var failParseError: GitError {
            GitError(message: "failed to parse '\(value)' as an integer", kind: .config, code: .__generic)
        }
        
        
        let parseResult = Int64.parse(gitNumberString: value, base: nil)
        let num_end = value[orNil: parseResult.parseRange.upperBound]
        var num = try parseResult.parsed.mapError({ _ in failParseError }).get()
        
        switch (num_end) {
        case "g", "G":
            num *= 1024
            fallthrough
            
        case "m", "M":
            num *= 1024
            fallthrough
            
        case "k", "K":
            num *= 1024
            
            /* check that that there are no more characters after the
             * given modifier suffix */
            guard value.endIndex < parseResult.parseRange.upperBound else {
                throw GitError(
                    message: "Integer string was a valid integer, but contained characters after the digits & SI suffix",
                    code: GitError.Code.__generic)
            }
            
            fallthrough
            
        case nil:
            return num
            
        default:
            throw failParseError
        }
    }
    
    
    /// Parse a string value as an `Int32`.
    ///
    /// An optional value suffix of `'k'`, `'m'`, or `'g'` will cause the value to be multiplied by 1024, 1048576, or 1073741824 prior to output.
    ///
    /// For example, `"123k"` parses as `125952`.
    ///
    /// This also follows the same rules as ``FixedWidthInteger/parse(gitNumberString:base:)``.
    ///
    /// - Parameter value: value to parse
    /// - Returns: the result of the parsing
    /// - Throws An error if parsing failed.
    // Analogous to `git_config_parse_int32`
    static func parseInt32(_ value: String) throws(GitError) -> Int32 {
        @inline(__always)
        var failParseError: GitError {
            GitError(message: "failed to parse '\(value)' as a 32-bit integer", kind: .config, code: .__generic)
        }
        
        
        let tmp = try mapError(try parseInt64(value)) { failParseError }
        
        let truncate = Int32(truncatingIfNeeded: tmp)
        guard truncate == tmp else {
            throw failParseError
        }
        
        return truncate
    }
    
    
    /// Parse a string value as an `Int`.
    ///
    /// An optional value suffix of `'k'`, `'m'`, or `'g'` will cause the value to be multiplied by 1024, 1048576, or 1073741824 prior to output.
    ///
    /// For example, `"123k"` parses as `125952`.
    ///
    /// This also follows the same rules as ``FixedWidthInteger/parse(gitNumberString:base:)``.
    ///
    /// - Parameter value: value to parse
    /// - Returns: the result of the parsing
    /// - Throws An error if parsing failed.
    // Analogous to `git_config_parse_int32`
    static func parseInt(_ value: String) throws(GitError) -> Int {
        Int(try parseInt64(value))
    }
    
    
    /**
     * API for repository configmap-style lookups from config - not cached, but
     * uses configmap value maps and fallbacks
     */
    func git_config__configmap_lookup(item: ConfigmapItem) throws(GitError) -> Int {
        var data: map_data = _configmaps[item.rawValue]
        var entry: git_config_entry?
        
        try throwOnlyForErrorsWithCodesButNotKinds { () throws(GitError) -> Void in
            entry = try git_config__lookup_entry(key: data.name, no_errors: false)
        }
        
        
        guard let entry else {
            return data.default_value.rawValue
        }
        
        if let maps = data.maps {
            return try git_config_lookup_map_value(maps: maps, value: entry.value).rawValue
        }
        else {
            return switch try Config.parseBool(entry.value) {
            case true:  git_configmap_t.true.rawValue
            case false: git_configmap_t.false.rawValue
            }
        }
    }
    
    
    mutating func set_writeorder(levels: [git_config_level_t])
    throws(GitError) {
        let entry: backend_entry
        
        try assert(expr: levels.count < INT_MAX) // What did INT_MAX mean? It was clearly being used as a magic
        
        for (i, element) in self.readers.enumerated() {
            guard element is backend_entry else {
                print("⚠️ While snapshotting a config, one of the reader entries was not of type `backend_entry`. Skipping...")
                continue
            }
            
            var entry: backend_entry {
                get { self.readers[i] as! backend_entry }
                set { self.readers[i] = newValue }
            }
            
            var found = false
            
            for j in levels.indices {
                if levels[j] == entry.level {
                    entry.write_order = j
                    found = true
                    break
                }
            }
            
            if !found {
                entry.write_order = -1;
            }
        }
        
        git_vector_sort(&writers);
        
        return 0;
    }
    
    
    /**
     * Create a snapshot of the configuration
     *
     * Create a snapshot of the current state of a configuration, which
     * allows you to look into a consistent view of the configuration for
     * looking up complex values (e.g. a remote, submodule).
     *
     * The string returned when querying such a config object is valid
     * until it is freed.
     *
     * - Parameter config: configuration to snapshot
     * - Returns: 0 or an error code
     */
    func git_config_snapshot(config in: inout Config) throws(GitError) -> Config {
        var i: size_t
        var entry: backend_entry
        var config: Config
        
        //var `in` = `in`
        var out: Config? = nil
        
        try handleErrorsWithCodesButNotKinds { () throws(GitError) -> Void in
            config = try Config()
        }
        catch: { (_) throws(GitError) -> Void in
            throw .generic
        }
        
        for (i, entry) in `in`.readers.enumerated() {
            guard let entry = entry as? backend_entry else {
                print("⚠️ While snapshotting a config, one of the reader entries was not of type `backend_entry`. Skipping...")
                continue
            }
            
            do {
                guard let b = try entry.instance?.backend?.snapshot() else { break }
                try git_config_add_backend(config: config, file: b, level: entry.level, repo: nil, force: false)
            }
            catch {
                break
            }
        }
        
        config.set_writeorder(nil, 0)
        
        if (error < 0)
            git_config_free(config);
        else
            *out = config;
        
        return error;
    }
}




/* Take something the user gave us and make it nice for our hash function */
// Ky 2025-09-28: For some reason, the original function doesn't normalize anything between the first & last `"."` characters...
public func git_config__normalize_name(_ in: String) throws(GitError) -> String {
    let name: String
    let fdot: String
    let ldot: String
    
    var invalid: GitError {
        GitError(message: "invalid config item name '\(`in`)'", kind: .config, code: .badRefspecFormat)
    }
    
    name = `in`
    
    guard let firstDotIndex = name.firstIndex(of: "."),
          let lastDotIndex  = name.lastIndex(of: "."),
          firstDotIndex != name.startIndex,
          lastDotIndex < name.endIndex
    else {
        throw invalid
    }
    
    
    /* Validate and downcase up to first dot and after last dot */
    do {
        name = try normalize_section(start: name.startIndex, end: firstDotIndex, in: name)
        name = try normalize_section(start: name.index(after: lastDotIndex), end: nil, in: name)
    }
    catch {
        throw invalid
    }
    
    /* If there is a middle range, make sure it doesn't have newlines */
    guard !name[firstDotIndex ..< lastDotIndex].contains("\n") else {
        throw invalid
    }
    
    return name
}




/**
 * Maps a string value to an integer constant
 *
 * - Parameter maps:  array of `git_configmap` objects specifying the possible mappings
 * - Parameter value: value to parse
 * - Returns the result of the parsing
 * - Throws an error code.
 */
public func git_config_lookup_map_value(
    maps: [git_configmap],
    value: String)
throws(GitError) -> ConfigmapValue {
    for m in maps {
        switch m.type {
        case .false, .true:
            if try Config.parseBool(value) == m.type {
                return m.map_value
            }
            
        case .int32:
            return ConfigmapValue(rawValue: try Config.parseInt(value))
            
        case .string:
            if 0 == strcasecmp(value, m.str_match) {
                return m.map_value
            }
        }
    }
    
    throw GitError(message: "failed to map '\(value)'", kind: .config, code: .generic)
}



/**
 * Add a generic config file instance to an existing config
 *
 * Note that the configuration object will free the file automatically.
 *
 * Further queries on this config object will access each of the config file instances in order (instances with a higher priority level will be accessed first).
 *
 * - Parameter config: the configuration to add the file to
 * - Parameter file: the configuration file (backend) to add
 * - Parameter level: the priority level of the backend
 * - Parameter repo: _optional_ - repository to allow parsing of conditional includes
 * - Parameter force: if a config file already exists for the given priority level, replace it
 * - Throws: Nothing on success, `GIT_EEXISTS` when adding more than one file for a given priority level (and `force` set to `false`), or another error
 */
public func git_config_add_backend(
    config: Config,
    file backend: git_config_backend,
    level: git_config_level_t,
    repo: Repository? = nil,
    force: Bool)
throws(GitError) {
    let instance: backend_instance
    let result: Int

    try GIT_ERROR_CHECK_VERSION(version: backend.version, expectedMax: GIT_CONFIG_BACKEND_VERSION, name: "git_config_backend");

    try backend.open(level: level, repo: repo)

    instance = backend_instance(backend: backend)

    instance.backend?.cfg = config;
    
    try git_config__add_instance(config, instance, level, force)

    if ((result = git_config__add_instance(config, instance, level, force)) < 0) {
        git__free(instance);
        return result;
    }
}





// MARK: - Internal only

internal extension Config {
    
    /// **For internal use only!**
    /// This doesn't normalize the key, and returns `nil` if not found
    func git_config__lookup_entry(
        key: String,
        no_errors: Bool)
    throws(GitError) -> git_config_entry?
    {
        try get_entry(
            name: key,
            normalize_name: false,
            want_errors: no_errors ? GET_NO_ERRORS : GET_NO_MISSING
        )
    }
}



// MARK: - Private

private let GET_ALL_ERRORS = 0
private let GET_NO_MISSING = 1
private let GET_NO_ERRORS  = 2


private func config_error_notfound(name: String) -> GitError
{
    GitError(message: "config value '\(name)' was not found", kind: .config, code: .objectNotFound)
}



private func reader_cmp(a: backend_entry, b: backend_entry) -> ComparisonResult
{
    b.level.rawValue <~> a.level.rawValue
}

private func writer_cmp(a: backend_entry, b: backend_entry) -> ComparisonResult
{
    b.write_order <~> a.write_order
}



private extension Config {
    
    func try_remove_existing_backend(
        level: git_config_level_t)
    {
        let entry: backend_entry
        let found: backend_entry?
        let i: size_t

        git_vector_foreach(&config.readers, i, entry) {
            if (entry->level == level) {
                git_vector_remove(&config->readers, i);
                found = entry;
                break;
            }
        }

        if (!found)
            return;

        git_vector_foreach(&config->writers, i, entry) {
            if (entry->level == level) {
                git_vector_remove(&config->writers, i);
                break;
            }
        }

        GIT_REFCOUNT_DEC(found->instance, backend_instance_free);
        git__free(found);
    }
    
    
    mutating func add_instance(
        instance: backend_instance,
        level: git_config_level_t,
        force: Bool)
    throws(GitError)
    {
        /* delete existing config backend for level if it exists */
        if force {
            try_remove_existing_backend(self, level)
        }
        
        let entry = backend_entry(
            instance: instance,
            level: level,
            write_order: level.rawValue
        )

        try git_vector_insert_sorted(&self.readers, entry, &duplicate_level)
        try git_vector_insert_sorted(&self.writers, entry, nil)

        GIT_REFCOUNT_INC(entry.instance)
    }
    
    
    func get_entry(
        name: String,
        normalize_name: Bool,
        want_errors: Int)
    throws(GitError)
    -> git_config_entry? {
        let entry: backend_entry
        var res: GitError? = .init(code: .objectNotFound)
        var key: String? = name
        var normalized: String? = nil
        
        func cleanup() throws(GitError) {
            if case .objectNotFound = res?.code {
                res = (want_errors > GET_ALL_ERRORS) ? nil : config_error_notfound(name: name);
            }
            else if nil != res,
                    want_errors == GET_NO_ERRORS
            {
                res = nil
            }
            
            if let res {
                throw res
            }
        }
        
        if normalize_name {
            do {
                normalized = try git_config__normalize_name(name)
            }
            catch {
                if nil != error.code, nil == error.kind {
                    try cleanup()
                    return nil
                }
            }
            
            key = normalized
        }
        
        res = .init(code: GitError.Code.objectNotFound)
        for entry in self.readers {
            guard let entry = entry as? backend_entry else { continue }
            guard let backend = entry.instance?.backend else {
                throw gitAssertFailure()
            }
            
            do {
                return try backend.get(key: key)
            }
            catch {
                res = error
            }
            
            guard case .objectNotFound = res?.code else {
                break
            }
        }
        
        try cleanup()
        return nil
    }
}


private func normalize_section(start: String.Index, end: String.Index?, in fullString: String) throws(GitError) -> String
{
    guard start != end else {
        throw .badRefspecFormat
    }
    var fullString = fullString
    var scannedIndex = start
    while var scanningIndex = fullString.indexOrNil(after: scannedIndex) {
        scannedIndex = scanningIndex
        
        guard var scanningChar = fullString[orNil: scanningIndex] else { break }
        
        if CharacterSet.alphanumerics.contains(scanningChar) {
            fullString.replaceCharacters(in: scannedIndex...scannedIndex, with: scanningChar.lowercased())
        }
        else if "-" != scanningChar || start == scanningIndex {
            throw .badRefspecFormat
        }
    }
    
    if start == scannedIndex {
        throw .badRefspecFormat
    }
    
    return fullString
}



/**
 * A refcounted instance of a config_backend that can be shared across
 * a configuration instance, any snapshots, and individual configuration
 * levels (from `git_config_open_level`).
 */
private struct backend_instance {
    var rc: RefCount?
    var backend: git_config_backend?
}



/**
 * An entry in the readers or writers vector in the configuration.
 * This is kept separate from the refcounted instance so that different
 * views of the configuration can have different notions of levels or
 * write orders.
 *
 * (eg, a standard configuration has a priority ordering of writers, a
 * snapshot has *no* writers, and an individual level has a single
 * writer.)
 */
private struct backend_entry: AnyStructProtocol {
    let instance: backend_instance?
    let level: git_config_level_t
    var write_order: Int
}



// MARK: - Migration


@available(*, unavailable, renamed: "Config.parseBool")
public func git_config_parse_bool(_: inout CInt, _: CharStar) -> CInt { fatalError() }
@available(*, unavailable, renamed: "Config.parseInt32")
public func git_config_parse_int32(_:inout __int32_t, _: CharStar) -> CInt { fatalError() }
@available(*, unavailable, renamed: "Config.parseInt64")
public func git_config_parse_int64(_:inout __int64_t, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function is a member of `Config` rather than taking an inout, returns `git_config_entry` instead of taking an inout, and throws a `GitError` instead of returning a `CInt`")
internal func git_config__lookup_entry(_: inout git_config_entry, _: git_config, _: CharStar, _: Bool) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function returns `String` instead of taking an inout, and throws a `GitError` instead of returning a `CInt`")
public func git_config__normalize_name(_: String, _: inout String) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function returns an `Int` instead of taking an inout, throws a `GitError` instead of returning an error code, and no longer takes a `size_t` parameter for the array length, since Swift tracks array bounds internally")
public func git_config_lookup_map_value( _: inout CInt, _: [git_configmap], _: size_t, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, renamed: "config.git_config__configmap_lookup(item:)", message: "The Swift version of this function is a member of `Config` rather than taking an inout, returns `git_config_entry` instead of taking an inout `CInt`, and throws a `GitError` instead of returning a `CInt`")
public func git_config__configmap_lookup(_: inout CInt, _: git_config, _: git_configmap_item) -> CInt { fatalError() }

@available(*, unavailable, renamed: "Config.init()")
public func git_config_new(_: inout git_config) -> Void { fatalError() }

@available(*, unavailable, renamed: "config.add_instance(_:level:force:)", message: "The Swift version of this function is a member of `Config` rather than taking an inout, and throws a `GitError` instead of returning a `CInt")
private func git_config__add_instance(_:inout git_config, _:backend_instance, _:git_config_level_t, _:Int) -> CInt { fatalError() }


@available(*, unavailable, renamed:  "config.try_remove_existing_backend(level:)", message: "The Swift version of this function is a member of `Config` rather than taking an inout")
private func try_remove_existing_backend(_:inout git_config, _:git_config_level_t) { fatalError() }

@available(*, unavailable, renamed: "config.set_writeorder(levels:)", message: "The Swift version of this function is a member of `Config` rather than taking an inout, treats the `levels` parameter as an array (dropping the `size_t` parameter), and throws a `GitError` instead of returning a `CInt`")
public func git_config_set_writeorder(_:inout git_config, _:git_config_level_t, _:size_t) -> CInt { fatalError() }
