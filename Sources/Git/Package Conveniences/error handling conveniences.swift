//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-08-09.
//

import Foundation



/// Mimics some error handling in libgit2.
///
/// Many places in the original C codebase perform some operation when an error is less than zero (but not when it's greater than zero), like this:
/// ```c
/// int error = 0;
/// if ((error = git_some_function()) < 0) {
///     handleTheError()
///     return -1
/// }
/// ```
///
/// This allows you to neatly replicate that behavior with libgit2.swift functions which throw `GitError`,like this:
/// ```swift
/// try handleErrorsWithCodesButNotKinds {
///     try git_some_function()
/// }
/// catch: { _ in
///     handleTheError()
///     throw .generic
/// }
/// ```
///
/// - Parameters:
///   - closure: The code which might error out
///   - handler: Handles when the `closure` code errors out with a `.code`, but not with a `.kind`
package func handleErrorsWithCodesButNotKinds<Value>(
    do closure: () throws(GitError) -> Value,
    catch handler: (GitError) throws(GitError) -> Value
)
throws(GitError) {
    do {
        try closure()
    }
    catch where error.hasCodeButNotKind {
        try handler(error)
    }
    catch {}
}



package extension GitError {
    /// `true` iff this error has a `.code` _**but not**_ a `.kind`. This is typical.
    var hasCodeButNotKind: Bool {
        return nil != code
            && nil == kind
    }
}
