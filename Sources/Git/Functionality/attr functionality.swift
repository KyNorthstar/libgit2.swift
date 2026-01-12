//
// attr functionality.swift
//
// Written by Ky on 2025-02-14.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public let GIT_ATTR_OPTIONS_VERSION: Versioned.Version = 1
public var GIT_ATTR_OPTIONS_INIT: git_attr_options { .init(version: GIT_ATTR_OPTIONS_VERSION, flags: []) }



private func collect_attr_files(
    repo: Repository,
    session attr_session: git_attr_session,
    options opts: git_attr_options,
    path: String,
    files: SelfSortingArray<TODO>) // TODO: Use actual type
throws(GitError)
{
    var error: GitError? = nil
    var dir: String?
    var attrfile = String()
    let workdir = repo.nonBareWorkdir
    var info = attr_walk_up_info()
    
    
    func cleanup(error: GitError?) throws(GitError) {
        if let error { throw error }
    }
    
    
    try assert(expr: !git_fs_path_is_absolute(path: path))
    
    do {
        try attr_setup(repo: repo, attr_session: attr_session, opts: opts)
    }
    catch where error.code != nil
             && error.kind == nil {
        throw error
    }
    catch {}
    
    do {
        /* Resolve path in a non-bare repo */
        if nil != workdir {
            dir = git_fs_path_find_dir(dir: try git_repository_workdir_path(repo: repo, path: path))
        }
        else {
            dir = try git_fs_path_dirname_r(path: path)
        }
    }
    catch {
        return try cleanup(error: error)
    }
    
    /* in precedence order highest to lowest:
     * - $GIT_DIR/info/attributes
     * - path components with .gitattributes
     * - config core.attributesfile
     * - $GIT_PREFIX/etc/gitattributes
     */
    
    try handleErrorsWithCodesButNotKinds { () throws(_) in
        attrfile = try repo.git_repository__item_path(item: .info)
    }
    catch: { (error: _) throws(_) -> Void in
        try handleErrorsWithCodesButNotKinds { () throws(_) -> Void in
            try repo.push_attr_file(attr_session: attr_session, list: files, base: attrfile, filename: GIT_ATTR_FILE_INREPO)
        }
        catch: { (error: _) throws(_) -> Void in
            return try cleanup(error: error)
        }
    }
    
    
    info.repo = repo;
    info.attr_session = attr_session;
    info.opts = opts;
    info.workdir = workdir;
    info.index = repo.index
    info.files = files;
    
    do {
        try throwOnlyForErrorsWithCodesButNotKinds { () throws(_) in
            if 0 == strcmp(dir, ".") {
                try push_one_attr(onto: &info, path: "")
            }
            else {
                try git_fs_path_walk_up(&dir, workdir, push_one_attr, &info);
            }
        }
    }
    catch error {
        if (error < 0)
            goto cleanup;
    }

    if (git_repository_attr_cache(repo)->cfg_attr_file != NULL) {
        error = push_attr_file(repo, attr_session, files, NULL, git_repository_attr_cache(repo)->cfg_attr_file);
        if (error < 0)
            goto cleanup;
    }

    if (!opts || (opts->flags & GIT_ATTR_CHECK_NO_SYSTEM) == 0) {
        error = system_attr_file(&dir, attr_session);

        if (!error)
            error = push_attr_file(repo, attr_session, files, NULL, dir.ptr);
        else if (error == GIT_ENOTFOUND)
            error = 0;
    }
}



internal func attr_setup(
    repo: Repository,
    attr_session: git_attr_session?,
    opts: git_attr_options)
