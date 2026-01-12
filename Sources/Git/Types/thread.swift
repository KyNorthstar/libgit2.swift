//
// thread.swift
//
// Written by Ky on 2024-11-10.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/// Protects access to atomic values
@globalActor
public final actor Volatile: GlobalActor {
    public static var shared = Volatile()
    
    @Volatile
    static func run<Value>(_ block: @Volatile () -> Value) -> Value {
        block()
    }
    
    
    @Volatile
    static func run<Value>(_ block: @Volatile () throws(GitError) -> Value) throws(GitError) -> Value {
        try block()
    }
}



@available(*, deprecated, renamed: "Volatile", message: "Better to use Swift's builtin @globalActor approach for exclusive access")
public typealias ThreadReadWriteLock = pthread_rwlock_t



//public typealias Atomic32 = Atomic<__int32_t>
//public typealias Atomic64 = Atomic<__int64_t>
//
//
//
//@Volatile
//@propertyWrapper
//public struct Atomic<WrappedValue>: AnyStructProtocol {
//    
//    public var wrappedValue: WrappedValue
//    
//    
//    public init(wrappedValue: WrappedValue) {
//        self.wrappedValue = wrappedValue
//    }
//}



public enum TlsData {}



public actor Mutex: AnyActorProtocol {
    func run<Return>(_ block: () -> Return) -> Return {
        block()
    }
    
    
    func run<Return, E: Error>(_ block: () throws(E) -> Return) throws(E) -> Return {
        try block()
    }
    
    
    func run<Return>(_ block: () throws(GitError) -> Return) throws(GitError) -> Return {
        try block()
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "Int32", message: "Simply mark the value as `@Volatile`")
public typealias git_atomic32 = Never//Atomic32

@available(*, unavailable, renamed: "Int64", message: "Simply mark the value as `@Volatile`")
public typealias git_atomic64 = Never//Atomic64

@available(*, unavailable, renamed: "Mutex")
public typealias git_mutex = Mutex

//@available(*, unavailable, message: "Use structured concurrency instead. If you need atomic access to a value, mark it `@Volatile`.")
//public typealias Mutex = CUnsignedInt

@available(*, unavailable, renamed: "ThreadReadWriteLock")
public typealias git_rwlock = ThreadReadWriteLock

//@available(*, unavailable)
//public extension Atomic32 {
//    @available(*, unavailable, renamed: "wrappedValue")
//    var val: CInt { fatalError("use wrappedValue") }
//}
//
//@available(*, unavailable)
//public extension Atomic64 {
//    @available(*, unavailable, renamed: "wrappedValue")
//    var val: __int64_t { fatalError("use wrappedValue") }
//}


@available(*, unavailable, message: "Mark the field as @Volatile and use normal assignment")
public func git_atomic32_set(_: inout __int32_t, _: CInt) {}

@available(*, unavailable, message: "Mark the field as @Volatile and use normal increment")
public func git_atomic32_inc(_: inout __int32_t) -> CInt { fatalError() }

@available(*, unavailable, message: "Mark the field as @Volatile and use normal addition")
public func git_atomic32_add(_: inout __int32_t, _: __int32_t) -> CInt { fatalError() }

@available(*, unavailable, message: "Mark the field as @Volatile and use normal decrement")
public func git_atomic32_dec(_: inout __int32_t) -> CInt { fatalError() }

@available(*, unavailable, message: "Mark the field as @Volatile and use normal getting")
public func git_atomic32_get(_: inout __int32_t) -> CInt { fatalError() }


@available(*, unavailable, renamed: "OSAtomicCompareAndSwapPtr", message: "Remember to move `ptr` to the last argument!")
public func git_atomic__compare_and_swap(
    ptr: inout UnsafeMutableRawPointer?, oldVal: UnsafeMutableRawPointer, newVal: UnsafeMutableRawPointer)
-> Bool
{
    OSAtomicCompareAndSwapPtr(oldVal, newVal, &ptr)
}

@available(*, unavailable, message: "TODO")
public func git_atomic__swap(
    _: inout UnsafeMutableRawPointer, _: UnsafeMutableRawPointer)
-> UnsafeMutablePointer<UnsafeMutableRawPointer>
{ fatalError("TODO") }

@available(*, unavailable, message: "TODO")
public func git_atomic__load(_: inout UnsafeMutableRawPointer) -> UnsafeMutablePointer<UnsafeMutableRawPointer> { fatalError("TODO") }

@available(*, unavailable, message: "TODO")
public func git_atomic64_add(_: inout git_atomic64, _: __int64_t) -> __int64_t {}

@available(*, unavailable, message: "TODO")
public func git_atomic64_set(_: inout git_atomic64, _: __int64_t) {}

@available(*, unavailable, message: "TODO")
public func git_atomic64_get(_: inout git_atomic64) -> __int64_t {}
