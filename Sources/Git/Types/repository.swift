//
// oid.swift
//
// Written by Ky on 2024-11-10.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

@preconcurrency import SafePointer



public struct Repository: AnyStructProtocol {
    public var _odb: ObjectDatabase
    public var _refdb: ReferenceDatabase
    public var _config: Config?
    public var _index: Index
    
    public var objects: Cache
    public weak var attrcache: SafePointer<AttributeCache>?
    public weak var diffDrivers: SafePointer<DiffDriverRegistry>?
    
    public var gitlink: String
    public var gitdir: String
    public var commondir: String
    public var rawWorkdir: String
    public var namespace: String
    
    public var ident_name: String
    public var ident_email: String
    
    public var reservedNames: [String]
    
    public var useEnv = true
    public var isBare = true
    public var isWorktree = true
    
    public var oid_type: Oid.Kind
    
    public var lru_counter: UInt
    
    public weak var grafts: SafePointer<Grafts>?
    public weak var shallowGrafts: SafePointer<Grafts>?
    
    @Volatile
    public var attr_session_key: Int32
    
    @Volatile
    public var configmapCache: [ConfigmapItem]
    public var submoduleCache: StringMap
};



/** Cvar cache identifiers */
public enum ConfigmapItem: Int, AnyEnumProtocol {
    case autoCrlf = 0      /* core.autocrlf */
    case eol               /* core.eol */
    case symlinks          /* core.symlinks */
    case ignoreCase        /* core.ignorecase */
    case fileMode          /* core.filemode */
    case ignoreStat        /* core.ignorestat */
    case trustCTime        /* core.trustctime */
    case abbrev            /* core.abbrev */
    case precompose        /* core.precomposeunicode */
    case safeCrlf          /* core.safecrlf */
    case logAllRefUpdates  /* core.logallrefupdates */
    case protectHfs        /* core.protectHFS */
    case protectNtfs       /* core.protectNTFS */
    case fSyncObjectFiles  /* core.fsyncObjectFiles */
    case logPaths          /* core.longpaths */
    
    case cacheMax
}



/**
 * Configuration map value enumerations
 *
 * These are the values that are actually stored in the configmap cache,
 * instead of their string equivalents. These values are internal and
 * symbolic; make sure that none of them is set to `-1`, since that is
 * the unique identifier for "not cached"
 */
public struct ConfigmapValue: RawRepresentable, AnyStructProtocol {
    public var rawValue: CInt
    
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
}



public extension ConfigmapValue {
    
    /* The value hasn't been loaded from the cache yet */
    static let GIT_CONFIGMAP_NOT_CACHED = Self(rawValue: -1)

    /* core.safecrlf: false, 'fail', 'warn' */
    static let GIT_SAFE_CRLF_FALSE = Self(rawValue: 0)
    static let GIT_SAFE_CRLF_FAIL = Self(rawValue: 1)
    static let GIT_SAFE_CRLF_WARN = Self(rawValue: 2)

    /* core.autocrlf: false, true, 'input; */
    static let GIT_AUTO_CRLF_FALSE = Self(rawValue: 0)
    static let GIT_AUTO_CRLF_TRUE = Self(rawValue: 1)
    static let GIT_AUTO_CRLF_INPUT = Self(rawValue: 2)
    static let GIT_AUTO_CRLF_DEFAULT = GIT_AUTO_CRLF_FALSE

    /* core.eol: unset, 'crlf', 'lf', 'native' */
    static let GIT_EOL_UNSET = Self(rawValue: 0)
    static let GIT_EOL_CRLF = Self(rawValue: 1)
    static let GIT_EOL_LF = Self(rawValue: 2)
#if GIT_WIN32
    static let GIT_EOL_NATIVE = GIT_EOL_CRLF
#else
    static let GIT_EOL_NATIVE = GIT_EOL_LF
#endif
    static let GIT_EOL_DEFAULT = GIT_EOL_NATIVE

    /* core.symlinks: bool */
    static let GIT_SYMLINKS_DEFAULT = git_configmap_t.true
    /* core.ignorecase */
    static let GIT_IGNORECASE_DEFAULT = git_configmap_t.false
    /* core.filemode */
    static let GIT_FILEMODE_DEFAULT = git_configmap_t.true
    /* core.ignorestat */
    static let GIT_IGNORESTAT_DEFAULT = git_configmap_t.false
    /* core.trustctime */
    static let GIT_TRUSTCTIME_DEFAULT = git_configmap_t.true
    /* core.abbrev */
    static let GIT_ABBREV_DEFAULT = Self(rawValue: 7)
    /* core.precomposeunicode */
    static let GIT_PRECOMPOSE_DEFAULT = git_configmap_t.false
    /* core.safecrlf */
    static let GIT_SAFE_CRLF_DEFAULT = git_configmap_t.false
    /* core.logallrefupdates */
    static let GIT_LOGALLREFUPDATES_FALSE = git_configmap_t.false
    static let GIT_LOGALLREFUPDATES_TRUE = git_configmap_t.true
    static let GIT_LOGALLREFUPDATES_UNSET = Self(rawValue: 2)
    static let GIT_LOGALLREFUPDATES_ALWAYS = Self(rawValue: 3)
    static let GIT_LOGALLREFUPDATES_DEFAULT = GIT_LOGALLREFUPDATES_UNSET
    /* core.protectHFS */
    static let GIT_PROTECTHFS_DEFAULT = git_configmap_t.false
    /* core.protectNTFS */
    static let GIT_PROTECTNTFS_DEFAULT = git_configmap_t.true
    /* core.fsyncObjectFiles */
    static let GIT_FSYNCOBJECTFILES_DEFAULT = git_configmap_t.false
    /* core.longpaths */
    static let GIT_LONGPATHS_DEFAULT = git_configmap_t.false
}