throws(GitError)
{
    let system = String()
    let info = String()
    let index_source = git_attr_file_source(type: .GIT_ATTR_FILE_SOURCE_INDEX, base: nil, filename: GIT_ATTR_FILE, commit_id: nil)
    let head_source = git_attr_file_source(type: .GIT_ATTR_FILE_SOURCE_HEAD, base: nil, filename: GIT_ATTR_FILE, commit_id: nil)
    let commit_source = git_attr_file_source(type: .GIT_ATTR_FILE_SOURCE_COMMIT, base: nil, filename: GIT_ATTR_FILE, commit_id: nil)
    var idx: Index
    var workdir: String
    var error: GitError? = nil

    if let attr_session,
       0 != attr_session.init_setup
    {
        return
    }
    
    do {
        try git_attr_cache__init(repo: repo)
    }
    catch where error.hasCodeButNotKind {
        throw error
    }
    catch {}
    
    
    /*
     * Preload attribute files that could contain macros so the
     * definitions will be available for later file parsing.
     */

    if ((error = system_attr_file(&system, attr_session)) < 0 ||
        (error = preload_attr_file(repo, attr_session, NULL, system.ptr)) < 0) {
        if (error != GIT_ENOTFOUND)
            goto out;

        error = 0;
    }

    if ((error = preload_attr_file(repo, attr_session, NULL,
                                   git_repository_attr_cache(repo)->cfg_attr_file)) < 0)
        goto out;

    if ((error = git_repository__item_path(&info, repo, GIT_REPOSITORY_ITEM_INFO)) < 0 ||
        (error = preload_attr_file(repo, attr_session, info.ptr, GIT_ATTR_FILE_INREPO)) < 0) {
        if (error != GIT_ENOTFOUND)
            goto out;

        error = 0;
    }

    if ((workdir = git_repository_workdir(repo)) != NULL &&
        (error = preload_attr_file(repo, attr_session, workdir, GIT_ATTR_FILE)) < 0)
            goto out;

    if ((error = git_repository_index__weakptr(&idx, repo)) < 0 ||
        (error = preload_attr_source(repo, attr_session, &index_source)) < 0) {
        if (error != GIT_ENOTFOUND)
            goto out;

        error = 0;
    }

    if ((opts && (opts->flags & GIT_ATTR_CHECK_INCLUDE_HEAD) != 0) &&
        (error = preload_attr_source(repo, attr_session, &head_source)) < 0)
        goto out;

    if ((opts && (opts->flags & GIT_ATTR_CHECK_INCLUDE_COMMIT) != 0)) {
#ifndef GIT_DEPRECATE_HARD
        if (opts->commit_id)
            commit_source.commit_id = opts->commit_id;
        else
#endif
        commit_source.commit_id = &opts->attr_commit_id;

        if ((error = preload_attr_source(repo, attr_session, &commit_source)) < 0)
            goto out;
    }

    if (attr_session)
        attr_session->init_setup = 1;

    func out(error: GitError?) throws(GitError) {
        if let error { throw error }
    }
}



// MARK: - Private functionality

@available(*, unavailable, message: "Swift automatically manages memory")
private func release_attr_files<T: Sendable>(_: inout SelfSortingArray<T>) { fatalError() }



private extension Repository {
    func push_attr_source(
        attrSession: git_attr_session?,
        list: SelfSortingArray<Never>,
        source: git_attr_file_source,
        allowMacros: Bool)
    throws(GitError) {
        var file: git_attr_file? = nil
        
        try throwOnlyForErrorsWithCodesButNotKinds { () throws(_) in
            file = try git_attr_cache__get(
                repo: self,
                attr_session: attrSession,
                source: source,
                parser: git_attr_file__parse_buffer,
                allow_macros: allowMacros)
            file = try self.git_attr_cache__get(attrSession,
                                        source,
                                        git_attr_file__parse_buffer,
                                        allowMacros);
        }
        
        if (file != NULL) {
            if ((error = git_vector_insert(list, file)) < 0)
                git_attr_file__free(file);
        }
        
        return error;
    }
}



private func attr_decide_sources(
    flags: git_attr_check,
    has_wd: Bool,
    has_index: Bool,
    srcs: inout [git_attr_file_source_t])
