//
// fs_path.swift
//
// Written by Ky on 2025-06-15.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation
import SafeStringIntegerAccess


/**
 * Prepend base to unrooted path or just copy path over.
 *
 * This will optionally return the index into the path where the "root"
 * is, either the end of the base directory prefix or the path root.
 */
public func git_fs_path_join_unrooted(
    path: String,
    base: String?)
throws(GitError) -> (path: String, root_at: PathRoot)
{
    var path_out = String()
    var root: PathRoot
    
    try assert(expr: path_out)
    try assert(expr: path)
    
    root = git_fs_path_root(path)
    
    if let base, !root.isRooted {
        path_out = String(joiningPath: base, withPathComponent: path)
        
        root = .rooted(after: base)
    }
    else {
        try convertErrorsWithCodesButNotKinds(to: .generic) { () throws(_) in
            try git_str_sets(buffer: &path_out, source: path)
        }
        do {
            try git_str_sets(buffer: &path_out, source: path)
        }
        catch where error.hasCodeButNotKind {
            throw .generic
        }
        catch {}

        if !root.isRooted {
            root = .rooted(offset: 0)
        }
        else if let base {
            root = .init(offset: git_fs_path_equal_or_prefixed(parent: base, child: path).prefixLength)
        }
    }
    
    return (path: path_out, root_at: root)
}


/// Result of comparing two POSIX-style paths for equality or prefix relationship.
public enum FSPathCompareResult {
    case notEqual                  // Corresponds to GIT_FS_PATH_NOTEQUAL
    case equal(prefixLength: Int)  // Corresponds to GIT_FS_PATH_EQUAL
    case prefix(prefixLength: Int) // Corresponds to GIT_FS_PATH_PREFIX
}



public extension FSPathCompareResult {
    var prefixLength: Int? {
        switch self {
            case .equal(prefixLength: let v),
                .prefix(prefixLength: let v):
            return v
            
        case .notEqual:
            return nil
        }
    }
}



/// Determines if a path is equal to or potentially a child of another.
///
/// - Parameters:
///   - parent: The possible parent
///   - child:  The possible child
@inline(__always)
public func git_fs_path_equal_or_prefixed(
    parent: String,
    child: String)
-> FSPathCompareResult {
    if parent == child {
        return .equal(prefixLength: parent.count)
    }
    
    guard child.hasPrefix(parent) else {
        return .notEqual
    }
    
    let remainingChild = child.dropFirst(parent.count)
    
    if remainingChild.first == "/" {
        // Parent's path without trailing slash
        let prefixLength = parent.hasSuffix("/")
            ? parent.count - 1
            : parent.count
        return .prefix(prefixLength: prefixLength)
    }
    else if parent.hasSuffix("/") {
        // Parent ends with slash, child continues directly
        return .prefix(prefixLength: parent.count - 1)
    }
    else {
        // String prefix but not directory boundary (e.g., "foo" vs "foobar")
        return .notEqual
    }
}



public enum PathRoot: AnyEnumProtocol {
    
    /// The path has a root
    /// - Parameter offset: The offset of the root in the path
    case rooted(offset: RawValue)
    
    /// The path has no root
    ///
    /// The C version of this used `-1` to represent this value
    case notRooted
}



public extension PathRoot {
    static func rooted(after prefix: String) -> Self {
        .rooted(offset: prefix.count)
    }
}



extension PathRoot: RawRepresentable {
    
    public init(rawValue: RawValue) {
        self = switch rawValue {
        case 0...: .rooted(offset: rawValue)
        default:   .notRooted
        }
    }
    
    
    public init(offset: RawValue?) {
        if let offset {
            self.init(rawValue: offset)
        }
        else {
            self = .notRooted
        }
    }
    
    
    @available(*, deprecated, renamed: "rootOffset", message: "Directly using the raw value of this enum is discouraged. Use `rootOffset` to determine the root offset, or compare enum values instead.")
    public var rawValue: RawValue {
        switch self {
        case .rooted(let offset): offset
        case .notRooted:          -1
        }
    }
    
    
    public var rootOffset: RawValue? {
        switch self {
        case .rooted(let offset): offset
        case .notRooted:          nil
        }
    }
    
    
    public var isRooted: Bool {
        switch self {
        case .rooted:    true
        case .notRooted: false
        }
    }
    
    
    
    public typealias RawValue = Int
}



/**
 * Find offset to root of path if path has one.
 *
 * This will return a number >= 0 which is the offset to the start of the
 * path, if the path is rooted (i.e. "/rooted/path" returns 0 and
 * "c:/windows/rooted/path" returns 2).  If the path is not rooted, this
 * returns -1.
 */
