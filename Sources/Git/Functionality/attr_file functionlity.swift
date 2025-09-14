//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-02-15.
//

import Foundation



public let GIT_ATTR_FILE          = ".gitattributes"



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
