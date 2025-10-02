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



internal func collect_attr_files(
    repo: Repository,
    session attr_session: git_attr_session,
    options opts: git_attr_options,
    path: String,
    files: SelfSortingArray<any AnyTypeProtocol>) // TODO: Use actual type
throws(GitError)
{
    var error: GitError? = nil
    var dir = String()
    var attrfile = String()
    let workdir = repo.nonBareWorkdir
    let info = attr_walk_up_info()

    try assert(expr: !git_fs_path_is_absolute(path: path))
    
    do {
        try attr_setup(repo: repo, attr_session: attr_session, opts: opts)
    }
    catch where error.code != nil
             && error.kind == nil {
        throw error
    }
    catch {}

    /* Resolve path in a non-bare repo */
    if let workdir {
        dir = try git_repository_workdir_path(repo: repo, path: path)
        dir = try git_fs_path_find_dir(dir: dir)
    }
    else {
        error = git_fs_path_dirname_r(&dir, path);
    }

    if (error < 0)
        goto cleanup;

    /* in precedence order highest to lowest:
     * - $GIT_DIR/info/attributes
     * - path components with .gitattributes
     * - config core.attributesfile
     * - $GIT_PREFIX/etc/gitattributes
     */

    if ((error = git_repository__item_path(&attrfile, repo, GIT_REPOSITORY_ITEM_INFO)) < 0 ||
        (error = push_attr_file(repo, attr_session, files, attrfile.ptr, GIT_ATTR_FILE_INREPO)) < 0) {
        if (error != GIT_ENOTFOUND)
            goto cleanup;
    }

    info.repo = repo;
    info.attr_session = attr_session;
    info.opts = opts;
    info.workdir = workdir;
    if (git_repository_index__weakptr(&info.index, repo) < 0)
        git_error_clear(); /* no error even if there is no index */
    info.files = files;

    if (!strcmp(dir.ptr, "."))
        error = push_one_attr(&info, "");
    else
        error = git_fs_path_walk_up(&dir, workdir, push_one_attr, &info);

    if (error < 0)
        goto cleanup;

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

 cleanup:
    if (error < 0)
        release_attr_files(files);
    git_str_dispose(&attrfile);
    git_str_dispose(&dir);

    return error;
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
        try git_attr_cache__init(repo)
    }
    catch where error.code != nil
             && error.kind == nil {
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

out:
    git_str_dispose(&system);
    git_str_dispose(&info);

    return error;
}
