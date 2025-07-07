//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2024-12-18.
//

import Foundation



public enum SysDir: CInt, AnyEnumProtocol {
    case system      = 0
    case global      = 1
    case xdg         = 2
    case programdata = 3
    case template    = 4
    case home        = 5
    case _max
}



// MARK: - Migration

@available(*, unavailable, renamed: "SysDir")
public typealias git_sysdir_t = SysDir

@available(*, unavailable, renamed: "SysDir.system")
public var GIT_SYSDIR_SYSTEM: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir.global")
public var GIT_SYSDIR_GLOBAL: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir.xdg")
public var GIT_SYSDIR_XDG: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir.programdata")
public var GIT_SYSDIR_PROGRAMDATA: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir.template")
public var GIT_SYSDIR_TEMPLATE: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir.home")
public var GIT_SYSDIR_HOME: git_sysdir_t { fatalError() }

@available(*, unavailable, renamed: "SysDir._max")
public var GIT_SYSDIR__MAX: git_sysdir_t { fatalError() }
