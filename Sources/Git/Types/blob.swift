//
// blob.swift
//
// Written by Ky on 2025-01-24.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import Either



public struct git_blob: AnyStructProtocol {
    public var object: Object
    public var data: Either<git_odb_object, Raw>
    public var raw: CUnsignedInt = 1
    
    public init(object: Object, data: Either<git_odb_object, Raw>, raw: CUnsignedInt) {
        self.object = object
        self.data = data
        self.raw = raw
    }
}



public extension git_blob {
    struct Raw: AnyStructProtocol {
        public var data: String
        
        public init(data: String) {
            self.data = data
        }
    }
}



@available(*, unavailable)
public extension git_blob.Raw {
    @available(*, unavailable, renamed: "data.count")
    var size: git_object_size_t { fatalError() }
}
