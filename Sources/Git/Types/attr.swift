//
// attr.swift
//
// Written by Ky on 2025-02-14.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



/**
* An options structure for querying attributes.
*/
public struct git_attr_options: AnyStructProtocol, Versioned {
    
    public var version: Version
    
    /** A combination of GIT_ATTR_CHECK flags */
    public var flags: git_attr_check
    
    public var reserved: AnyTypeProtocol?
    
    /**
     * The commit to load attributes from, when
     * `GIT_ATTR_CHECK_INCLUDE_COMMIT` is specified.
     */
    public var attr_commit_id: Oid?
    
    
    init(version: Version, flags: git_attr_check, reserved: AnyTypeProtocol? = nil, attr_commit_id: Oid? = nil) {
        self.version = version
        self.flags = flags
        self.reserved = reserved
        self.attr_commit_id = attr_commit_id
    }
    
    
    public init(version: Version) {
        self.init(version: version, flags: [], reserved: nil, attr_commit_id: nil)
    }
}



public enum git_attr_check: CUnsignedInt, AnyEnumProtocol, AutoOptionSet {
    public static let __empty: git_attr_check = GIT_ATTR_CHECK_FILE_THEN_INDEX
    
    /**
     * Check attribute flags: Reading values from index and working directory.
     *
     * When checking attributes, it is possible to check attribute files
     * in both the working directory (if there is one) and the index (if
     * there is one).  You can explicitly choose where to check and in
     * which order using the following flags.
     *
     * Core git usually checks the working directory then the index,
     * except during a checkout when it checks the index first.  It will
     * use index only for creating archives or for a bare repo (if an
     * index has been specified for the bare repo).
     */
    case GIT_ATTR_CHECK_FILE_THEN_INDEX = 0 // 0b00
    case GIT_ATTR_CHECK_INDEX_THEN_FILE = 1 // 0b01
    case GIT_ATTR_CHECK_INDEX_ONLY      = 2 // 0b10
    
    
    /**
     * Check attribute flags: controlling extended attribute behavior.
     *
     * Normally, attribute checks include looking in the /etc (or system
     * equivalent) directory for a `gitattributes` file.  Passing the
     * `GIT_ATTR_CHECK_NO_SYSTEM` flag will cause attribute checks to
     * ignore that file.
     *
     * Passing the `GIT_ATTR_CHECK_INCLUDE_HEAD` flag will use attributes
     * from a `.gitattributes` file in the repository at the HEAD revision.
     *
     * Passing the `GIT_ATTR_CHECK_INCLUDE_COMMIT` flag will use attributes
     * from a `.gitattributes` file in a specific commit.
     */
    case GIT_ATTR_CHECK_NO_SYSTEM      = 0b00100 // (1 << 2)
    case GIT_ATTR_CHECK_INCLUDE_HEAD   = 0b01000 // (1 << 3)
    case GIT_ATTR_CHECK_INCLUDE_COMMIT = 0b10000 // (1 << 4)
}



public struct attr_walk_up_info {
    var repo: Repository?
    var attr_session: git_attr_session?
    var opts: git_attr_options?
    var workdir: String?
    var index: Index?
    var files: SelfSortingArray<TODO>?
}
