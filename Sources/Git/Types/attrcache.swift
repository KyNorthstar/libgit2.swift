//
// attrcache.swift
//
// Written by Ky on 2024-11-11.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public actor AttributeCache: AnyActorProtocol { // actor because it needs reference semantics and thread safety
    public var cfg_attr_file: String? /* cached value of core.attributesfile */
    public var cfg_excl_file: String? /* cached value of core.excludesfile */
    public var files: StringMap      /* hash path to git_attr_cache_entry records */
    public var macros: StringMap     /* hash name to vector<git_attr_assignment> */
    public var pool: Pool?
    
    
    init(cfg_attr_file: String? = nil,
         cfg_excl_file: String? = nil,
         files: StringMap = [:],
         macros: StringMap = [:],
         pool: Pool? = nil)
    {
        self.cfg_attr_file = cfg_attr_file
        self.cfg_excl_file = cfg_excl_file
        self.files = files
        self.macros = macros
        self.pool = pool
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "AttributeCache")
public typealias git_attr_cache = AttributeCache


@available(*, unavailable)
public extension git_attr_cache {
    @available(*, unavailable, message: "No mutex needed; AttributeCache is an actor")
    var mutex: Mutex { fatalError() }
}
