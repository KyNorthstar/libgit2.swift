//
// path functionality.swift
//
// Written by Ky on 2025-09-29.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



#if !os(Windows)

/// Takes in any path and returns the real actual canonical path to that file. If that file, or any of the directories along the way, don't exist, then this returns `nil`.
///
/// Like `realpath`, but assuming you want it to work as intended, not replicating `realpath`'s... nuanced differences between paltforms.
///
/// - Parameter pathname: A path to a file
/// - Returns: The real path to that file, resolving all symlinks, dots, etc., or `nil` if it doesn't exist at the given path.
public func p_realpath(pathname: String) -> String? { // TODO: This and `p_realpath` are Our first attempt to completely rewrite one of these low-level C functions with high-level Swift implementations. This should be tested thoroughly to guarantee parity!
    let proposedPath = URL(filePath: pathname).resolvingSymlinksInPath().standardizedFileURL.path
    return if FileManager.default.fileExists(atPath: proposedPath) { proposedPath } else { nil }
}

#endif



// MARK: - Migration

@available(*, unavailable, renamed: "p_realpath(pathname:)", message: "The libgit2.swift version omits the second argument in favor of always returning the result")
public func p_realpath(_: String, _: inout String?) -> String? { fatalError() }
