//
// str functionality.swift
//
// Written by Ky on 2024-12-18.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

/// Git's string out-of-memory mark
public let git_str__oom = "\u{0}"

@available(*, deprecated, renamed: "nil", message: "You should only have to nilify the String and the Swift runtime will take care of the rest.")
@inline(__always)
public func git_str_dispose(string: inout String?) {
    string = nil
}



/// Resizes the given string to the given target size, or throws an error if that can't be done (e.g. low memory).
///
/// - Parameters:
///   - string:     The string to resize
///   - targetSize: The desired size of the new string
/// - Throws: Any error thrown during resizing, if it has no kind but _does_ have a code. If any other error is thrown during resizing, it's ignored. That was the original behavior.
@inline(__always)
private func ENSURE_SIZE(string: inout String, targetSize: Int) throws(GitError) {
    if git_str__oom == string
        || (targetSize > string.count)
    {
        do {
            try string.resize(to: targetSize)
        }
        catch where error.code != nil
                 && error.kind == nil
        {
            throw .init(code: .__generic)
        }
        catch {
            return
        }
    }
    
    // The above code translates this original C code:
    //
    // #define ENSURE_SIZE(b, d) \
    //     if ((b)->ptr == git_str__oom || \
    //         ((d) > (b)->asize && git_str_grow((b), (d)) < 0))\
    //         return -1;
}



public extension String {
    
