//
// git2_util functionality.swift
//
// Written by Ky on 2025-02-18.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// Check for an error value and throw it if non-nil.
/// - Parameter error: The error to throw, or `nil` to not throw an error
/// - Throws: `error` iff it's non-`nil`
@inline(__always)
public func GIT_ERROR_CHECK_ERROR(_ error: GitError?) throws(GitError) {
    if let error {
        throw error
    }
}


@inline(__always)
public func GIT_ERROR_CHECK_ERROR<Return>(_ checkedFunction: @autoclosure () throws(GitError) -> Return) throws(GitError) -> Return {
    try checkedFunction()
}



public extension FixedWidthInteger {
    
    /** Check for additive overflow, failing if it would occur. */
    func addingOrThrowOnOverflow(_ two: Self) throws(GitError) -> Self {
        let (out, overflow) = self.addingReportingOverflow(two)
        
        if overflow {
            throw .init(code: .__generic)
        }
        else {
            return out
        }
    }
}



@inline(__always)
public func git__add_sizet_overflow<I: FixedWidthInteger>(out: inout I, one: I, two: I) -> Bool {
    let (result, problem) = one.addingReportingOverflow(two)
    out = result
    return problem
}


/** Check for additive overflow, setting an error if would occur. */
@inline(__always)
public func GIT_ADD_SIZET_OVERFLOW<I: FixedWidthInteger>(out: inout I, one: I, two: I) throws(GitError) {
    if git__add_sizet_overflow(out: &out, one: one, two: two) {
        throw .outOfMemory
    }
    else {
        return
    }
}

/// Check whether the given value is `nil`, throwing `.generic` if is is
public func GIT_ERROR_CHECK_ALLOC<T>(_ ptr: T?) throws(GitError) {
    guard nil != ptr else { throw .generic }
}


/** Check for additive overflow, failing if it would occur. */
@inline(__always)
public func GIT_ERROR_CHECK_ALLOC_ADD<I: FixedWidthInteger>(out: inout I, one: I, two: I) throws(GitError) {
    do {
        try GIT_ADD_SIZET_OVERFLOW(out: &out, one: one, two: two)
    }
    catch {
        throw .init(code: .__generic)
    }
}



// MARK: - Migrating

@available(*, unavailable, renamed: "one.addingOrThrowOnOverflow(_:)")
public func GIT_ERROR_CHECK_ALLOC_ADD<Out, One, Two>(out: inout Out, one: One, two: Two) { fatalError() }
