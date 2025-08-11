//
// TODO.swift
//
// Written by Ky on 2025-08-09.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



@dynamicCallable
package enum TODO {
    // Empty on-purpose: This type should never be initialized
}



extension TODO {
    static func dynamicallyCall(withArguments _: [Any]) throws -> Any {
        fatalError("TODO")
    }
}