    /// If the given new string is not `nil`, then this string becomes a copy of it. If it is `nil`, then this function throws an error
    ///
    /// - Parameters:
    ///   - newString:       The string to overwrite this one with
    ///   - expressionLabel: _optional_ - **Encouraged!** Labels the expression in the thrown error. This should be the name of the argument you're using as the new string. Defaults to `#function`.
    ///
    /// - Throws: A ``GitError`` iff `newString` is `nil`
    // Analogous to `git_str_puts`
    mutating func checkedSet(to newString: String?, expressionLabel: String = #function) throws(GitError) {
        self = try .init(checking: newString)
    }
    
    
    /// If the given new string is not `nil`, then this string is initialized as a copy of it. If it is `nil`, then this initializer throws an error
    ///
    /// - Parameters:
    ///   - newString:       The string to initialize this new string as
    ///   - expressionLabel: _optional_ - **Encouraged!** Labels the expression in the thrown error. This should be the name of the argument you're using as the new string. Defaults to `#function`.
    ///
    /// - Throws: A ``GitError`` iff `newString` is `nil`
    // Analogous to `git_str_puts`
    init(checking newString: String?, expressionLabel: String = #function) throws(GitError) {
        self = try assert(expr: newString, expressionLabel: expressionLabel)
    }
    
    
    /// If the given new string is not `nil`, then this string is initialized as a copy of it. If it is `nil`, then this initializer throws an error
    ///
    /// - Parameters:
    ///   - cString:         The C string to initialize this new string as
    ///   - expressionLabel: _optional_ - **Encouraged!** Labels the expression in the thrown error. This should be the name of the argument you're using as the new string. Defaults to `#function`.
    ///
    /// - Returns: `nil` if the given C string is non-nil but can't be converted into a Swift string
    ///
    /// - Throws: A ``GitError`` iff `newString` is `nil`
    // Analogous to `git_str_puts`
    init?(checking cString: [CChar]?, expressionLabel: String = #function) throws(GitError) {
        var cString = try assert(expr: cString, expressionLabel: expressionLabel)
        self.init(validatingCString: &cString)
    }
    
    
    /// If the given new string is not `nil`, then this string is initialized as a copy of it. If it is `nil`, then this initializer throws an error
    ///
    /// - Parameters:
    ///   - cString:         The C string to initialize this new string as
    ///   - expressionLabel: _optional_ - **Encouraged!** Labels the expression in the thrown error. This should be the name of the argument you're using as the new string. Defaults to `#function`.
    ///
    /// - Returns: `nil` if the given C string is non-nil but can't be converted into a Swift string
    ///
    /// - Throws: A ``GitError`` iff `newString` is `nil`
    // Analogous to `git_str_puts`
    init?(checking cString: UnsafeMutablePointer<CChar>?, expressionLabel: String = #function) throws(GitError) {
        self.init(validatingCString: try assert(expr: cString, expressionLabel: expressionLabel))
    }
    
    
    /**
     * Join two strings as paths, inserting a slash between as needed.
     * @return 0 on success, -1 on failure
     */
    @inline(__always)
    // Analogous to `git_str_joinpath`
    init(joiningPath a: String, withPathComponent b: String) { // TODO: Unit tests
        self.init(joining: a, with: b, separator: "/")
        
        // The above code translates this original C code:
        //
        // return git_str_join(str, '/', a, b);
    }
    
    
    /** General join with separator */
    // Analogous to `git_str_join`
    init(joining str_a: String?, with str_b: String, separator: Character?) { // TODO: Unit tests
        if let separator {
            if let str_a {
                self = "\(str_a)\(separator)\(str_b)"
            }
            else {
                self = "\(separator)\(str_b)"
            }
        }
        else {
            if let str_a {
                self = str_a + str_b
            }
            else {
                self = str_b
            }
        }
        
        // The above code translates this original C code:
        //
        // int git_str_join(
        //     git_str *buf,
        //     char separator,
        //     const char *str_a,
        //     const char *str_b)
        // {
        //     size_t strlen_a = str_a ? strlen(str_a) : 0;
        //     size_t strlen_b = strlen(str_b);
        //     size_t alloc_len;
        //     int need_sep = 0;
        //     ssize_t offset_a = -1;
        //
        //     /* not safe to have str_b point internally to the buffer */
        //     if (buf->size)
        //         GIT_ASSERT_ARG(str_b < buf->ptr || str_b >= buf->ptr + buf->size);
        //
        //     /* figure out if we need to insert a separator */
        //     if (separator && strlen_a) {
        //         while (*str_b == separator) { str_b++; strlen_b--; }
        //         if (str_a[strlen_a - 1] != separator)
        //             need_sep = 1;
        //     }
        //
        //     /* str_a could be part of the buffer */
        //     if (buf->size && str_a >= buf->ptr && str_a < buf->ptr + buf->size)
        //         offset_a = str_a - buf->ptr;
        //
        //     GIT_ERROR_CHECK_ALLOC_ADD(&alloc_len, strlen_a, strlen_b);
        //     GIT_ERROR_CHECK_ALLOC_ADD(&alloc_len, alloc_len, need_sep);
        //     GIT_ERROR_CHECK_ALLOC_ADD(&alloc_len, alloc_len, 1);
        //     ENSURE_SIZE(buf, alloc_len);
        //
        //     /* fix up internal pointers */
        //     if (offset_a >= 0)
        //         str_a = buf->ptr + offset_a;
        //
        //     /* do the actual copying */
        //     if (offset_a != 0 && str_a)
        //         memmove(buf->ptr, str_a, strlen_a);
        //     if (need_sep)
        //         buf->ptr[strlen_a] = separator;
        //     memcpy(buf->ptr + strlen_a + need_sep, str_b, strlen_b);
        //
        //     buf->size = strlen_a + strlen_b + need_sep;
        //     buf->ptr[buf->size] = '\0';
        //
        //     return 0;
        // }
    }
    
    
    /// This treats `buffer` as a data buffer and appends `stringToAppend` at the end of it.
    ///
    /// This is different from `buffer.append(stringToAppend)` because it performs additional checks and guarantees that `buffer` can act as a buffer.
    /// For example, this explicitly treats the `buffer`'s capacity separately from its character `count`.
    ///
    /// - Parameters:
    ///   - buffer:         The buffer which will have the given new data appended to its end
    ///   - stringToAppend: The new data to append to the end of the buffer
    // Analogous to `git_buf_put``
    static func bufferAppend(buffer: inout String, stringToAppend: String) {
        guard !stringToAppend.isEmpty else { return }
        buffer.reserveCapacity(buffer.count + stringToAppend.count)
        buffer.append(stringToAppend)
    }
    
    
    /**
     * Resize the string buffer allocation to make more space.
     *
     * This will attempt to grow the string buffer to accommodate the target
     * size.  The bstring buffer's `ptr` will be replaced with a newly
     * allocated block of data.  Be careful so that memory allocated by the
     * caller is not lost.  As a special variant, if you pass `target_size` as
     * 0 and the memory is not allocated by libgit2, this will allocate a new
     * buffer of size `size` and copy the external data into it.
     *
     * Currently, this will never shrink a buffer, only expand it.
     *
     * If the allocation fails, this will return an error and the buffer will be
     * marked as invalid for future operations, invaliding the contents.
     *
     * - Parameter target_size: The desired available size
     * - Throws: on allocation failure
     */
    mutating func resize(to target_size: Int) throws(GitError) {
        try resize(to: target_size)
    }
    
    
    /// Attempt to grow this string's internal buffer to allow it to hold at least `target_size` characters.
    ///  
    /// Note that the string's `.count` will remain the same after this returns; the only change will be guaranteeing that enough free memory exists to contain `target_size` characters.
    /// 
    /// Currently, this will never shrink a buffer, only expand it.
    /// 
    /// - Attention: This is a niche utility. You're encouraged to use `.reserveCapacity` instead. If this function fails to allocate the memory needed to create a string of the given size, this will return an error and the buffer will be marked as invalid for future operations, invaliding its contents entirely.
    /// 
    /// - Parameters:
    ///   - target_size:               The minimum number of characters this string should be able to hold
    ///   - markAsOutOfMemoryIfFailed: _optional_ - When `true`, then if this ever fails to reserve the capacity you request, it sets this string to the Out-Of-Memory string and throws an error.
    ///                                Otherwise, when `false`, this won't change the string but would still throw an error.
    ///                                Defaults to `false`.
    mutating func resize(to target_size: size_t, markAsOutOfMemoryIfFailed: Bool = false) throws(GitError) {
        
        let target_size = target_size.nonZeroOrNil ?? self.count
        
        guard target_size > count else {
            return
        }
        
        guard git_str__oom != self else {
            throw .generic
        }
        
        self.reserveCapacity(target_size)
        
        // The above code translates a bunch of original C code which did a lot of string handling which Swift handles internlly with `.reserveCapacity`. Checking for memory constraints was kept and the rest discarded.
        //
        //
        // Here's checks the original performs and how they're handled above:
        //
        // - If the buffer points to the out-of-memory error string, throw a generic error
        //    - This does that
        //
        // - If the buffer's `asize` and `size` are both `0`, then it assumes the buffer was borrowed and throws GIT_EINVALID
        //    - Since this version mutates the current string, and the Swift `String` type is `Copyable`, that string cannot be borrowed into this function
        //
        // - If the target size is less than or equal to the current size, do nothing
        //    - This does that
        //
        // - Various checks around current vs allocated size
        //    - These are taken care of in Swift's `String` already
        //
        // - Allocating at least X bytes to avoid memory holes
        //    - This is taken care of in Swift's `String` already
        //
        // - If the newly-allocated size is less than the current size, then an out-of-memory error is thrown
        //    - Since Swift doesn't really concern itself with that, this version doesn't either
        //
        // - Checking if reallocation resulted in a null pointer, then throwing an out-of-memory error
        //    - Since Swift doesn't really concern itself with that, this version doesn't either
        //
        //
        // See libgit2/util/str.c:36 `git_str_try_grow`
    }
}



