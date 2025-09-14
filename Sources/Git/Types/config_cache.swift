//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-08-11.
//

import Foundation



internal struct map_data: AnyStructProtocol {
    public let name: String
    public var maps: [git_configmap]?
    public var map_count: size_t
    public var default_value: git_configmap_t
}
