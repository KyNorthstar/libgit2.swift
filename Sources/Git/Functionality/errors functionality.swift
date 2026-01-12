//
// errors functionality.swift
//
// Written by Ky on 2024-12-08.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public extension GitError {
    // Analogous to `git_error_global_init`
    @MainActor
    @available(*, deprecated, message: "This is likely unnecessary in Swift (seems all it did was deallocate things)")
    static func initialize() async {
        // TODO: Do we need to register on-Task-exit hooks here?
//        tls_key = Git.TlsData.onThreadExit(callback: threadstate_free)
        // TODO: Do we need to register on-shutdown hooks here?
//        await Git.Runtime.registerShutdownHook(git_error_global_shutdown)
    }
    
    
    init<E: Error>(_ anyError: E) {
        if let gitError = anyError as? Self {
            self = gitError
        }
        else if let localizedError = anyError as? LocalizedError {
            self.init(message: localizedError.bestDescription)
        }
        else {
            self.init(message: anyError.localizedDescription)
        }
    }
}



// MARK: - Predefined errors

public extension GitError {
    
    static let outOfMemory = Self(
        message: "Out of memory",
        kind: .noMemory
    )
}



// MARK: -

extension GitError: InitializableByOneArgument {
    typealias OtherType = Error
}



internal func mapError<Thrown, Mapped, Returned>(
    newType: Mapped.Type = Mapped.self,
    _ thrower: @autoclosure @Sendable () throws(Thrown) -> Returned)
throws(Mapped) -> Returned
where Thrown: Error,
    Mapped: Error,
    Mapped: InitializableByOneArgument,
    Mapped.OtherType == Thrown,
    Mapped.InitializerError == Never
{
    do {
        return try thrower()
    }
    catch {
        throw Mapped(error)
    }
}



internal func mapError<Thrown, Mapped, Returned>(
    _ thrower: @autoclosure () throws(Thrown) -> Returned,
    _ mapper: (Thrown) -> Mapped)
throws(Mapped) -> Returned
where Thrown: Error,
    Mapped: Error
{
    do {
        return try thrower()
    }
    catch {
        throw mapper(error)
    }
}



internal func mapError<NewError, Returned>(
    _ thrower: @autoclosure () throws -> Returned,
    _ alternative: () -> NewError)
throws(NewError) -> Returned
where NewError: Error
{
    do {
        return try thrower()
    }
    catch {
        throw alternative()
    }
}



//infix operator ?! : NilCoalescingPrecedence
//
//
//
//func ?! <NewError, Returned>(
//    _ thrower: @autoclosure () throws -> Returned,
//    _ alternative: @autoclosure () throws(NewError) -> Void)
//throws(NewError) -> Returned
//where NewError: Error
//{
//    do {
//        return try thrower()
//    }
//    catch {
//        try alternative()
//    }
//}



private extension LocalizedError {
    var bestDescription: String {
        let topDescription = errorDescription ?? localizedDescription
        if let recoverySuggestion {
            return """
                \(topDescription)
                
                \(recoverySuggestion)
                """
        }
        else {
            return topDescription
        }
    }
}



/**
 * Set the error message to a special value for memory allocation failure.
 *
 * The normal `git_error_set_str()` function attempts to `strdup()` the
 * string that is passed in.  This is not a good idea when the error in
 * question is a memory allocation failure.  That circumstance has a
 * special setter function that sets the error string to a known and
 * statically allocated internal value.
 */
@available(*, deprecated, renamed: "GitError.outOfMemory", message: "libgit2.swift doesn't support side-channel errors, so throwing `.outOfMemory` is the same as calling this")
public func git_error_set_oom() throws(GitError) {
    throw .outOfMemory
}



// MARK: - Migrated

@available(*, unavailable, renamed: "GitError.initialize")
public func git_error_global_init() -> CInt { fatalError() }

@available(*, unavailable, renamed: "GitError.outOfMemory")
public var oom_error: git_error { fatalError() }

@available(*, unavailable, message: "This is unnecessary in Swift. Use `try?` instead.")
public func git_clear_error() { fatalError() }
