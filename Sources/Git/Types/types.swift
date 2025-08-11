//
// commit_graph.swift
//
// Written by Ky on 2024-11-10.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public typealias FileSize = __int64_t;

/** time in seconds from epoch */
// Analogous to `git_time_t`
public typealias IntSecondsSinceEpoch = __int64_t;

/** The maximum size of an object */
public typealias git_object_size_t =  __uint64_t


/** Time in a signature */
public struct Time: AnyStructProtocol {
    
    /// time in seconds from epoch
    public var time: IntSecondsSinceEpoch
    
    /// timezone offset, in minutes
    public var offset: CInt
    
    /// indicator for questionable '-0000' offsets in signature
    public var sign: CChar
}


/// An action signature (e.g. for committers, taggers, etc)
public struct git_signature: AnyStructProtocol {
    
    /// full name of the author
    public var name: String
    
    /// email of the author
    public var email: String
    
    /// time when the action happened
    public var when: Time
}



/** A type to write in a streaming fashion, for example, for filters. */
public protocol Writestream: ~Copyable {
    mutating func write(data: String) throws(GitError) -> Void
    mutating func close() throws(GitError) -> Void
    
    
    
    associatedtype Base: Writestream = Self
    
    
    
    typealias WriteFunction = @Sendable (_ `self`: inout Base) -> _WriteFunction_Method
    typealias _WriteFunction_Method = @Sendable (_ data: String) throws(GitError) -> Void
    
    typealias CloseFunction = @Sendable (_ `self`: inout Base) -> _CloseFunction_Method
    typealias _CloseFunction_Method = @Sendable () throws(GitError) -> Void
    
    typealias FreeFunction = @Sendable (_ `self`: inout Base) -> _FreeFunction_Method
    typealias _FreeFunction_Method = @Sendable () -> Void
}



public extension Writestream {
    mutating func close() throws(GitError) -> Void { }
    
    @available(*, deprecated, message: "These operations should be performed in `deinit`")
    mutating func free() -> Void { }
}



///// The most barebones implementation of a ``Writestream``
//public struct CustomWritestream<Base: Writestream>: Writestream, AnyStructProtocol {
//    public var writeFunction: Base.WriteFunction
//    public var closeFunction: Base.CloseFunction?
//    public var freeFunction: Base.FreeFunction?
//}



// MARK: - Consistency

/// All types in this repo should conform to this by default
public typealias AnyTypeProtocol = Copyable

/// All value types (e.g. `struct`s, `enum`s, etc.) in this repo should conform to this by default
public typealias AnyValueTypeProtocol = AnyTypeProtocol & Sendable

/// All `struct`s in this repo should conform to this by default
public typealias AnyStructProtocol = AnyValueTypeProtocol

/// All `enum`s in this repo should conform to this by default
public typealias AnyEnumProtocol = AnyValueTypeProtocol

/// All reference types should conform to this by default. Equivalent to `void *` in libgit2
public typealias AnyRefProtocol = AnyTypeProtocol & AnyObject

/// All `class`es in this repo should conform to this by default
public typealias AnyClassProtocol = AnyRefProtocol

/// All `actor`s in this repo should conform to this by default
public typealias AnyActorProtocol = AnyRefProtocol & Actor



// MARK: - Fuck C

public typealias CUnsigned = CUnsignedInt



// MARK: - Migration

@available(*, unavailable, renamed: "Time")
public typealias git_time = Time

@available(*, unavailable, renamed: "IntSecondsSinceEpoch")
public typealias git_time_t = IntSecondsSinceEpoch

@available(*, unavailable, renamed: "FileSize")
public typealias git_off_t = FileSize

@available(*, unavailable, renamed: "AnyRefProtocol", message: "`void *` could mean 'a pointer to any type' or 'a raw pointer'. You might consider `Data?`, `AnyObject?`, `UnsafeMutableRawPointer?` or Swift generics")
public typealias VoidStar = AnyRefProtocol


@available(*, unavailable, renamed: "String", message: "`char *` is a C string")
public typealias CharStar = UnsafePointer<CChar>


@available(*, unavailable, renamed: "Data", message: "`unsigned char *` means 'contiguous bytes in memory', which is exactly what `Data` means")
public typealias UnsignedCharStar = Data


@available(*, unavailable, renamed: "Writestream")
public typealias git_writestream = Writestream
