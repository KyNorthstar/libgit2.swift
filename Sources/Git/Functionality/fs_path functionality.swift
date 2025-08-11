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



#if GIT_WIN32
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


#else // #if GIT_WIN32


public func git_fs_path_mkposix(path _: inout String) {/* blank */}


public func git_fs_path_is_absolute(path: String) -> Bool {
    path.first == "/"
}


public func git_fs_path_is_dirsep(path: String) -> Bool {
    path == "/"
}
#endif // #if GIT_WIN32