func git_str_sets(buf: inout String, string: String?) throws(GitError) {
    try git_str_set(buffer: &buf, source: string, length: string?.count ?? 0)
}


func git_str_set(buffer buf: inout String, source data: String?, length len: size_t) throws(GitError) {
    var alloclen: size_t
    
    guard let data, len != 0 else {
        buf.removeAll(keepingCapacity: true)
        return
    }
    
    if data != buf {
        (alloclen, _) = len.addingReportingOverflow(1)
        try ENSURE_SIZE(string: &buf, targetSize: alloclen)
        buf = data // memmove(buf, data, len);
    }
    
    return
    
    
    // The above code translates this original C code:
    //
    // int git_str_set(git_str *buf, const void *data, size_t len)
    // {
    //     size_t alloclen;
    //
    //     if (len == 0 || data == NULL) {
    //         git_str_clear(buf);
    //     } else {
    //         if (data != buf->ptr) {
    //             GIT_ERROR_CHECK_ALLOC_ADD(&alloclen, len, 1);
    //             ENSURE_SIZE(buf, alloclen);
    //             memmove(buf->ptr, data, len);
    //         }
    //
    //         buf->size = len;
    //         if (buf->asize > buf->size)
    //             buf->ptr[buf->size] = '\0';
    //
    //     }
    //     return 0;
    // }
}



// MARK: - Migration

@available(*, unavailable, renamed: "String()")
@inline(__always)
public var GIT_STR_INIT: git_str { .init() }

@available(*, unavailable, renamed: "git_str_dispose(string:)", message: "Evaluate whether this is necessary in Swift (original was mostly deallocation)")
public func git_str_dispose(_: inout git_str?) { fatalError() }

@available(*, unavailable, renamed: "String.bufferAppend(buffer:stringToAppend:)")
public func git_str_put(_: inout git_str, _: CharStar, _: size_t) throws(GitError) { fatalError() }

@available(*, unavailable, renamed: "String.init(checking:expressionLabel:)")
public func git_str_puts(_: inout git_str?, _: CharStar?) -> CInt { fatalError() }

@available(*, unavailable, renamed: "String.init(joining:with:separator:)")
public func git_str_join(_: inout git_str?, _: CChar, _: CharStar, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, renamed: "String.init(joiningPath:withPathComponent:)")
public func git_str_joinpath(_: inout git_str?, _: CharStar, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, message: "This is equivalent to `.removeAll(keepingCapacity: true)``")
public func git_str_clear(_: inout git_str?) -> CInt { fatalError() }

@available(*, unavailable, renamed: "String.count", message: "just use .count")
public func git_str_len(_: inout git_str?) -> size_t { fatalError() }


public extension String {
    @available(*, unavailable, message: "This is identical to Swift = assignment if the new string isn't Optional")
    init(checking _: String, expressionLabel _: String = #function) throws(GitError) { fatalError() }
    
    
    @available(*, unavailable, renamed: "git_str_try_grow(target_size:)")
    func git_str_try_grow(target_size: size_t, mark_oom: Bool) { fatalError() }
}


@available(*, unavailable, renamed: "buf.resize(to:)")
public func git_str_try_grow(_ buf: inout git_str, _ target_size: size_t, _ mark_oom: Bool) { fatalError() }

@available(*, unavailable, renamed: "buf.resize(to:)")
public func git_str_grow(_ buf: inout git_str, _: size_t) -> CInt { fatalError() }
