//
// assert_safe functionality.swift
//
// Written by Ky on 2024-12-09.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// Safely guarantees the given expression is non-`nil` in production, without crashing.
///
/// If the given expression is found to be `nil`, then a Swift error is thrown.
///
/// ```swift
/// func requiresNonNil(but argMightBeNil: String?) throws(GitError) {
///     let nonNilArg = try assert(argMightBeNil, expressionLabel: "argMightBeNil")
/// }
/// ```
///
/// - Parameters:
///   - expr:            The expression to test.
///   - expressionLabel: _optional_ - **Encouraged!** Labels the expression in the thrown error. This should be the name of the argument you're testing. Defaults to `#function`.
///   - onNil:           _optional_ - Information logged/thrown when handling the `nil` case. Defaults to something generic.
///   - cleanup:         _optional_ - Called after the error is thrown but before the function returns, in case you need to perform any cleanup work. This does not run when the value is non-`nil`.
///
/// - Returns: The value of `expr`, iff it is non-`nil`.
///
/// - Throws: A ``GitError`` iff `expr` is `nil`, containing information provided in `expressionLabel` and `onNil`
@discardableResult
internal func assert<T>(
    expr: T?,
    expressionLabel: String = #function,
    onNil: @autoclosure () -> (
        errorKind: GitError.Kind,
        errorMessage: String) = (
            errorKind: .internal,
            errorMessage: "Internal inconsistency error. Will attempt to recover."
        ),
    cleanup: () -> Void = {})
throws(GitError) -> T {
    guard let expr else {
        defer { cleanup() }
        let onNil = onNil()
        throw .init(message: "\(onNil.errorMessage): \(expressionLabel)", kind: onNil.errorKind)
    }
    
    return expr
}



// MARK: - Migration

/** Internal consistency check to stop the function. */
@available(*, deprecated, renamed: "assert(expr:expressionLabel:cleanup:)", message: "This has been replaced with a more Swiftey version")
internal func GIT_ASSERT<T>(expr: T?, expressionLabel: String = #function) throws(GitError) -> T {
    try GIT_ASSERT_WITH_CLEANUP(expr: expr, expressionLabel: expressionLabel)
    
    // The above code replaces this original C code:
    //
    // GIT_ASSERT_WITH_RETVAL(expr, -1)
}

/**
 * Assert that a consumer-provided argument is valid, setting an
 * actionable error message and returning -1 if it is not.
 */
@available(*, deprecated, renamed: "assert(expr:expressionLabel:cleanup:)", message: "This has been replaced with a more Swiftey version")
internal func GIT_ASSERT_ARG<T>(expr: T?, argumentName: String = #function) throws(GitError) -> T {
    try GIT_ASSERT_WITH_CLEANUP(expr: expr, expressionLabel: argumentName)
    
    // The above code replaces this original C code:
    //
    // GIT_ASSERT_ARG_WITH_RETVAL(expr, -1)
}

/** Internal consistency check to return the `fail` param on failure. */
@available(*, deprecated, renamed: "??", message: "Since libgit2.swift uses native erros instead of a side error channel, this doesn't do anything special. The `??` might be more appropriate")
internal func GIT_ASSERT_WITH_RETVAL<T>(expr: T?, expressionLabel: String = #function, backup: @autoclosure () -> T) -> T {
    GIT_ASSERT__WITH_RETVAL(
        expr: expr,
        expressionLabel: expressionLabel,
        onNil: (kind: .internal,
                msg: "unrecoverable internal error"),
        backup: backup())
}

/**
 * Assert that a consumer-provided argument is valid, setting an
 * actionable error message and returning the `fail` param if not.
 */
@available(*, deprecated, message: "Since libgit2.swift uses native erros instead of a side error channel, this doesn't do anything special. `guard let` might be more appropriate")
internal func GIT_ASSERT_ARG_WITH_RETVAL<T>(expr: T?, expressionLabel: String = #function, backup: @autoclosure () -> T) -> T {
    GIT_ASSERT__WITH_RETVAL(
        expr: expr,
        expressionLabel: expressionLabel,
        onNil: (kind: .invalid,
                msg: "invalid argument"),
        backup: backup())
}

@available(*, deprecated, message: "Since libgit2.swift uses native erros instead of a side error channel, this doesn't do anything special. `guard let` might be more appropriate")
internal func GIT_ASSERT__WITH_RETVAL<T>(
    expr: T?,
    expressionLabel: String = #function,
    onNil: @autoclosure () -> (
        kind: GitError.Kind,
        msg: String),
    backup: @autoclosure () -> T)
-> T {
    guard let expr else {
        // Do something more???
        let onNil = onNil()
        print(#function, "\(onNil.msg): \(expressionLabel)")
//        git_error_set(kind, "%s: '%s'", msg, #expr)
        return backup()
    }
    
    return expr
}

/**
 * Go to to the given label on assertion failures; useful when you have
 * taken a lock or otherwise need to release a resource.
 */
@available(*, deprecated, renamed: "assert(expr:expressionLabel:cleanup:)", message: "This has been replaced with a more Swiftey version")
internal func GIT_ASSERT_WITH_CLEANUP<T>(expr: T?, expressionLabel: String = #function, cleanup: () -> Void = {}) throws(GitError) -> T {
    try GIT_ASSERT__WITH_CLEANUP(
        expr: expr,
        expressionLabel: expressionLabel,
        onNil: (
            kind: .internal,
            msg: "unrecoverable internal error"),
        cleanup: cleanup)
}


@available(*, deprecated, renamed: "assert(expr:expressionLabel:onNil:cleanup:)", message: "This has been replaced with a more Swiftey version")
internal func GIT_ASSERT__WITH_CLEANUP<T>(
    expr: T?,
    expressionLabel: String,
    onNil: @autoclosure () -> (
        kind: GitError.Kind,
        msg: String),
    cleanup: () -> Void = {})
throws (GitError) -> T {
    guard let expr else {
        defer { cleanup() }
        let onNil = onNil()
        throw .init(message: "\(onNil.msg): \(expressionLabel)", kind: onNil.kind)
    }
    return expr
}
