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



@inline(__always)
public func attr_cache_lookup_entry(cache: AttributeCache, path: String) async -> git_attr_file_entry? {
    await cache.files[path] as? git_attr_file_entry
}



public func git_attr_cache__init(repo: Repository)
throws(GitError)
{
    var ret: GitError? = nil
    var cfg: Config? = nil
    
    guard nil == repo.attrcache else {
        return
    }
    
    let cache = AttributeCache()
    
    try handleErrorsWithCodesButNotKinds { () throws(GitError) -> Void in
        cfg = try git_repository_config_snapshot(repo: repo)
    }
    catch: { (_) throws(GitError) -> Void in
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



public func git_attr_cache__get(
    repo: Repository,
    attr_session: git_attr_session,
    source: git_attr_file_source,
    parser: git_attr_file_parser,
    allow_macros: Bool)
throws(GitError) -> git_attr_file {
    var cache = repo.attrcache
    var entry: git_attr_file_entry? = nil
    var file: git_attr_file? = nil
    var updated: git_attr_file? = nil
    
    try throwOnlyForErrorsWithCodesButNotKinds {
        file = try attr_cache_lookup(entry, repo, attr_session, source)
    }
    
    /* load file if we don't have one or if existing one is out of date */
    if (!file ||
        (error = git_attr_file__out_of_date(repo, attr_session, file, source)) > 0)
        error = git_attr_file__load(&updated, repo, attr_session,
                                    entry, source, parser,
                                    allow_macros);

    /* if we loaded the file, insert into and/or update cache */
    if (updated) {
        if ((error = attr_cache_upsert(cache, updated)) < 0) {
            git_attr_file__free(updated);
        } else {
            git_attr_file__free(file); /* offset incref from lookup */
            file = updated;
        }
    }

    /* if file could not be loaded */
    if (error < 0) {
        /* remove existing entry */
        if (file) {
            attr_cache_remove(cache, file);
            git_attr_file__free(file); /* offset incref from lookup */
            file = NULL;
        }
        /* no error if file simply doesn't exist */
        if (error == GIT_ENOTFOUND) {
            git_error_clear();
            error = 0;
        }
    }

    return file
}
