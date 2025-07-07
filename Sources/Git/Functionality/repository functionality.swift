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



/**
 * Configuration map cache
 *
 * Efficient access to the most used config variables of a repository.
 * The cache is cleared every time the config backend is replaced.
 */
public func git_repository__configmap_lookup(repo: Repository, item: ConfigmapItem) async throws(GitError) -> CInt
{
    var value = intptr_t(await Volatile.run { repo.configmapCache[item.rawValue].rawValue })
    
    var out = value
    
    if value == ConfigmapValue.GIT_CONFIGMAP_NOT_CACHED.rawValue {
        let config: Config
        let oldval = value
        
        try git_repository_config__weakptr(&config, repo)
        try git_config__configmap_lookup(&out, config, item)
        
        value = out
        git_atomic_compare_and_swap(&repo.configmap_cache[.init(item)], oldval, value)
    }
    else {
        return value
    }
    
    
    // The above code translates this original C code:
    //
    // int git_repository__configmap_lookup(int *out, git_repository *repo, git_configmap_item item)
    // {
    //     intptr_t value = (intptr_t)git_atomic_load(repo->configmap_cache[(int)item]);
    //
    //     *out = (int)value;
    //
    //     if (value == GIT_CONFIGMAP_NOT_CACHED) {
    //         git_config *config;
    //         intptr_t oldval = value;
    //         int error;
    //
    //         if ((error = git_repository_config__weakptr(&config, repo)) < 0 ||
    //             (error = git_config__configmap_lookup(out, config, item)) < 0)
    //             return error;
    //
    //         value = *out;
    //         git_atomic_compare_and_swap(&repo->configmap_cache[(int)item], (void *)oldval, (void *)value);
    //     }
    //
    //     return 0;
    // }
}

void git_repository__configmap_lookup_cache_clear(git_repository *repo);



// MARK: - Weak pointers to repository internals

/*
 * The returned pointers do not need to be freed. Do not keep
 * permanent references to these (i.e. between API calls), since they may
 * become invalidated if the user replaces a repository internal.
 */

public extension Repository {
    func git_repository_config__weakptr() throws(GitError) -> Config?
    {
        @available(*, unavailable, renamed: "self")
        var repo: Self {
            get {
                self
            }
        }
        
        if nil == _config {
            let system_buf = String()
            var global_buf = String()
            let xdg_buf = String()
            let programdata_buf = String()
            let use_env = self.useEnv
            let config: Config
            
            system_buf = try config_path_system(use_env: use_env)
            try config_path_global(&global_buf, use_env)
            
            git_config__find_xdg(&xdg_buf);
            git_config__find_programdata(&programdata_buf);
            
            /*
             * If there is no global file, open a backend
             * for it anyway.
             */
            if global_buf.isEmpty {
                git_config__global_location(&global_buf);
            }
            
            try load_config(
                &config, repo,
                path_unless_empty(&global_buf),
                path_unless_empty(&xdg_buf),
                path_unless_empty(&system_buf),
                path_unless_empty(&programdata_buf));
            
            GIT_REFCOUNT_OWN(config, repo);
            
            if (git_atomic_compare_and_swap(&repo->_config, NULL, config) != NULL) {
                GIT_REFCOUNT_OWN(config, NULL);
                git_config_free(config);
            }
            
            
            git_str_dispose(&global_buf);
            git_str_dispose(&xdg_buf);
            git_str_dispose(&system_buf);
            git_str_dispose(&programdata_buf);
        }
        
        return repo._config
    }
    //int git_repository_odb__weakptr(git_odb **out, git_repository *repo);
    //int git_repository_refdb__weakptr(git_refdb **out, git_repository *repo);
    //int git_repository_index__weakptr(git_index **out, git_repository *repo);
    //int git_repository_grafts__weakptr(git_grafts **out, git_repository *repo);
    //int git_repository_shallow_grafts__weakptr(git_grafts **out, git_repository *repo);
}



@inline(__always)
private func config_path_system(backup: String? = nil, use_env: Bool) throws(GitError) -> String? {
    
    
    if (use_env) {
        var no_system: Bool
        
        do {
            let no_system_buf = try _getEnv(name: "GIT_CONFIG_NOSYSTEM")
            no_system = try Config.parseBool(no_system_buf)
        }
        catch {
            guard error.code == .objectNotFound else {
                throw error
            }
        }
        
        if no_system {
            return backup
        }
        
        do {
            return try _getEnv(name: "GIT_CONFIG_SYSTEM")
        }
        catch {
            guard error.code == .objectNotFound else {
                // error != GIT_ENOTFOUND
                return backup
            }
        }
        catch {
            // Ignore other errors
        }
    }
    var out: String
    try git_config__find_system(path: out)
    
    // The above code translates this original C code:
    //
    // GIT_INLINE(int) config_path_system(git_str *out, bool use_env)
    // {
    //     if (use_env) {
    //         git_str no_system_buf = GIT_STR_INIT;
    //         int no_system = 0;
    //         int error;
    //
    //         error = git__getenv(&no_system_buf, "GIT_CONFIG_NOSYSTEM");
    //
    //         if (error && error != GIT_ENOTFOUND)
    //             return error;
    //
    //         error = git_config_parse_bool(&no_system, no_system_buf.ptr);
    //         git_str_dispose(&no_system_buf);
    //
    //         if (no_system)
    //             return 0;
    //
    //         error = git__getenv(out, "GIT_CONFIG_SYSTEM");
    //
    //         if (error == 0 || error != GIT_ENOTFOUND)
    //             return 0;
    //     }
    //
    //     git_config__find_system(out);
    //     return 0;
    // }
}


/// Check if the given repository is a linked work tree
///
/// - Parameter repo: Repo to test
/// - Returns: `true` if the repository is a linked work tree, `false` otherwise
@available(*, deprecated, renamed: "repo.isWorktree", message: "The original version of this just accessed `repo.isWorktree` after checking whether `repo` was null. Swift has robust nilness checking, so that is unnecessary.")
@inline(__always)
public func git_repository_is_worktree(repo: Repository) -> Bool {
    repo.isWorktree
}


public func git_config__find_system(path: String) throws(GitError) {
    try git_sysdir_find_system_file(path: path, filename: GIT_CONFIG_FILENAME_SYSTEM)
}


/// Check if the given repository is bare
///
/// - Parameter repo: Repo to test
/// - Returns: `true` if the repository is bare, `false` otherwise
@available(*, deprecated, renamed: "repo.isBare", message: "The original version of this just accessed `repo.isBare` after checking whether `repo` was null. Swift has robust nilness checking, so that is unnecessary.")
@inline(__always)
public func git_repository_is_bare(repo: Repository) -> Bool {
    repo.isBare
}