-> Int
{
    var count = 0
    
    // The original C code switched over `flags & 0x03`, but I'm unsure why.
    // Since that's the same as `& 0b11`, all that does is mask all except the bottom two bits...
    // which, I suppose does constrain it so that the contents of this `switch` match all possible values of its input.. but that's not required.
    // I assume that this was some C-specific optimization, perhaps to do with casting or lookup tables.
    // I'll just use the strongly-typed option set.
    //
    // – Ky 2026-01-11
    if flags.contains(.GIT_ATTR_CHECK_FILE_THEN_INDEX) {
        if has_wd {
            srcs[count] = .file
            count += 1
        }
        if has_index {
            srcs[count] = .index
            count += 1
        }
    }
    else if flags.contains(.GIT_ATTR_CHECK_INDEX_THEN_FILE) {
        if has_index {
            srcs[count] = .index
            count += 1
        }
        if has_wd {
            srcs[count] = .file
            count += 1
        }
    }
    else if flags.contains(.GIT_ATTR_CHECK_INDEX_ONLY) {
        if has_index {
            srcs[count] = .index
            count += 1
        }
    }
    
    if flags.contains(.GIT_ATTR_CHECK_INCLUDE_HEAD) {
        srcs[count] = .head
        count += 1
    }

    if flags.contains(.GIT_ATTR_CHECK_INCLUDE_COMMIT) {
        srcs[count] = .commit
        count += 1
    }

    return count;
}



// Unsure why but the original C used `void*` here instead of `attr_walk_up_info*` – Ky 2026-01-11
private func push_one_attr(onto ref: inout attr_walk_up_info, path: String) throws(GitError) {
    let info = ref
    var src = [git_attr_file_source_t]()
    let n_src: Int
    let i: Int
    let allow_macros: Bool
    var lastError: GitError? = nil
    
    n_src = attr_decide_sources(flags: info.opts?.flags ?? .__empty,
                                has_wd: info.workdir != nil,
                                has_index: info.index != nil,
                                srcs: &src)
    
    allow_macros = info.workdir.map({ 0 == strcmp($0, path) }) ?? false
    
    //for (i = 0; !error && i < n_src; ++i) {
    for i in 0 ..< n_src {
        //git_attr_file_source source = { src[i], path, GIT_ATTR_FILE };
        var source = git_attr_file_source(type: src[i], base: path, filename: GIT_ATTR_FILE)
        
        if case .commit = src[i],
           let opts = info.opts
        {
            source.commit_id = opts.attr_commit_id
        }
        
        do {
            try info.repo?.push_attr_source(attr_session: info.attr_session, list: info.files,
                                 source: source, allow_macros: allow_macros)
        }
        catch {
            // The original code seems to ignore errors when it comes to processing this loop, and then thtow the last error it encountered after the loop has completed.
            // I'm trying to replicate that assuming it's intended behavior.
            //
            // – Ky 2026-01-11
            lastError = error
        }
    }
    
    if let lastError {
        throw lastError
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "repo.push_attr_source(attr_session:list:source:allow_macros:)", message: "The Swift version of this is a member on `Repository`")
private func push_attr_source(
    repo: git_repository,
    attr_session: git_attr_session,
    list: SelfSortingArray<Never>,
    source: git_attr_file_source,
    allow_macros: Bool)
throws(GitError) {
    fatalError()
}


@available(*, unavailable, renamed: "push_one_attr(onto:path:)", message: "The Swift version throws an error instead of returning an error code")
public func push_one_attr<T>(_:T, _:CharStar) -> CInt { fatalError() }


@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_FILE_THEN_INDEX")
public var GIT_ATTR_CHECK_FILE_THEN_INDEX: git_attr_check { fatalError() }

@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_INDEX_THEN_FILE")
public var GIT_ATTR_CHECK_INDEX_THEN_FILE: git_attr_check { fatalError() }

@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_INDEX_ONLY")
public var GIT_ATTR_CHECK_INDEX_ONLY: git_attr_check { fatalError() }


@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_NO_SYSTEM")
public var GIT_ATTR_CHECK_NO_SYSTEM: git_attr_check { fatalError() }

@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_INCLUDE_HEAD")
public var GIT_ATTR_CHECK_INCLUDE_HEAD: git_attr_check { fatalError() }

@available(*, unavailable, renamed: "git_attr_check.GIT_ATTR_CHECK_INCLUDE_COMMIT")
public var GIT_ATTR_CHECK_INCLUDE_COMMIT: git_attr_check { fatalError() }
