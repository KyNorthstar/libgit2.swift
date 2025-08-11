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
    var info: attr_get_many_info? = nil
    var num_found: size_t = 0
    var dir_flag: git_dir_flag = .GIT_DIR_FLAG_UNKNOWN
    
    func cleanup() throws(GitError) -> [String]? {
        path = nil
        info = nil
        
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
    
    do {
        collect_attr_files(repo, attr_session, opts, pathname, &files)
    }
    catch where nil != error.code && nil == error.kind {
        caughtError = error
        return try cleanup()
    }

    info = git__calloc(num_attr, sizeof(attr_get_many_info));
    GIT_ERROR_CHECK_ALLOC(info);

    git_vector_foreach(&files, i, file) {

        git_attr_file__foreach_matching_rule(file, &path, j, rule) {

            for (k = 0; k < num_attr; k++) {
                size_t pos;

                if (info[k].found != NULL) /* already found assignment */
                    continue;

                if (!info[k].name.name) {
                    info[k].name.name = names[k];
                    info[k].name.name_hash = git_attr_file__name_hash(names[k]);
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



public func git_attr_path__free(info: inout git_attr_path?) {
    info?.full = nil
    info?.path = nil
    info?.basename = nil
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
