//
// alloc functionality.swift
//
// Written by Ky on 2024-12-08.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



private extension UnsafeMutableRawPointer {
    @available(*, unavailable, renamed: "assumingMemoryBound(to:)", message: "This already exists, ya stoner!")
    func typed<Value>() -> UnsafeMutablePointer<Value> {
        .init(OpaquePointer(self))
    }
}



// MARK: - Migration

@available(*, unavailable, message: "No need for allocators in Swift")
func git_allocator_global_init() -> CInt { fatalError() }


@available(*, unavailable, renamed: "Array", message: "Swift's array allocation is smart enough that this is not needed. Use `array.reserveCapacity` if you need to reserve capacity.")
public func git__calloc<T>(_: size_t, _: size_t) -> T { fatalError() }

@available(*, unavailable, message: "Swift Strings are copy-on-write, so there is no need for explicit duplication.")
func git__strdup(_: String) -> String { fatalError() }
