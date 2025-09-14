//
// util functionality.swift
//
// Written by Ky on 2024-12-18.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public extension SelfSortingArray {
    /**
     * Binary search for matching entry using explicit comparison function that
     * returns position where item would go if not found.
     */
    mutating func binarySearch(cmp key_lookup: git_vector_cmp<Element>, key: Element) -> (index: Index, error: GitError) {
        git_vector_sort(&self)
        
        return contents.binarySearch(for: key, comparator: key_lookup)
    }

}



// MARK: - Migration

@available(*, unavailable, renamed: "SelfSortingArray.init")
public var GIT_VECTOR_INIT: git_vector<Any> { fatalError() }

@available(*, unavailable, renamed: "SelfSortingArray.init")
public func git_vector_init(_: git_vector<Any>, _: size_t, _: git_vector_cmp<Any>) -> CInt { fatalError() }

@available(*, unavailable, message: "Just use Swift's builtin `for` loop instead.")
public func git_vector_foreach(_: Any, _: Any, _: Any) { fatalError() }

@available(*, unavailable, renamed: "<#newName#>")
public func git_vector_bsearch2(_: inout size_t, _: inout git_vector, _: git_vector_cmp, _: Any) -> CInt { fatalError() }
