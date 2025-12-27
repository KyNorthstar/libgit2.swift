//
// config.swift
//
// Written by Ky on 2024-11-11.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public struct Config: AnyStructProtocol {
    public var refCount: RefCount
    public var readers: SelfSortingArray<AnyTypeProtocol>
    public var writers: SelfSortingArray<AnyTypeProtocol>
}



/**
 * Config var type
 */
public enum git_configmap_t: Int, AnyEnumProtocol {
    case `false` = 0
    case `true` = 1
    case int32
    case string
}



public extension git_configmap_t {
    static func == (lhs: Bool, rhs: Self) -> Bool {
        switch rhs {
        case .`false`: false == lhs
        case .`true`:  true  == lhs
        default: false
        }
    }
    
    
    @inline(__always)
    static func == (lhs: Self, rhs: Bool) -> Bool {
        !(rhs == lhs)
    }
}



/**
 * Mapping from config variables to values.
 */
public struct git_configmap: AnyStructProtocol {
    public var type: git_configmap_t
    public let str_match: String?
    public let map_value: ConfigmapValue
}



/**
 * Priority level of a config file.
 *
 * These priority levels correspond to the natural escalation logic
 * (from higher to lower) when reading or searching for config entries
 * in git.git. Meaning that for the same key, the configuration in
 * the local configuration is preferred over the configuration in
 * the system configuration file.
 *
 * Callers can add their own custom configuration, beginning at the
 * `.app` level.
 *
 * Writes, by default, occur in the highest priority level backend
 * that is writable. This ordering can be overridden with
 * `git_config_set_writeorder`.
 *
 * git_config_open_default() and git_repository_config() honor those
 * priority levels as well.
 */
public enum git_config_level_t: Int, AnyEnumProtocol {
    /** System-wide on Windows, for compatibility with portable git */
    case programData = 1

    /** System-wide configuration file; /etc/gitconfig on Linux systems */
    case system = 2

    /** XDG compatible configuration file; typically ~/.config/git/config */
    case xdg = 3

    /** User-specific configuration file (also called Global configuration
     * file); typically ~/.gitconfig
     */
    case global = 4

    /** Repository specific configuration file; $WORK_DIR/.git/config on
     * non-bare repos
     */
    case local = 5

    /** Worktree specific configuration file; $GIT_DIR/config.worktree
     */
    case worktree = 6

    /** Application specific configuration file; freely defined by applications
     */
    case app = 7

    /** Represents the highest level available config file (i.e. the most
     * specific config file available that actually is loaded)
     */
    case _highest = -1
}




/**
 * An entry in a configuration file
 */
public struct git_config_entry: AnyStructProtocol {
    /** Name of the configuration entry (normalized) */
    public let name: String
    
    /** Literal (string) value of the entry */
    public let value: String
    
    /** The type of backend that this entry exists in (eg, "file") */
    public let backend_type: String
    
    /**
     * The path to the origin of this entry. For config files, this is
     * the path to the file.
     */
    public let origin_path: String
    
    /** Depth of includes where this variable was found */
    public var include_depth: CUnsignedInt
    
    /** Configuration level for the file this was found in */
    public var level: git_config_level_t
}



/**
 * Generic backend that implements the interface to
 * access a configuration file
 */
public protocol git_config_backend: AnyProtocolProtocol {
    var version: UInt { get }
    
    /** True if this backend is for a snapshot */
    var readonly: Bool { get }
    
    var cfg: Config { get set }

    /** Open means open the file/database and parse if necessary */
    func open(level: git_config_level_t, repo: Repository?) throws(GitError) -> Void
    func get(key: String?) throws(GitError) -> git_config_entry
    func set(key: String?, value: String) throws(GitError) -> Void
    func set_multivar(name: String?, regexp: String, value: String) throws(GitError) -> Void
    func del(key: String?) throws(GitError) -> Void
    func del_multivar(key: String?, regexp: String) throws(GitError) -> Void
    func iterator() throws(GitError) -> git_config_iterator
    
    /** Produce a read-only version of this backend */
    func snapshot() throws(GitError) -> git_config_backend
    
    /**
     * Lock this backend.
     *
     * Prevent any writes to the data store backing this
     * backend. Any updates must not be visible to any other
     * readers.
     */
    func lock() throws(GitError) -> Void
    
