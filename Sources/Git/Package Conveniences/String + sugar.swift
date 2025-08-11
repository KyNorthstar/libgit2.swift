//
//  String + sugar.swift
//  libgit2.swift
//
//  Created by Ky on 2025-07-09.
//

import Foundation



internal extension String {
    
    mutating func removeFirst(while predicate: (Character) throws -> Bool) rethrows {
        self = .init(try drop(while: predicate))
//        var index = startIndex
//        while index < endIndex, try predicate(self[index]) {
//            formIndex(after: &index)
//        }
//        removeSubrange(..<index)
    }
    
    
    mutating func removeLast(while predicate: (Character) throws -> Bool) rethrows {
        self = .init(try dropLast(while: predicate))
    }
    
    
    func dropLast(while predicate: (Character) throws -> Bool) rethrows -> Substring {
        var newLastIndex = index(before: endIndex)
        while newLastIndex > startIndex, try predicate(self[newLastIndex]) {
            newLastIndex = index(before: newLastIndex)
        }
        return self[..<newLastIndex]
    }
}
