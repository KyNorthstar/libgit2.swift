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



public extension Repository {
    /**
     * Configuration map cache
     *
     * Efficient access to the most used config variables of a repository.
     * The cache is cleared every time the config backend is replaced.
     */
    mutating func configmap_lookup(item: ConfigmapItem) async throws(GitError) -> ConfigmapValue? {
        var value = self.configmapCache[item]
        var out = value
        
        if value == .GIT_CONFIGMAP_NOT_CACHED {
            if let config {
                out = ConfigmapValue(rawValue: try config.git_config__configmap_lookup(item: item))
            }
            
            await Volatile.run {
                if value == self.configmapCache[item] {
                    self.configmapCache[item] = out
                }
            }
        }
        
        return out
        
        
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
}

//void git_repository__configmap_lookup_cache_clear(git_repository *repo);



/**
 * Given a relative `path`, this makes it absolute based on the
 * repository's working directory.  This will perform validation
 * to ensure that the path is not longer than MAX_PATH on Windows
 * (unless `core.longpaths` is set in the repo config).
 */
func git_repository_workdir_path(repo: Repository, path: String) throws(GitError) -> String {

    guard let workdir = repo.rawWorkdir else {
        throw GitError(message: "repository has no working directory", kind: .repository, code: .operationNotAllowed_bareRepo)
    }
    
    return try git_path_validate_str_length(repo, try String(joiningPath: workdir, withPathComponent: path))
}



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
        
