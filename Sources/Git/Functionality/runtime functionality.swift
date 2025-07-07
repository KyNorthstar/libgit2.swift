//
// runtime functionality.swift
//
// Written by Ky on 2024-12-07.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



// MARK: - Public functionality

public extension Runtime {
    
    /// The number of initializations active (the number of calls to ``initialize(initializationFunctions:)`` minus the number of calls sto ``shutdown()``).
    ///
    /// If 0, the runtime is not currently initialized.
    ///
    /// Can also be thought of as the number of initializations performed
    @Volatile
    private(set) static var initCount: InitializedCount = 0
    
    
    /**
     * Start up a new runtime.  If this is the first time that this
     * function is called within the context of the current library
     * or executable, then the given `initializationFunctions` will be invoked.  If
     * it is not the first time, they will be ignored.
     *
     * The given initialization functions _may_ register shutdown
     * handlers using ``registerShutdownHook(_:)`` to be notified
     * when the runtime is shutdown.
     *
     * - Parameter initializationFunctions: The list of initialization functions to call
     * - Returns: The number of initializations performed (including this one)
     */
    @InitLock
    // Analogous to `git_runtime_init`
    static func initialize(initializationFunctions: [InitFunction]) async throws(GitError) -> InitializedCount {
        
        let thisInitCount = await Volatile.run {
            initCount += 1
            return initCount
        }
        
        /* Only do work on a 0 -> 1 transition of the refcount */
        if 1 == thisInitCount {
            try await init_common(initializationFunctions)
        }
        
        // The above code translates this original C code:
        //
        // if ((ret = git_atomic32_inc(&init_count)) == 1) {
        //     if (init_common(init_fns, cnt) < 0)
        //         ret = -1;
        // }

        return thisInitCount
    }
    
    
    /**
     * Shut down the runtime.  If this is the last shutdown call,
     * such that there are no remaining `init` calls, then any
     * shutdown hooks that have been registered will be invoked.
     *
     * The number of outstanding initializations will be returned.
     * If this number is 0, then the runtime is shutdown.
     *
     * - Returns: The number of outstanding initializations (after this one)
     */
    @InitLock
    // Analogous to `git_runtime_shutdown`
    static func shutdown() async throws(GitError) -> InitializedCount {
        let ret = await Volatile.run {
            initCount -= 1
            return initCount
        }
        
        /* Only do work on a 1 -> 0 transition of the refcount */
        if (0 == ret) {
            await shutdown_common()
        }
        
        return ret
    }
    
    /**
     * Register a shutdown handler for this runtime.  This should be done
     * by a function invoked by `git_runtime_init` to ensure that the
     * appropriate locks are taken.
     *
     * - Parameter callback: The shutdown handler callback
     */
    @InitLock
    static func registerShutdownHook(_ callback: @escaping ShutdownFunction) async {
        await Volatile.run {
            shutdownCallbacks.append(callback)
        }
    }
    
    
    
    typealias InitFunction = @Sendable () async throws(GitError) -> Void
    
    typealias ShutdownFunction = @Volatile () async -> Void
}



public extension Runtime {
    @globalActor
    final actor InitLock: GlobalActor, AnyActorProtocol {
        public static let shared = ActorType()
        
        public typealias ActorType = InitLock
    }
}



// MARK: - Private functionality



internal extension Runtime {
    
    @Volatile
    private static var shutdownCallbacks = [ShutdownFunction]()
    
    
    
    /// Initialize subsystems that have global state
    ///
    /// - Parameter initFunctions: Each of these is called in sequence. If any throws an error, that error is thrown and this function exits without executing further init functions
    ///
    /// - Throws: The first error any given init function throws
    @InitLock
    @inline(__always)
    static func init_common(_ initFunctions: [InitFunction]) async throws(GitError) {
        for initFunction in initFunctions {
            try await initFunction()
        }
    }
    
    
    /// Calls all the shutdown callbacks in reverse order, popping each one off the list of shutdown callbacks immediately before calling it.
    ///
    /// When this returns, all shutdown callbacks will have been called and removed from the list of shutdown callbacks
    @Volatile
    static func shutdown_common() async {
        while let callback = shutdownCallbacks.popLast() {
            await callback()
        }

        // The above code translates this original C code:
        //
        // for (pos = git_atomic32_get(&shutdown_callback_count);
        //      pos > 0;
        //      pos = git_atomic32_dec(&shutdown_callback_count)) {
        //     cb = git_atomic_swap(shutdown_callback[pos - 1], NULL);
        //
        //     if (cb != NULL)
        //         cb();
        // }
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "Git.Runtime.InitFunction")
public typealias git_runtime_init_fn = () -> CInt

@available(*, unavailable, renamed: "Git.Runtime.ShutdownFunction")
public typealias git_runtime_shutdown_fn = () -> Void

@available(*, unavailable, renamed: "Git.Runtime.initialize(initializationFunctions:)")
public func git_runtime_init(_: [git_runtime_init_fn], _: size_t) -> CInt { -1 }

@available(*, unavailable, renamed: "Git.Runtime.initCount")
public func git_runtime_init_count() -> CInt { -1 }

@available(*, unavailable, renamed: "Git.Runtime.shutdown()")
public func git_runtime_shutdown() -> CInt { -1 }

@available(*, unavailable, renamed: "Git.Runtime.registerShutdownHook(_:)")
public func git_runtime_shutdown_register(_: git_runtime_shutdown_fn) -> CInt { -1 }
