//
// thread functionality.swift
//
// Written by Ky on 2024-12-07.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



///
/// Atomically replace the contents of `ptr` (if they are equal to `oldval`) with `newval`
///
/// - Returns: the original contents of `ptr`
///
@Volatile
@inline(__always)
@discardableResult
public func git_atomic_compare_and_swap<T: Equatable>(ptr: inout T, oldval: T, newval: T) async -> T {
    var foundval = ptr
    if foundval == oldval {
        ptr = newval
    }
    return foundval
}




//public extension TlsData {
//    
//    /**
//     * Create a thread-local data key.  The destroy function will be
//     * called upon thread exit.  On some platforms, it may be called
//     * when all threads have deleted their keys.
//     *
//     * - Parameter destroy_fn: function pointer called upon thread exit
//     * - Returns: The TlsData key
//     */
//    // Analogous to `git_tlsdata_init`
//    @available(*, deprecated, message: "I think Swift has a better way to do this")
//    @MainActor
//    static func onThreadExit(callback: @escaping OnThreadExit) async throws(GitError) -> Index {
//        values.append(.init(value: nil, onThreadExit: callback))
//        return values.count
//        
//        // The above code translates this original C code:
//        //
//        // if (tlsdata_cnt >= TLSDATA_MAX)
//        //     return -1;
//        //
//        // tlsdata_values[tlsdata_cnt].value = NULL;
//        // tlsdata_values[tlsdata_cnt].destroy_fn = destroy_fn;
//        //
//        // *key = tlsdata_cnt;
//        // tlsdata_cnt++;
//        //
//        // return 0;
//    }
//    
//    
//    /**
//     * Get the thread-local value for the given key.
//     *
//     * - Parameter key: the tlsdata key to retrieve the value of
//     * - Returns: the pointer stored with the setter, or `nil`
//     */
//    // Analogous to `git_tlsdata_get`
//    @available(*, unavailable, message: "Use @TaskLocal instead")
//    static func get<Value: AnyTypeProtocol>(key: Key) async -> Value? { fatalError() }
//    
//    
//    /**
//     * Set a the thread-local value for the given key.
//     *
//     * - Parameter key: the tlsdata key to store data on
//     * - Parameter value: the pointer to store
//     */
//    @available(*, unavailable, message: "Use @TaskLocal instead")
//    static func set<Value: AnyTypeProtocol>(key: Key, to value: Value) async { fatalError() }
//    
//    
//    
//    typealias Key = pthread_key_t
//    
//    typealias OnThreadExit = @Sendable (GitError.ThreadState) -> Void
//    
//    typealias Index = Array<Any>.Index
//}
//
//
//
//private extension TlsData {
//    
//    @MainActor
//    static var values: [Value] = []
//    
//    @MainActor
//    @available(*, deprecated, renamed: "values.count")
//    static var count: [Value].Index { values.count }
//    
//    
//    
//    struct Value: AnyStructProtocol {
//        var value: AnyRefProtocol?
//        var onThreadExit: OnThreadExit
//    }
//}



// MARK: - Migration

@available(*, unavailable, /*renamed: "TlsData.onThreadExit(callback:)",*/ message: "Use @TaskLocal instead")
public func git_tlsdata_init(_: inout git_tlsdata_key, _: () -> AnyRefProtocol) -> CInt { fatalError() }

@available(*, unavailable, /*renamed: "Git.TlsData.subscript(key:)",*/ message: "Use @TaskLocal instead")
public func git_tlsdata_get(_: git_tlsdata_key) -> UnsafeMutableRawPointer? { fatalError() }



@available(*, unavailable, message: "Use @TaskLocal instead")
private typealias tlsdata_value = Never//Git.TlsData.Value

@available(*, unavailable, message: "Use @TaskLocal instead")
public typealias git_tlsdata_key = Never//Git.TlsData.Key
