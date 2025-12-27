//
// path.swift
//
// Written by Ky on 2025-09-11.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public extension FilesystemPathRejectionFlags {
    
    static let dotGit        = FilesystemPathRejectionFlags(rawValue: FilesystemPathRejectionFlags.max.rawValue << 1)
    static let dotGitLiteral = FilesystemPathRejectionFlags(rawValue: FilesystemPathRejectionFlags.max.rawValue << 2)
    static let dotGitHFS     = FilesystemPathRejectionFlags(rawValue: FilesystemPathRejectionFlags.max.rawValue << 3)
    static let dotGitNTFS    = FilesystemPathRejectionFlags(rawValue: FilesystemPathRejectionFlags.max.rawValue << 4)
}



// MARK: - Migration

@available(*, unavailable, renamed: "FilesystemPathRejectionFlag.dotGit")
public var GIT_PATH_REJECT_DOT_GIT: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlag.dotGitLiteral")
public var GIT_PATH_REJECT_DOT_GIT_LITERAL: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlag.dotGitHFS")
public var GIT_PATH_REJECT_DOT_GIT_HFS: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlag.dotGitNTFS")
public var GIT_PATH_REJECT_DOT_GIT_NTFS: Int { fatalError() }
