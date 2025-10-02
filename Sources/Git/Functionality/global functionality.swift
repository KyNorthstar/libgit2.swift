//
// global functionality.swift
//
// Written by Ky on 2024-12-07.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public extension Libgit2 {
    
    /**
     * Init the global state
     *
     * This function must be called before any other libgit2 function in
     * order to set up global state and threading.
     *
     * This function may be called multiple times - it will return the number
     * of times the initialization has been called (including this one) that have
     * not subsequently been shutdown.
     *
     * - Returns: the number of initializations of the library
     */
    // Analogous to `git_libgit2_init`
    @MainActor
    @discardableResult
    static func initialize() async throws(GitError) -> InitializedCount {
        try await Runtime.initialize(initializationFunctions: init_fns)
    }
    
    
    /**
     * Shutdown the global state
     *
     * Clean up the global state and threading context after calling it as
     * many times as `git_libgit2_init()` was called - it will return the
     * number of remainining initializations that have not been shutdown
     * (after this one).
     *
     * - Returns: the number of remaining initializations of the library
     */
    @MainActor
    @discardableResult
    static func shutdown() async throws(GitError) -> InitializedCount {
        try await Runtime.shutdown()
    }
}



public typealias InitializedCount = Int



private extension Libgit2 {
    
    @MainActor
    static let init_fns: [Runtime.InitFunction] = {
        let general: [Runtime.InitFunction?] = [
//            git_allocator_global_init,
            GitError.initialize,
//            git_threads_global_init,
//            git_oid_global_init,
//            git_rand_global_init,
//            git_hash_global_init,
            SysDir.globalInit,
            git_filter_global_init, // Filter.globalInit,
            git_merge_driver_global_init,
            git_transport_ssh_libssh2_global_init,
            git_stream_registry_global_init,
            git_socket_stream_global_init,
            git_openssl_stream_global_init,
            git_mbedtls_stream_global_init,
            git_mwindow_global_init,
            git_pool_global_init,
            git_settings_global_init
        ]
        
        #if os(Windows)
        return [git_win32_leakcheck_global_init] + general
        #else
        return general
        #endif
    }()
}



// MARK: - Migration

@available(*, unavailable, renamed: "Libgit2.initialize()")
public func git_libgit2_init() -> CInt { -1 }

@available(*, unavailable, renamed: "Libgit2.shutdown()")
public func git_libgit2_shutdown() -> CInt { -1 }
