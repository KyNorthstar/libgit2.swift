//
// fs_path functionality.swift
//
// Written by Ky on 2025-07-09.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



#if os(Windows)
import StringIntegerAccess



public func git_fs_path_is_absolute(path: String) -> Bool {
    // [A-Za-z]:[\\/]
    (git__isalpha((p)[0]) && (p)[1] == ":" && ((p)[2] == "\\" || (p)[2] == "/"))
}


public func git_fs_path_is_dirsep(path: String) -> Bool {
    path == "/" || path == "\\"
}


/**
 * Convert backslashes in path to forward slashes.
 */
public func git_fs_path_mkposix(path: inout String)
{
    path = path.replacingOccurrences(of: "\\", with: "/")
}


#else // #if os(Windows)


public func git_fs_path_mkposix(path _: inout String) {/* blank */}


public func git_fs_path_is_absolute(path: String) -> Bool {
    path.first == "/"
}


public func git_fs_path_is_dirsep(path: String) -> Bool {
    path == "/"
}
#endif // #if os(Windows)




/**
 * Get a directory from a path.
 *
 * If path is a directory, this acts like ``git_fs_path_prettify_dir``
 * (cleaning up path and appending a "/").  If path is a normal file,
 * this prettifies it, then removed the filename a la `dirname` and
 * appends the trailing "/".  If the path does not exist, it is
 * treated like a regular filename.
 */
func git_fs_path_find_dir(dir: String) throws(GitError) -> String {
    var buf: String
    
    @ Ky of the Future™: Probably just replace all this with `URL(fileURLWithPath:).deletingLastPathComponent().path`.
    
    if (p_realpath(dir.ptr, buf) != nil)
        error = git_str_sets(dir, buf);

    /* call dirname if this is not a directory */
    if (!error) /* && git_fs_path_isdir(dir->ptr) == false) */
        error = (git_fs_path_dirname_r(dir, dir->ptr) < 0) ? -1 : 0;

    if (!error)
        error = git_fs_path_to_dir(dir);

    return error;
}