public func git_fs_path_root(_ path: String) -> PathRoot {
    var offset: Int = 0
    
    /* Does the root of the path look like a windows drive ? */
    if let prefix_len = dos_drive_prefix_length(path: path) {
        offset += prefix_len;
    }
    
#if os(Windows)
    TODO; all.this.shit
//    /* Are we dealing with a windows network path? */
//    else if ((path[0] == '/' && path[1] == '/' && path[2] != '/') ||
//        (path[0] == '\\' && path[1] == '\\' && path[2] != '\\'))
//    {
//        offset += 2;
//
//        /* Skip the computer name segment */
//        while (path[offset] && path[offset] != '/' && path[offset] != '\\')
//            offset++;
//    }
//
//    if (path[offset] == '\\')
//        return offset;
#endif

    if "/" == path[path.index(path.startIndex, offsetBy: offset)] {
        return .rooted(offset: offset)
    }
    else {
        return .notRooted
    }
}


private func dos_drive_prefix_length(path: String) -> Int?
{
    guard let firstCharacter = path.first else {
        // libgit2 doesn't do this 🙃
        return nil
    }
    
    /*
     * Does it start with an ASCII letter (i.e. highest bit not set),
     * followed by a colon?
     */
    guard firstCharacter.isASCII else {
        if path.count >= 2,
           ":" == path.dropFirst().first
        {
            return 2
        }
        else {
            return nil
        }
    }
    
    // The above code translates this original C code:
    //
    // if (!(0x80 & (unsigned char)*path))
    //     return *path && path[1] == ':' ? 2 : 0;
    
    
    /*
     * While drive letters must be letters of the English alphabet, it is
     * possible to assign virtually _any_ Unicode character via `subst` as
     * a drive letter to "virtual drives". Even `1`, or `ä`. Or fun stuff
     * like this:
     *
     *    subst ֍: %USERPROFILE%\Desktop
     */
    if let (secondIndex, second) = path.enumerated().dropFirst().first {
        return ":" == second ? .init(secondIndex) : nil
    }
    else {
        return 0
    }
    
    // The above code translates this original C code:
    //
    // for (i = 1; i < 4 && (0x80 & (unsigned char)path[i]); i++)
    // ; /* skip first UTF-8 character */
    // return path[i] == ':' ? i + 1 : 0;
}



private extension Sequence {
    @inline(__always)
    var first: Element? {
        self.first(where: { _ in true })
    }
}



private extension ssize_t {
    init?(_ pathRoot: PathRoot) {
        switch pathRoot {
        case .rooted(let offset):
            self = .init(offset)
            
        case .notRooted:
            return nil
        }
    }
}


/** Flags to determine path validity in `git_fs_path_isvalid` */
public struct FilesystemPathRejectionFlags: AnyStructProtocol, OptionSet {
    /// The underlying bitfield.
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    
    // MARK: Individual flag bindings
    public static let emptyComponent = Self(rawValue: 1 << 0)
    public static let traversal     = Self(rawValue: 1 << 1)
    public static let slash         = Self(rawValue: 1 << 2)
    public static let backslash     = Self(rawValue: 1 << 3)
    public static let trailingDot   = Self(rawValue: 1 << 4)
    public static let trailingSpace = Self(rawValue: 1 << 5)
    public static let trailingColon = Self(rawValue: 1 << 6)
    public static let dosPaths      = Self(rawValue: 1 << 7)
    public static let ntChars       = Self(rawValue: 1 << 8)
    public static let longPaths     = Self(rawValue: 1 << 9)
    
    public static let max: Self = .longPaths
}



// MARK: - Migration

@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.emptyComponent")
public var GIT_FS_PATH_REJECT_EMPTY_COMPONENT: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.traversal")
public var GIT_FS_PATH_REJECT_TRAVERSAL: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.slash")
public var GIT_FS_PATH_REJECT_SLASH: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.backslash")
public var GIT_FS_PATH_REJECT_BACKSLASH: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.trailingDot")
public var GIT_FS_PATH_REJECT_TRAILING_DOT: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.trailingSpace")
public var GIT_FS_PATH_REJECT_TRAILING_SPACE: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.trailingColon")
public var GIT_FS_PATH_REJECT_TRAILING_COLON: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.dosPaths")
public var GIT_FS_PATH_REJECT_DOS_PATHS: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.ntChars")
public var GIT_FS_PATH_REJECT_NT_CHARS: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.longPaths")
public var GIT_FS_PATH_REJECT_LONG_PATHS: Int { fatalError() }

@available(*, unavailable, renamed: "FilesystemPathRejectionFlags.max")
public var GIT_FS_PATH_REJECT_MAX: Int { fatalError() }