    /**
     * Unlock the data store backing this backend. If success is
     * true, the changes should be committed, otherwise rolled
     * back.
     */
    func unlock(success: Bool) throws(GitError) -> Void
}



/**
 * Every iterator must have this struct as its first element, so the
 * API can talk to it. You'd define your iterator as
 *
 *     struct my_iterator {
 *             git_config_iterator parent;
 *             ...
 *     }
 *
 * and assign `iter->parent.backend` to your `git_config_backend`.
 */
public protocol git_config_iterator: AnyProtocolProtocol {
    var backend: git_config_backend { get }
    var flags: CUnsignedInt { get }

    /**
     * Return the current entry and advance the iterator. The
     * memory belongs to the library.
     */
    func next() throws(GitError) -> git_config_entry
}




// MARK: - Migration

@available(*, unavailable, renamed: "Config")
public typealias git_config = Config



public extension Config {
    @available(*, unavailable, renamed: "refCount")
    var rc: git_refcount { refCount }
}


@available(*, unavailable, renamed: "git_configmap_t.false")
public var GIT_CONFIGMAP_FALSE: git_configmap_t { fatalError() }

@available(*, unavailable, renamed: "git_configmap_t.true")
public var GIT_CONFIGMAP_TRUE: git_configmap_t { fatalError() }

@available(*, unavailable, renamed: "git_configmap_t.int32")
public var GIT_CONFIGMAP_INT32: git_configmap_t { fatalError() }

@available(*, unavailable, renamed: "git_configmap_t.string")
public var GIT_CONFIGMAP_STRING: git_configmap_t { fatalError() }



@available(*, unavailable)
public extension git_config_entry {
    @available(*, unavailable, message: "This is unnecesary in Swift")
    var free: (inout git_config_entry?) -> Void { fatalError() }
}


@available(*, unavailable, renamed: "git_config_level_t.programData")
public var GIT_CONFIG_LEVEL_PROGRAMDATA: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.system")
public var GIT_CONFIG_LEVEL_SYSTEM: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.xdg")
public var GIT_CONFIG_LEVEL_XDG: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.global")
public var GIT_CONFIG_LEVEL_GLOBAL: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.local")
public var GIT_CONFIG_LEVEL_LOCAL: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.worktree")
public var GIT_CONFIG_LEVEL_WORKTREE: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t.app")
public var GIT_CONFIG_LEVEL_APP: git_config_level_t { fatalError() }
@available(*, unavailable, renamed: "git_config_level_t._highest")
public var GIT_CONFIG_HIGHEST_LEVEL: git_config_level_t { fatalError() }



@available(*, unavailable)
public extension git_config_backend {
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func open(_: git_config_backend, _ level: git_config_level_t, _ repo: Repository?) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func get(_: git_config_backend, _ key: String) throws(GitError) -> git_config_entry { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func set(_: git_config_backend, _ key: String, _ value: String) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func set_multivar(_: git_config_backend, _ name: String, _ regexp: String, _ value: String) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func del(_: git_config_backend, _ key: String) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func del_multivar(_: git_config_backend, _ key: String, _ regexp: String) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function returns `git_config_iterator` instead of taking an inout, assumes the backend is `self`")
    func iterator(_: inout git_config_iterator, _: git_config_backend) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function returns `git_config_backend` instead of taking an inout, assumes the other backend is `self`")
    func snapshot(_: inout git_config_backend?, _: git_config_backend) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func lock(_: git_config_backend) throws(GitError) -> Void { fatalError() }
    
    @available(*, unavailable, message: "The Swift version of this function assumes the `git_config_backend` parameter is `self`")
    func unlock(_: git_config_backend, _ success: Bool) throws(GitError) -> Void { fatalError() }
    
    
    @available(*, unavailable, message: "Swift takes care of memory management automatically")
    var free: (inout git_config_backend?) -> Void { fatalError() }
}



@available(*, unavailable)
public extension git_config_iterator {
    
    @available(*, unavailable, message: "The Swift version of this function returns `git_config_entry` instead of taking an inout, assumes the iterator is `self`")
    func next(_: inout git_config_entry, _: inout git_config_iterator) -> Void { fatalError() }
    
    @available(*, unavailable, message: "Swift takes care of memory management automatically")
    var free: (inout git_config_iterator) -> Void { fatalError() }
}
