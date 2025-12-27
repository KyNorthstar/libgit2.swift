//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-12-26.
//

import Foundation



// MARK: - Migration

/**
 * Return value associated with the given key.
 *
 * - Parameter map: map to search key in
 * - Parameter key: key to search for
 * - Returns: value associated with the given key or `nil` if the key was not found
 */
@available(*, unavailable, message: "Use the subscript map[key] instead.")
public func git_strmap_get(_ map: StringMap, _ key: String) -> Any? { fatalError() }
