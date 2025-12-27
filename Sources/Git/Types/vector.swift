//
// vector.swift
//
// Written by Ky on 2024-11-11.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



@available(*, deprecated, message: "Use a strongly-typed array instead")
public typealias ArbitraryArray = [any AnyTypeProtocol]

public typealias AnyTypeComparator<Value> = @Sendable (Value, Value) -> ComparisonResult



/// An array with a built-in way to self-sort as items are added
// Analogous to `git_vector`
public struct SelfSortingArray<Element: AnyTypeProtocol>: AnyStructProtocol {
    public var comparator: AnyTypeComparator<Element>?
    public var contents: Contents
    public var flags: Flags
    
    // Analogous to `git_vector_init`
    public init(contents: [Element] = [], comparator: @escaping AnyTypeComparator<Element>)
    where Element: Comparable {
        self.comparator = comparator
        self.contents = contents
        self.flags = flags.union(.sorted)
    }
    
    
    public init<Compared: Comparable & AnyTypeProtocol>(
        contents: [Element] = [],
        comparingBy comparisonKeypath: KeyPath<Element, Compared>,
        flags: Flags = [])
    {
        let comparisonKeypath = comparisonKeypath
        self.comparator = { .init($0, $1, by: comparisonKeypath) }
        self.contents = contents
        self.flags = flags.union(.sorted)
    }
    
    
    public init(contents: [Element] = [], flags: Flags = []) {
        self.comparator = nil
        self.contents = contents
        self.flags = flags.subtracting(.sorted)
    }
    
    
    public init() {
        self.comparator = nil
        self.contents = []
        self.flags = []
    }
    
    
    public typealias Contents = [Element]
}



// MARK: - Conformance

extension SelfSortingArray: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Element...) {
        if elements.isEmpty {
            self.init(contents: [])
        }
        else {
            self.init(contents: elements)
        }
    }
}



extension SelfSortingArray: Sequence {
    public typealias Index = Contents.Index
    public typealias Iterator = IndexingIterator<Self>
}



extension SelfSortingArray: Collection {
    public func index(after i: Contents.Index) -> Contents.Index {
        contents.index(after: i)
    }
    
    
    public subscript(position: Contents.Index) -> Element {
        get { contents[position] }
        set { contents[position] = newValue }
    }
    
    
    public var startIndex: Contents.Index {
        contents.startIndex
    }
    
    
    public var endIndex: Contents.Index {
        contents.endIndex
    }
}



extension SelfSortingArray: RandomAccessCollection {}



extension SelfSortingArray: RangeReplaceableCollection {
    public mutating func replaceSubrange<C>(_ subrange: Range<Int>, with newElements: C) where C: Collection, C.Element == Element {
        contents.replaceSubrange(subrange, with: newElements)
    }
}



// MARK: - Auxiliary types

public extension SelfSortingArray {
    enum Flags: CUnsignedInt, AutoOptionSet, AnyStructProtocol {
        case __empty = 0
        case sorted = 0b0001 // 1u << 0
        
        // Analogous to `GIT_VECTOR_FLAG_MAX`
        static var max: RawValue { __Flags_max } // 1u << 2
    }
}



infix operator <~> : ComparisonPrecedence



/// Sugar for creating a comparison result by comparing two comparable values
///
/// - Parameters:
///   - lhs: The left value to compare
///   - rhs: The right value to compare
/// - Returns: The result of comparing them
public func <~> <T: Comparable> (lhs: T, rhs: T) -> ComparisonResult {
    if lhs < rhs {
        .orderedAscending
    }
    else if lhs == rhs {
        .orderedSame
    }
    else {
        .orderedDescending
    }
}



private let __Flags_max = SelfSortingArray<AnyTypeProtocol>.Flags.calculateRawValueAfterLastOption() // 1u << 2



// MARK: - Migration

@available(*, unavailable, renamed: "AnyTypeComparator")
public typealias git_vector_cmp = AnyTypeComparator

@available(*, unavailable, renamed: "SelfSortingArray")
public typealias git_vector = SelfSortingArray



@available(*, unavailable)
public extension git_vector {
    @available(*, unavailable, renamed: "contents.capacity") // TODO: is this the corret interpretation of the C code?
    var _alloc_size: size_t { fatalError() }
    
    @available(*, unavailable, renamed: "comparator")
    var _cmp: git_vector_cmp<Any>? { fatalError() }
    
    @available(*, unavailable, renamed: "count")
    var length: size_t { fatalError() }
}

@available(*, unavailable, renamed: "SelfSortingArray.init")
public func git_vector_init(_: inout git_vector<Any>, _: size_t, _: git_vector_cmp<Any>) -> CInt { fatalError() }


@available(*, unavailable, renamed: "SelfSortingArray.Flags.sorted")
public var GIT_VECTOR_SORTED: SelfSortingArray<Never>.Flags { fatalError() }

@available(*, unavailable, renamed: "SelfSortingArray.Flags.max")
public var GIT_VECTOR_FLAG_MAX: SelfSortingArray<Never>.Flags { fatalError() }



