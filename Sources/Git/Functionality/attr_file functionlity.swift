//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-02-15.
//

import Foundation



@inline(__always) public let GIT_ATTR_FILE          = ".gitattributes"
@inline(__always) public let GIT_ATTR_FILE_INREPO   = "attributes"
@inline(__always) public let GIT_ATTR_FILE_SYSTEM   = "gitattributes"
@inline(__always) public let GIT_ATTR_FILE_XDG      = "attributes"



public enum git_attr_fnmatch_flags: UInt32, OptionSet, AutoOptionSet {
    case __empty = 0
    
    case negative          = 0b0000_0000_0001 //1 << 0
    case directory         = 0b0000_0000_0010 //1 << 1
    case fullpath          = 0b0000_0000_0100 //1 << 2
    case macro             = 0b0000_0000_1000 //1 << 3
    case ignore            = 0b0000_0001_0000 //1 << 4
    case haswild           = 0b0000_0010_0000 //1 << 5
    case allowspace        = 0b0000_0100_0000 //1 << 6
    case icase             = 0b0000_1000_0000 //1 << 7
    case match_all         = 0b0001_0000_0000 //1 << 8
    case allowneg          = 0b0010_0000_0000 //1 << 9
    case allowmacro        = 0b0100_0000_0000 //1 << 10
}

@available(*, unavailable, renamed: "git_attr_fnmatch_flags.negative")
public var GIT_ATTR_FNMATCH_NEGATIVE: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.directory")
public var GIT_ATTR_FNMATCH_DIRECTORY: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.fullpath")
public var GIT_ATTR_FNMATCH_FULLPATH: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.macro")
public var GIT_ATTR_FNMATCH_MACRO: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.ignore")
public var GIT_ATTR_FNMATCH_IGNORE: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.haswild")
public var GIT_ATTR_FNMATCH_HASWILD: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.allowspace")
public var GIT_ATTR_FNMATCH_ALLOWSPACE: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.icase")
public var GIT_ATTR_FNMATCH_ICASE: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.match_all")
public var GIT_ATTR_FNMATCH_MATCH_ALL: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.allowneg")
public var GIT_ATTR_FNMATCH_ALLOWNEG: git_attr_fnmatch_flags { fatalError() }
@available(*, unavailable, renamed: "git_attr_fnmatch_flags.allowmacro")
public var GIT_ATTR_FNMATCH_ALLOWMACRO: git_attr_fnmatch_flags { fatalError() }

public extension git_attr_fnmatch_flags {
    static var GIT_ATTR_FNMATCH__INCOMING: Self { [.allowspace, .allowneg, .allowmacro] }
}



public func git_attr_get_many_with_session(
    repo: Repository,
    attr_session: git_attr_session,
    opts: git_attr_options,
    path pathname: String,
    num_attr: size_t,
    names: [String])
throws(GitError) -> [String]?
{
    var caughtError: GitError?
    var path: git_attr_path?
    var files = SelfSortingArray<AnyTypeProtocol>()
    var i, j, k: size_t
    var file: git_attr_file
    var rule: git_attr_rule
    var info: [attr_get_many_info]
    var num_found: size_t = 0
    var dir_flag: git_dir_flag = .GIT_DIR_FLAG_UNKNOWN
    
    func cleanup() throws(GitError) {
        path = nil
        info = []
        
        if let caughtError { throw caughtError }
    }
    
    
    guard 0 != num_attr else {
        return nil
    }
    
    try assert(expr: repo)
    try assert(expr: pathname)
    try assert(expr: names)
    try GIT_ERROR_CHECK_VERSION(structure: opts, expectedMax: GIT_ATTR_OPTIONS_VERSION, name: "git_attr_options")
    
    if repo.isBare {
        dir_flag = .GIT_DIR_FLAG_FALSE
    }
    
    do {
        if let nonBareWorkdir = repo.nonBareWorkdir {
            path = try git_attr_path__init(path: pathname, base: nonBareWorkdir, isDir: dir_flag)
        }
    }
    catch {
        throw GitError.generic
    }
    
    // TODO: Remove these temp functions
    func a() throws(GitError) {
        try collect_attr_files(repo: repo, session: attr_session, options: opts, path: pathname, files: files)
    }
    
    func b(error: GitError) throws(GitError) {
        
        caughtError = error
        try cleanup()
    }
    
    func e(do closure: () throws(GitError) -> Void,
           catch handler: (GitError) throws(GitError) -> Void)
    throws(GitError) {
        do {
            try closure()
        }
        catch where error.hasCodeButNotKind {
            try handler(error)
        }
        catch {}
    }
    
    
    func c() throws(GitError) {
        try handleErrorsWithCodesButNotKinds(do: a, catch: b)
    }
    
    try c()
    
    info = Array()
    info.reserveCapacity(num_attr)
    try GIT_ERROR_CHECK_ALLOC(info)
    
    for file in files {
        
        git_attr_file__foreach_matching_rule(file, &path, j, rule) {
            
        loop_k:
            for k in 0 ..< num_attr {
                var pos: size_t
                
                if (info[k].found != NULL) {/* already found assignment */
                    continue loop_k
                }
                
                if (!info[k].name.name) {
                    info[k].name.name = names[k];
                    info[k].name.name_hash = git_attr_file__name_hash(for: names[k]);
                }
                
                if (!git_vector_bsearch(&pos, &rule->assigns, &info[k].name)) {
                    info[k].found = (git_attr_assignment *)
                        git_vector_get(&rule->assigns, pos);
                    values[k] = info[k].found->value;

                    if (++num_found == num_attr)
                        return try cleanup()
                }
            }
        }
    }

    for (k = 0; k < num_attr; k++) {
        if (!info[k].found)
            values[k] = NULL;
    }
    
    return try cleanup()
}



