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
    case rooted(offset: CInt)
    case notRooted
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

    if (path[path.index(path.startIndex, offsetBy: Int(offset))] == "/"){
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