        if nil == config {
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
        
        return repo.config
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


/**
 * Get a snapshot of the repository's configuration
 *
 * Convenience function to take a snapshot from the repository's
 * configuration.  The contents of this snapshot will not change,
 * even if the underlying config files are modified.
 *
 * The configuration file must be freed once it's no longer
 * being used by the user.
 *
 * @param out Pointer to store the loaded configuration
 * @param repo the repository
 * @return 0, or an error code
 */
public func git_repository_config_snapshot(startingValue out: git_config? = nil, repo: git_repository) -> git_config {
    git_config_snapshot(out, repo.config)
}


/**
 * Get the path of the working directory for this repository
 *
 * If the repository is bare, this function will always return
 * NULL.
 *
 * - Parameter repo: A repository object
 * - Return: the path to the working dir, if it exists
 */
@available(*, deprecated, renamed: "repo.nonBareWorkdir", message: "TODO: rename the new version.")
public func git_repository_workdir(repo: Repository) -> String? {
    repo.nonBareWorkdir
}



public extension Repository {
    /// The path of the working directory for this repo, or `nil` if the repo is bare
    var nonBareWorkdir: String? {
        isBare ? nil : rawWorkdir
    }
}



public extension Repository {
    func git_repository__item_path(item: Item) throws(GitError) -> String {
        @available(*, unavailable, renamed: "self")
        var repo: Self { self }
        
        guard
            let mapped = items[item],
            let parent = try resolved_parent_path(item: mapped.parent, fallback: mapped.fallback)
        else {
            throw GitError(message: "path cannot exist in repository", kind: .invalid, code: .objectNotFound)
        }
        
        var out = parent
        
        if let name = mapped.name {
            out = String(joiningPath: parent, withPathComponent: name)
        }
        
        if mapped.isDirectory {
            out.ensureTrailingSlash()
        }
        
        return out
    }
    
    
    
    @inline(__always)
    func push_attr_file(
        attr_session: git_attr_session,
        list: SelfSortingArray<TODO>,
        base: String,
        filename: String)
    throws(GitError)
    {
        var source = git_attr_file_source(type: .file, base: base, filename: filename)
        return self.push_attr_source(attr_session, list, &source, true);
    }

    
    
    /// A fancy indirect way of accessing three of the repo's fields. Use `??` instead if you can.
    ///
    /// Here's the mapping of items to fields that you should use directly instead of this function:
    /// - `Item.gitDir` — `self.gitdir`
    /// - `Item.workDir` — `self.workingDirectory`
    /// - `Item.commonDir` — `self.commondir`
    ///
    /// ### Example
    /// If you call `resolved_parent_path(item: .workDir, fallback: .commonDir)` on a bare repo (where there is no working directory), this recursively acts like you called `resolved_parent_path(item: .commonDir, fallback: nil)` and returns the common directory.
    ///
    /// That behavior is identical to `workingDirectory ?? commondir`, so you're encouraged to do that instead because it's much simpler and faster.
    ///
    ///
    /// - Attention:The libgit2 C version of this didn't return any error codes if a problem occurred, instead silently setting a side-channel error and returning `NULL`. If you want to replicate that behavior, use a mechanism which discontinues error propagation, like `try?`
    ///
    /// - Parameters:
    ///   - item:     Represents a field to retrieve. Must be either `.gitDir`, `.workDir`, or `.commonDir`.
    ///   - fallback: The field to retrieve if `item` couldn't be found. Must be either `.gitDir`, `.workDir`, or `.commonDir`.
    ///
    /// - Returns: The path to the parent directory specified by `item`, or if that couldn't be found, the one specified by `fallback`.
    ///
    /// - Throws: An error if `item` (or, if that couldn't be found, `fallback`) are anything other than `.gitDir`, `.workDir`, or `.commonDir`.
    func resolved_parent_path(item: Repository.Item, fallback: Repository.Item?) throws(GitError) -> String? {
        guard let parent = switch item {
            case .gitDir:    gitdir
            case .workDir:   workingDirectory
            case .commonDir: commondir
            default: throw GitError(message: "invalid item directory", kind: .invalid)
        }
        else {
            if let fallback {
                return try resolved_parent_path(item: fallback, fallback: nil)
            }
            else {
                return nil
            }
        }
        
        return parent
    }
    
    
    /// The path of the working directory for this repository, if it exists.
    /// If the repository is bare, this will always be `null`.
    var workingDirectory: String? {
        isBare
            ? nil
            : rawWorkdir
    }
}



// MARK: - private

private let items: [Repository.Item : __UnnamedItemCollectionBody] = [
    .gitDir:         (parent: .gitDir,    fallback: nil,      name: nil,               isDirectory: true),
    .workDir:        (parent: .workDir,   fallback: nil,      name: nil,               isDirectory: true),
    .commonDir:      (parent: .commonDir, fallback: nil,      name: nil,               isDirectory: true),
    .index:          (parent: .gitDir,    fallback: nil,      name: "index",           isDirectory: false),
    .objects:        (parent: .commonDir, fallback: .gitDir,  name: "objects",         isDirectory: true),
    .refs:           (parent: .commonDir, fallback: .gitDir,  name: "refs",            isDirectory: true),
    .packedRefs:     (parent: .commonDir, fallback: .gitDir,  name: "packed-refs",     isDirectory: false),
    .remotes:        (parent: .commonDir, fallback: .gitDir,  name: "remotes",         isDirectory: true),
    .config:         (parent: .commonDir, fallback: .gitDir,  name: "config",          isDirectory: false),
    .info:           (parent: .commonDir, fallback: .gitDir,  name: "info",            isDirectory: true),
    .hooks:          (parent: .commonDir, fallback: .gitDir,  name: "hooks",           isDirectory: true),
    .logs:           (parent: .commonDir, fallback: .gitDir,  name: "logs",            isDirectory: true),
    .modules:        (parent: .gitDir,    fallback: nil,      name: "modules",         isDirectory: true),
    .worktrees:      (parent: .commonDir, fallback: .gitDir,  name: "worktrees",       isDirectory: true),
    .worktreeConfig: (parent: .gitDir,    fallback: .gitDir,  name: "config.worktree", isDirectory: false),
]



private typealias __UnnamedItemCollectionBody = (
    parent: Repository.Item,
    fallback: Repository.Item?,
    name: String?,
    isDirectory: Bool,
)



// MARK: - Migration

@available(*, unavailable, renamed: "repo.configmap_lookup(item:)", message: "The Swift version is an extension member of Repository, returns a `ConfigmapValue` instead of taking an inout pointer, and throws an error instead of returning an error code.")
public func git_repository__configmap_lookup(_: inout CInt, _: inout git_repository, _: git_configmap_item) -> CInt { fatalError() }


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


@available(*, unavailable, renamed: "repo.attrcache", message: "Just access `repo.attrcache` directly.")
public func git_repository_attr_cache(_: git_repository) -> git_attr_cache? { fatalError() }


@available(*, unavailable, renamed: "repo.config", message: "Swift doesn't require such manual pointer juggling. Use `yourVar = repo.config` instead")
public func git_repository_config__weakptr(_: inout git_config?, _: git_repository) throws(GitError) { fatalError() }

@available(*, unavailable, renamed: "repo.odb", message: "Swift doesn't require such manual pointer juggling.")
public func git_repository_odb__weakptr(_: inout git_config?, _: git_repository) throws(GitError) { fatalError() }

@available(*, unavailable, renamed: "repo.odb", message: "Swift doesn't require such manual pointer juggling")
public func git_repository_odb__weakptr(_: inout git_odb?, _: git_repository) {  fatalError() }

@available(*, unavailable, renamed: "repo.refdb", message: "Swift doesn't require such manual pointer juggling")
public func git_repository_refdb__weakptr(_: inout git_refdb?, _: git_repository) {  fatalError() }

@available(*, unavailable, renamed: "repo.index", message: "Swift doesn't require such manual pointer juggling")
public func git_repository_index__weakptr(_: inout git_index?, _: git_repository) {  fatalError() }

@available(*, unavailable, renamed: "repo.grafts", message: "Swift doesn't require such manual pointer juggling")
public func git_repository_grafts__weakptr(_: inout git_grafts?, _: git_repository) {  fatalError() }

@available(*, unavailable, renamed: "repo.shallowGrafts", message: "Swift doesn't require such manual pointer juggling")
public func git_repository_shallow_grafts__weakptr(_: inout git_grafts?, _: git_repository) {  fatalError() }

@available(*, unavailable, message: "This now returns a String and throws an error, rather than returning an error code and taking an inout string")
public func git_repository_workdir_path(_: inout git_str, _: git_repository, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, renamed: "repo.git_repository__item_path(item:)", message: "The Swift version is an extension member of Repository, returns a String instead of taking an inout string, and throws an error instead of returning an error code.")
public func git_repository__item_path(_: inout git_str, repo: git_repository, item: git_repository_item_t) -> CInt { fatalError() }

@available(*, unavailable, renamed: "repo.resolved_parent_path(item:fallback:)", message: "The Swift version is an extension member of Repository.")
public func resolved_parent_path(_: git_repository, _: git_repository_item_t, _: git_repository_item_t) -> CharStar { fatalError() }

@available(*, unavailable, renamed: "repo.gitdir", message: """
    Just access the `gitdir` field directly.
    
    This was necessary in libgit2 because checks had to be made and directly accessing fields in C isn't always safe. Swift guarantees safety and doesn't require the checks that indirection provides.
    """)
public func git_repository_path(_: git_repository) -> CharStar { fatalError() }

@available(*, unavailable, renamed: "repo.workingDirectory")
public func git_repository_workdir(_: git_repository) -> CharStar? { fatalError() }

@available(*, unavailable, renamed: "repo.commondir", message: """
    Just access the `commondir` field directly.
    
    This was necessary in libgit2 because checks had to be made and directly accessing fields in C isn't always safe. Swift guarantees safety and doesn't require the checks that indirection provides.
    """)
public func git_repository_commondir(_: git_repository) -> CharStar { fatalError() }
