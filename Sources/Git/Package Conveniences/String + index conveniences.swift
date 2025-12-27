//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-01-16.
//

import Foundation



internal extension Collection {
    var indexRange: Range<Index> {
        startIndex..<endIndex
    }
}



internal extension RandomAccessCollection {
    var indexClosedRange: ClosedRange<Index> {
        guard startIndex != endIndex else { return startIndex ... startIndex }
        return startIndex ... index(before: endIndex)
    }
}
