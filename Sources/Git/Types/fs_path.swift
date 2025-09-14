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


/**
 * Prepend base to unrooted path or just copy path over.
 *
 * This will optionally return the index into the path where the "root"
 * is, either the end of the base directory prefix or the path root.
 */
public func git_fs_path_join_unrooted(
    path: String,
    base: String)
throws(GitError) -> (path: String, root_at: ssize_t)
{
    var path_out = String()
    var root: ssize_t
    
    try assert(expr: path_out)
    try assert(expr: path)
    
    root = ssize_t(git_fs_path_root(path)) ?? -1

    if (base != NULL && root < 0) {
        if (git_str_joinpath(path_out, base, path) < 0)
            return -1;

        root = (ssize_t)strlen(base);
    } else {
        if (git_str_sets(path_out, path) < 0)
            return -1;

        if (root < 0)
            root = 0;
        else if (base)
            git_fs_path_equal_or_prefixed(base, path, &root);
    }
    
    return (path: path_out, root_at: root)
}



public enum PathRoot: AnyEnumProtocol {
    
    /// The path has a root
    /// - Parameter offset: The offset of the root in the path
    case rooted(offset: RawValue)
    
    /// The path has no root
    case notRooted
}



extension PathRoot: RawRepresentable {
    
    public init(rawValue: RawValue) {
        self = switch rawValue {
        case 0...: .rooted(offset: rawValue)
        default:   .notRooted
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
    var offset: CInt = 0
    
    /* Does the root of the path look like a windows drive ? */
    if let prefix_len = dos_drive_prefix_length(path: path) {
        offset += prefix_len;
    }
    
#if GIT_WIN32
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

    if "/" == path[path.index(path.startIndex, offsetBy: Int(offset))] {
        return .rooted(offset: offset)
    }
    else {
        return .notRooted
    }
}


private func dos_drive_prefix_length(path: String) -> CInt?
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
struct FilesystemPathReject: OptionSet {
    /// The underlying bitfield.
    let rawValue: Int

    // MARK: Individual flag bindings
    static let emptyComponent = PathReject(rawValue: 1 << 0)
    static let traversal     = PathReject(rawValue: 1 << 1)
    static let slash         = PathReject(rawValue: 1 << 2)
    static let backslash     = PathReject(rawValue: 1 << 3)
    static let trailingDot   = PathReject(rawValue: 1 << 4)
    static let trailingSpace = PathReject(rawValue: 1 << 5)
    static let trailingColon = PathReject(rawValue: 1 << 6)
    static let dosPaths      = PathReject(rawValue: 1 << 7)
    static let ntChars       = PathReject(rawValue: 1 << 8)
    static let longPaths     = PathReject(rawValue: 1 << 9)

    static let max: PathReject = .longPaths
}



// MARK: - Migration

@available(*, unavailable, renamed: "FilesystemPathReject.emptyComponent")
public var GIT_FS_PATH_REJECT_EMPTY_COMPONENT: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.traversal")
public var GIT_FS_PATH_REJECT_TRAVERSAL: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.slash")
public var GIT_FS_PATH_REJECT_SLASH: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.backslash")
public var GIT_FS_PATH_REJECT_BACKSLASH: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.trailingDot")
public var GIT_FS_PATH_REJECT_TRAILING_DOT: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.trailingSpace")
public var GIT_FS_PATH_REJECT_TRAILING_SPACE: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.trailingColon")
public var GIT_FS_PATH_REJECT_TRAILING_COLON: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.dosPaths")
public var GIT_FS_PATH_REJECT_DOS_PATHS: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.ntChars")
public var GIT_FS_PATH_REJECT_NT_CHARS: Int { fatalError() }
@available(*, unavailable, renamed: "FilesystemPathReject.longPaths")
public var GIT_FS_PATH_REJECT_LONG_PATHS: Int { fatalError() }

@available(*, unavailable, renamed: "FilesystemPathReject.max")
public var GIT_FS_PATH_REJECT_MAX: Int { fatalError() }