// MARK: - Migration

@available(*, unavailable, renamed: "Repository")
public typealias git_repository = Repository

@available(*, unavailable, renamed: "ConfigmapItem")
public typealias git_configmap_item = ConfigmapItem



@available(*, unavailable, renamed: "ConfigmapItem.autoCrlf")
public let GIT_CONFIGMAP_AUTO_CRLF = ConfigmapItem.autoCrlf

@available(*, unavailable, renamed: "ConfigmapItem.eol")
public let GIT_CONFIGMAP_EOL = ConfigmapItem.eol

@available(*, unavailable, renamed: "ConfigmapItem.symlinks")
public let GIT_CONFIGMAP_SYMLINKS = ConfigmapItem.symlinks

@available(*, unavailable, renamed: "ConfigmapItem.ignoreCase")
public let GIT_CONFIGMAP_IGNORECASE = ConfigmapItem.ignoreCase

@available(*, unavailable, renamed: "ConfigmapItem.fileMode")
public let GIT_CONFIGMAP_FILEMODE = ConfigmapItem.fileMode

@available(*, unavailable, renamed: "ConfigmapItem.ignoreStat")
public let GIT_CONFIGMAP_IGNORESTAT = ConfigmapItem.ignoreStat

@available(*, unavailable, renamed: "ConfigmapItem.trustCTime")
public let GIT_CONFIGMAP_TRUSTCTIME = ConfigmapItem.trustCTime

@available(*, unavailable, renamed: "ConfigmapItem.abbrev")
public let GIT_CONFIGMAP_ABBREV = ConfigmapItem.abbrev

@available(*, unavailable, renamed: "ConfigmapItem.precompose")
public let GIT_CONFIGMAP_PRECOMPOSE = ConfigmapItem.precompose

@available(*, unavailable, renamed: "ConfigmapItem.safeCrlf")
public let GIT_CONFIGMAP_SAFE_CRLF = ConfigmapItem.safeCrlf

@available(*, unavailable, renamed: "ConfigmapItem.logAllRefUpdates")
public let GIT_CONFIGMAP_LOGALLREFUPDATES = ConfigmapItem.logAllRefUpdates

@available(*, unavailable, renamed: "ConfigmapItem.protectHfs")
public let GIT_CONFIGMAP_PROTECTHFS = ConfigmapItem.protectHfs

@available(*, unavailable, renamed: "ConfigmapItem.protectNtfs")
public let GIT_CONFIGMAP_PROTECTNTFS = ConfigmapItem.protectNtfs

@available(*, unavailable, renamed: "ConfigmapItem.fSyncObjectFiles")
public let GIT_CONFIGMAP_FSYNCOBJECTFILES = ConfigmapItem.fSyncObjectFiles

@available(*, unavailable, renamed: "ConfigmapItem.logPaths")
public let GIT_CONFIGMAP_LONGPATHS = ConfigmapItem.logPaths

@available(*, unavailable, renamed: "ConfigmapItem.cacheMax")
public let GIT_CONFIGMAP_CACHE_MAX = ConfigmapItem.cacheMax



public extension Repository {
    @available(*, unavailable, renamed: "diffDrivers")
    var diff_drivers: git_diff_driver_registry { fatalError("use diffDrivers") }
    
    @available(*, unavailable, renamed: "reservedNames")
    var reserved_names: [String] { fatalError("use reservedNames") }
    
    
    @available(*, unavailable, renamed: "useEnv")
    var use_env: CUnsigned { fatalError("use useEnv") }
    
    @available(*, unavailable, renamed: "isBare")
    var is_bare: CUnsigned { fatalError("use isBare") }
    
    @available(*, unavailable, renamed: "isWorktree")
    var is_worktree: CUnsigned { fatalError("use isWorktree") }
    
    @available(*, unavailable, renamed: "shallowGrafts")
    var shallow_grafts: SafePointer<Grafts>? { fatalError("use shallowGrafts") }
    
    @available(*, unavailable, renamed: "configmapCache")
    var configmap_cache: [ConfigmapItem] { fatalError("use configmapCache") }
    
    @available(*, unavailable, renamed: "submoduleCache")
    var submodule_cache: StringMap { fatalError("use submoduleCache") }
}
