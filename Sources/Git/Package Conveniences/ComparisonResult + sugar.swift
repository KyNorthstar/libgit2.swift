//
// ComparisonResult + sugar.swift
//
// Written by Ky on 2025-01-03.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



internal extension ComparisonResult {
    init<Value>(_ lhs: Value, _ rhs: Value)
    where Value: Comparable
    {
        // This behavior mimics that of `filter_def_priority_cmp`
        
        if lhs < rhs {
            self = .orderedAscending
        }
        else if lhs > rhs {
            self = .orderedDescending
        }
        else {
            self = .orderedSame
        }
    }
    
    
    init<Value, Compared>(_ lhs: Value, _ rhs: Value, by comparableField: KeyPath<Value, Compared>)
    where Compared: Comparable
    {
        self.init(lhs[keyPath: comparableField], rhs[keyPath: comparableField])
    }
    
    
    @inline(__always)
    init<I: SignedInteger>(cValue: I) {
        if case .zero = cValue {
            self = .orderedSame
        }
        else if cValue < .zero {
            self = .orderedAscending
        }
        else {
            self = .orderedDescending
        }
    }
}
