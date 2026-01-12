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
    // Analogous to `git_vector_bsearch2`
    mutating func binarySearch(comparator key_lookup: git_vector_cmp<Element>, needle key: Element) -> (index: Index, error: GitError) {
        self.sort()
        
        return contents.binarySearch(for: key, comparator: key_lookup)
    }
    
    
    // Analogous to `git_vector_sort`
    mutating func sort() {
        if isSorted || (nil == comparator) {
            return
        }

        if count > 1 {
            git__tsort(contents, length, comparator);
        }
        git_vector_set_sorted(v, 1);
    }
    
    
    /** Check if vector is sorted */
    // Analogous to `git_vector_is_sorted`
    @inline(__always)
    var isSorted: Bool {
        flags.contains(.sorted)
    }
    
    
    //int git_vector_insert(git_vector *v, void *element)
    // Analogous to `git_vector_insert`
    @discardableResult
    mutating func insert(_ newElement: Element) throws(GitError) -> Index {
        TODO
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "SelfSortingArray.init")
public var GIT_VECTOR_INIT: git_vector<Any> { fatalError() }

@available(*, unavailable, renamed: "SelfSortingArray.init")
public func git_vector_init(_: git_vector<Any>, _: size_t, _: git_vector_cmp<Any>) -> CInt { fatalError() }

@available(*, unavailable, message: "Just use Swift's builtin `for` loop instead.")
public func git_vector_foreach(_: Any, _: Any, _: Any) { fatalError() }

@available(*, unavailable, renamed: "vector.binarySearch(comparator:needle:)")
public func git_vector_bsearch2(_: inout size_t, _: inout git_vector<AnyTypeProtocol>, _: git_vector_cmp<Any>, _: Any) -> CInt { fatalError() }


@available(*, unavailable, renamed: "selfSortingArray.sort()")
public func git_vector_sort(_: inout git_vector<Any>) { fatalError() }

@available(*, unavailable, renamed: "selfSortingArray.isSorted")
public func git_vector_is_sorted(_: git_vector<Any>) -> Bool { fatalError() }

@available(*, unavailable, renamed: "selfSortingArray.insert(_:)")
public func git_vector_insert(_: inout git_vector<Any>, _: Any) -> Int { fatalError() }
