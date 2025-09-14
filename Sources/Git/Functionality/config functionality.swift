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



@inline(__always)
public let GIT_CONFIG_FILENAME_SYSTEM = "gitconfig"



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
    
    
    /// Parse a string value as an Int64.
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
            guard value.endIndex <= parseResult.parseRange.upperBound else {
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
    
    
    /// Parse a string value as an Int32.
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
    static func parseInt32(_ value: String) throws(GitError) -> __int32_t {
        @inline(__always)
        var failParseError: GitError {
            GitError(message: "failed to parse '\(value)' as a 32-bit integer", kind: .config, code: .__generic)
        }
        
        
        let tmp = try mapError(try parseInt64(value)) { failParseError }
        
        let truncate = __int32_t(truncatingIfNeeded: tmp)
        guard truncate == tmp else {
            throw failParseError
        }
        
        return truncate
    }
}


/**
 * API for repository configmap-style lookups from config - not cached, but
 * uses configmap value maps and fallbacks
 */
public func git_config__configmap_lookup(config: Config, item: ConfigmapItem) throws(GitError) -> CInt {
    var error: GitError? = nil
    var data: map_data = _configmaps[item.rawValue]
    var entry: git_config_entry?
    
    entry = try handleErrorsWithCodesButNotKinds(
        do: { () throws(GitError) -> git_config_entry? in
            try git_config__lookup_entry(cfg: config, key: data.name, no_errors: false)
        },
        catch: { (error: GitError) throws(GitError) -> git_config_entry? in throw error }
    )
    
    
    if nil == entry {
        return data.default_value
    }
    else if let maps = data.maps {
        return try git_config_lookup_map_value(maps: maps, value: entry.value)
        return try git_config_lookup_map_value(
            maps, data.map_count, entry.value);
    }
    else {
        return try git_config_parse_bool(entry.value)
    }
}



public func git_config__normalize_name(_ in: String) throws(GitError) -> String {
    TODO
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
throws(GitError) -> Int {
    for m in maps {
        switch m.type {
        case .false, .true:
            if try Config.parseBool(value) == m.type {
                return m.map_value
            }
            
        case .int32:
            return Int(try Config.parseInt32(value))
            
        case .string:
            if 0 == strcasecmp(value, m.str_match) {
                return m.map_value
            }
        }
    }
    
    throw GitError(message: "failed to map '\(value)'", kind: .config, code: .generic)
}





// MARK: - Internal only

/// **For internal use only!**
/// This doesn't normalize the key, and returns `nil` if not found
internal func git_config__lookup_entry(
    cfg config: Config,
    key: String,
    no_errors: Bool)
throws(GitError) -> git_config_entry?
{
    try get_entry(
        config: config,
        name: key,
        normalize_name: false,
        want_errors: no_errors ? GET_NO_ERRORS : GET_NO_MISSING
    )
}



// MARK: - Private

private let GET_ALL_ERRORS = 0
private let GET_NO_MISSING = 1
private let GET_NO_ERRORS  = 2


private func config_error_notfound(name: String) -> GitError
{
    GitError(message: "config value '\(name)' was not found", kind: .config, code: .objectNotFound)
}



private func get_entry(
    config: Config,
    name: String,
    normalize_name: Bool,
    want_errors: Int)
throws(GitError)
-> git_config_entry?
{
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
    for entry in config.readers {
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



/**
 * A refcounted instance of a config_backend that can be shared across
 * a configuration instance, any snapshots, and individual configuration
 * levels (from `git_config_open_level`).
 */
private struct backend_instance {
    let rc: RefCount
    let backend: git_config_backend?
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
    let write_order: CInt
}



// MARK: - Migration


@available(*, unavailable, renamed: "Config.parseBool")
public func git_config_parse_bool(_: inout CInt, _: CharStar) -> CInt { fatalError() }
@available(*, unavailable, renamed: "Config.parseInt32")
public func git_config_parse_int32(_:inout __int32_t, _: CharStar) -> CInt { fatalError() }
@available(*, unavailable, renamed: "Config.parseInt64")
public func git_config_parse_int64(_:inout __int64_t, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function returns `git_config_entry` instead of taking an inout, and throws a `GitError` instead of returning a `CInt`")
public func git_config__lookup_entry(_: inout git_config_entry, _: git_config, _: CharStar, _: Bool) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function returns `String` instead of taking an inout, and throws a `GitError` instead of returning a `CInt`")
public func git_config__normalize_name(_: String, _: inout String) -> CInt { fatalError() }

@available(*, unavailable, message: "The Swift version of this function returns an `Int` instead of taking an inout, throws a `GitErrro` instead of returning an error code, and no longer takes a `size_t` parameter for the array length, since Swift tracks array bounds internally")
public func git_config_lookup_map_value( _: inout CInt, _: [git_configmap], _: size_t, _: CharStar) -> CInt { fatalError() }
