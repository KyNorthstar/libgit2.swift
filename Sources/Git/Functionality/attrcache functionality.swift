//
// attrcache functionality.swift
//
// Written by Ky on 2025-08-09.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public func git_attr_cache__init(repo: inout Repository)
throws(GitError)
{
    var ret: GitError? = nil
    var cfg: Config? = nil
    
    guard nil == repo.attrcache?.pointee else {
        return
    }
    
    let cache = AttributeCache()
    try GIT_ERROR_CHECK_ALLOC(cache);
    
    try handleErrorsWithCodesButNotKinds {
        try git_repository_config_snapshot(&cfg, repo)
    }
    catch: { _ in
        try cancel()
    }
    if ((ret = git_repository_config_snapshot(&cfg, repo)) < 0)
        goto cancel;

    /* cache config settings for attributes and ignores */
    ret = attr_cache__lookup_path(
        &cache->cfg_attr_file, cfg, GIT_ATTR_CONFIG, GIT_ATTR_FILE_XDG);
    if (ret < 0)
        goto cancel;

    ret = attr_cache__lookup_path(
        &cache->cfg_excl_file, cfg, GIT_IGNORE_CONFIG, GIT_IGNORE_FILE_XDG);
    if (ret < 0)
        goto cancel;

    /* allocate hashtable for attribute and ignore file contents,
     * hashtable for attribute macros, and string pool
     */
    if ((ret = git_strmap_new(&cache->files)) < 0 ||
        (ret = git_strmap_new(&cache->macros)) < 0 ||
        (ret = git_pool_init(&cache->pool, 1)) < 0)
        goto cancel;

    if (git_atomic_compare_and_swap(&repo->attrcache, NULL, cache) != NULL)
        goto cancel; /* raced with another thread, free this but no error */

    git_config_free(cfg);

    /* insert default macros */
    return git_attr_add_macro(repo, "binary", "-diff -merge -text -crlf");

    func cancel() throws(GitError) {
        attr_cache__free(cache);
        git_config_free(cfg);
        throw ret
    }
}
