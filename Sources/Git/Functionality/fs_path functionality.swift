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



/**
 * The dirname() function shall take a pointer to a character string
 * that contains a pathname, and return a pointer to a string that is a
 * pathname of the parent directory of that file. Trailing '/' characters
 * in the path are not counted as part of the path.
 *
 * If path does not contain a '/', then dirname() shall return a pointer to
 * the string ".". If path is a null pointer or points to an empty string,
 * dirname() shall return a pointer to the string "." .
 *
 * The `git_fs_path_dirname` implementation is thread safe. The returned
 * string must be manually free'd.
 *
 * The `git_fs_path_dirname_r` implementation writes the dirname to a `git_str`
 * if the buffer pointer is not NULL.
 * It returns an error code < 0 if there is an allocation error, otherwise
 * the length of the dirname (which will be > 0).
 */
func git_fs_path_dirname(path: String) -> String? {
    try? git_fs_path_dirname_r(path: path)
}


/**
 * The dirname() function shall take a pointer to a character string
 * that contains a pathname, and return a pointer to a string that is a
 * pathname of the parent directory of that file. Trailing '/' characters
 * in the path are not counted as part of the path.
 *
 * If path does not contain a '/', then dirname() shall return a pointer to
 * the string ".". If path is a null pointer or points to an empty string,
 * dirname() shall return a pointer to the string "." .
 *
 * The `git_fs_path_dirname` implementation is thread safe. The returned
 * string must be manually free'd.
 *
 * The `git_fs_path_dirname_r` implementation writes the dirname to a `git_str`
 * if the buffer pointer is not NULL.
 * It returns an error code < 0 if there is an allocation error, otherwise
 * the length of the dirname (which will be > 0).
 */
func git_fs_path_dirname_r(path: String?) throws(GitError) -> String? {
    var path = path
//    var endp: String.Index
    var is_prefix = false
    
    
    func Exit() throws(GitError) -> String? {
        if var path {
            do { try git_str_sets(buffer: &path, source: path) }
            catch let error where nil != error.code { throw .generic }
            catch {}
            
            if is_prefix {
                path += "/"
            }
        }
        
        return path
    }
    
    
    /* Empty or NULL string gets treated as "." */
    guard var path, !path.isEmpty else {
        path = "."
        return try Exit()
    }
    
    // Strip trailing slashes
    var pathMinusTrailingSlashes = path
    while pathMinusTrailingSlashes.last == "/",
          pathMinusTrailingSlashes.count > 1
    {
        pathMinusTrailingSlashes.removeLast()
    }

    // Find the last slash, ignoring trailing slashes
    if let lastSlash = pathMinusTrailingSlashes.lastIndex(of: "/"),
       !pathMinusTrailingSlashes.isEmpty
    {
        // Handle root ("/")
        if lastSlash == pathMinusTrailingSlashes.startIndex {
            pathMinusTrailingSlashes = String(pathMinusTrailingSlashes.prefix(1))
        }
        else {
            pathMinusTrailingSlashes = String(pathMinusTrailingSlashes.prefix(upTo: lastSlash))
        }
    }
    else {
        // No slashes left, so dirname is "."
        pathMinusTrailingSlashes = "."
    }
    path = pathMinusTrailingSlashes
    
    return try Exit()
    
    // The above code translates this original C code:
    //
    //     const char *endp;
    //     int is_prefix = 0, len;
    //
    //     /* Empty or NULL string gets treated as "." */
    //     if (path == NULL || *path == '\0') {
    //         path = ".";
    //         len = 1;
    //         goto Exit;
    //     }
    //
    //     /* Strip trailing slashes */
    //     endp = path + strlen(path) - 1;
    //     while (endp > path && *endp == '/')
    //         endp--;
    //
    //     if (endp - path + 1 > INT_MAX) {
    //         git_error_set(GIT_ERROR_INVALID, "path too long");
    //         return -1;
    //     }
    //
    //     if ((len = win32_prefix_length(path, (int)(endp - path + 1))) > 0) {
    //         is_prefix = 1;
    //         goto Exit;
    //     }
    //
    //     /* Find the start of the dir */
    //     while (endp > path && *endp != '/')
    //         endp--;
    //
    //     /* Either the dir is "/" or there are no slashes */
    //     if (endp == path) {
    //         path = (*endp == '/') ? "/" : ".";
    //         len = 1;
    //         goto Exit;
    //     }
    //
    //     do {
    //         endp--;
    //     } while (endp > path && *endp == '/');
    //
    //     if (endp - path + 1 > INT_MAX) {
    //         git_error_set(GIT_ERROR_INVALID, "path too long");
    //         return -1;
    //     }
    //
    //     if ((len = win32_prefix_length(path, (int)(endp - path + 1))) > 0) {
    //         is_prefix = 1;
    //         goto Exit;
    //     }
    //
    //     /* Cast is safe because max path < max int */
    //     len = (int)(endp - path + 1);
    //
    // Exit:
    //     if (buffer) {
    //         if (git_str_set(buffer, path, len) < 0)
    //             return -1;
    //         if (is_prefix && git_str_putc(buffer, '/') < 0)
    //             return -1;
    //     }
    //
    //     return len;
}



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
func git_fs_path_find_dir(dir: String) -> String { // TODO: This and `p_realpath` are Our first attempt to completely rewrite one of these low-level C functions with high-level Swift implementations. This should be tested thoroughly to guarantee parity!
    var dir = dir
    if let buf = p_realpath(pathname: dir) {
        dir = buf
    }
    var _isDirectory: ObjCBool
    _ = FileManager.default.fileExists(atPath: dir, isDirectory: &_isDirectory)
    
    if _isDirectory.boolValue {
        return dir.hasSuffix("/") ? dir : (dir + "/")
    }
    else {
        return URL(filePath: dir).deletingLastPathComponent().path
    }
}