//extern int git_attr_fnmatch__parse(
//    git_attr_fnmatch *spec,
//    git_pool *pool,
//    const char *source,
//    const char **base);
public func git_attr_fnmatch__parse(spec: git_attr_fnmatch, pool: git_pool, source: String?, base: inout String?) throws(GitError) {
    TODO
}



public func git_attr_file__parse_buffer(repo: Repository, attrs: inout git_attr_file, data: String, allow_macros: Bool) async throws(GitError) {
    var scan: String? = data
    var context: String? = nil
    
    
    func out(error: GitError?) throws(GitError) {
        if let error { throw error }
    }
    
    
    /* If subdir file path, convert context for file paths */
    if let entry = attrs.entry,
       case .notRooted = git_fs_path_root(entry.path),
       case .orderedSame = git__suffixcmp(str: entry.path, suffix: "/" + GIT_ATTR_FILE)
    {
        context = entry.path
    }
    
    try await attrs.lock.run { () throws(GitError) in
        while TODO {
            var rule = git_attr_rule(match: .init(flags: [.allowneg, .allowmacro]), assigns: [])
            
            /* Parse the next "pattern attr attr attr" line */
            do {
                try git_attr_fnmatch__parse(spec: rule.match, pool: attrs.pool, source: context, base: &scan)
                try git_attr_assignment__parse(repo: repo, pool: attrs.pool, assigns: rule.assigns, scan: &scan)
            }
            catch let error as GitError { // `as` here really shouldn't be required but the typed-throws in Swift is halfassed
                guard error.code == .objectNotFound else {
                    throw error
                }
            }
            catch {}
            
            if rule.match.flags.contains(.macro) {
                /* TODO: warning if macro found in file below repo root */
                guard allow_macros else { continue }
                try throwOnlyForErrorsWithCodesButNotKinds { () throws(_) in
                    try git_attr_cache__insert_macro(repo: repo, macro: rule)
                }
            }
            else {
                try throwOnlyForErrorsWithCodesButNotKinds { () throws(_) in
                    try attrs.rules.insert(.left(rule))
                }
            }
        }
    }
}




public func git_attr_file__name_hash(for name: String) throws(GitError) -> UInt32 {
    var h: UInt32 = 5381
    
    for byte in name.utf8 {
        h = (h &<< 5) &+ h &+ UInt32(byte)
    }
    
    return h
}



public func git_attr_path__free(info: inout git_attr_path?) {
    info?.full = nil
    info?.path = nil
    info?.basename = nil
}



public extension git_attr_file {
    /* loop over rules in file from bottom to top */
    mutating func iterateRulesFromBottomToTop(_ body: (inout git_attr_rule) -> Void) {
        for index in rules.contents.indices.reversed() {
            switch rules.contents[index] {
            case .left(var rule):
                body(&rule)
                rules.contents[index] = .left(rule)
            
            case .right(_):
                assertionFailure("Attempted to treat a FileName Match (`git_attr_fnmatch`) as a Rule (`git_attr_rule`)")
            }
        }
    }
}



//extern int git_attr_assignment__parse(
//    git_repository *repo, /* needed to expand macros */
//    git_pool *pool,
//    git_vector *assigns,
//    const char **scan);

public func git_attr_assignment__parse(
    repo: Repository,
    pool: Pool,
    assigns: SelfSortingArray<git_attr_assignment>,
    scan: inout String?) throws(GitError)
{
    TODO()
}



// MARK: - package conveniences

internal extension Bool {
    init(_ gitDirFlag: git_dir_flag) {
        switch gitDirFlag {
        case .GIT_DIR_FLAG_TRUE:
            self = true
        case .GIT_DIR_FLAG_FALSE:
            self = false
        case .GIT_DIR_FLAG_UNKNOWN:
            let message = "Unknown git flag used! Defaulting to `false`"
            assertionFailure(message)
            print(message)
            self = false
        }
    }
}



// MARK: - Private to `attr.c`

private struct attr_get_many_info: AnyStructProtocol {
    var name: git_attr_name
    var found: git_attr_assignment
}



// MARK: - Migration

@available(*, unavailable, renamed: "git_attr_file.iterateRulesFromBottomToTop")
public func git_attr_file__foreach_matching_rule(_: Any, _: Any, _: Any, _: Any, _: () -> Void) { fatalError() }
