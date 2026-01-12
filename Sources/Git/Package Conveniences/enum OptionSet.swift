//
// enum OptionSet.swift
//
// Written by Ky on 2025-01-03.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



// TODO: Test



/// Apply this to an `enum` to automatically make it an ``OptionSet``
public protocol AutoOptionSet: RawRepresentable, OptionSet, CaseIterable, AnyEnumProtocol
where RawValue: FixedWidthInteger, Element == Self
{
    /// This represents an empty `OptionSet` of this type.
    ///
    /// - Attention: To implementers: This _must_ be a pre-calculated value, _never_ a computed variable. This _must never_ use array literal initialization nor `.init(rawValue:)`, or a stack overflow will occur
    static var __empty: Self { get }
}



public extension AutoOptionSet {
    
    init(rawValue: RawValue) { // TODO: Test
        if rawValue == Self.__empty.rawValue {
            self = .__empty
        }
        else {
            self = Self.allCases.reduce(into: Self.__empty) { optionSet, flag in
                if 0 != (flag.rawValue & rawValue) {
                    optionSet.insert(flag)
                }
            }
        }
    }
    
    
    static func calculateRawValueAfterLastOption() -> RawValue { // TODO: Test
        let shift = allCases.lazy.map(\.rawValue).max()?.trailingZeroBitCount ?? allCases.count
        return 1 << min(shift, RawValue.max.bitWidth - 1)
    }
}
