//
// util functionality.swift
//
// Written by Ky on 2024-12-18.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation

//import OptionalTools
import SafePointer



public func _getEnv(name: String) throws(GitError) -> String {
#if os(Windows)
    var wide_name: String? = nil
    var wide_value: String? = nil
    let value_len: DWORD
    
    git_str_clear(out);
    
    try git_utf8_to_16_alloc(&wide_name, name)
    
    if ((value_len = GetEnvironmentVariableW(wide_name, NULL, 0)) > 0) {
        wide_value = git__malloc(value_len * sizeof(wchar_t));
        GIT_ERROR_CHECK_ALLOC(wide_value);
        
        value_len = GetEnvironmentVariableW(wide_name, wide_value, value_len);
    }
    
    if (value_len) {
        error = git_str_put_w(out, wide_value, value_len);
    }
    else if (GetLastError() == ERROR_SUCCESS || GetLastError() == ERROR_ENVVAR_NOT_FOUND) {
        error = GIT_ENOTFOUND;
    }
    else {
        git_error_set(GIT_ERROR_OS, "could not read environment variable '%s'", name);
    }
    
    git__free(wide_name);
    git__free(wide_value);
    return error;
#else
    guard let val = getenv(name) else {
        throw GitError(code: .objectNotFound)
    }
    
    return String(platformString: val)
    
    // The above code translates this original C code:
    //
    // const char *val = getenv(name);
    //
    // git_str_clear(out);
    //
    // if (!val)
    //     return GIT_ENOTFOUND;
    //
    // return git_str_puts(out, val);
#endif
}



public typealias Comparator<Element> = (_ a: Element, _ b: Element) -> ComparisonResult



public func git__tsort<Element>(dst: inout [Element], comparator: Comparator<Element>) {
    git__tsort_r(dst: &dst, comparator: comparator)
}






public func git__tsort_r<Element>(dst: inout [Element], comparator: Comparator<Element>) {
    TODO
}




public extension Bool {
    /// Parse a string value as a boolean, just like libgit does, just like Core Git does.
    ///
    /// Valid values for true are: `"true"`, `"yes"`, `"on"`, and `nil`
    /// Valid values for false are: `"false"`, `"no"`, `"off"`, and any string beginning with NUL (U+0000)
    ///
    /// Parsing `nil` and NUL-starting strings this way are undocumented features of libgit2 1.8.4
    static func parse(gitBoolString value: String?) throws(GitError) -> Bool {
        /* A missing value means true */   // WHY THO?!?!?! – Ky, 2025-01-06
        if (value == nil ||
            0 == strcasecmp(value, "true") ||
            0 == strcasecmp(value, "yes") ||
            0 == strcasecmp(value, "on")) {
            return true
        }
        if let value,
           (0 == strcasecmp(value, "false") ||
            0 == strcasecmp(value, "no") ||
            0 == strcasecmp(value, "off") ||
            "\u{0}" == value.first) {
            return false
        }
        
        throw .init(code: .__generic)
    }
}



public extension FixedWidthInteger {
    
    /// Parses the given string to this integer type, in the style of libgit2.
    ///
    /// libgit2 allows explicitly specifying a base, and also allows implying a base by setting that to `0`.
    /// If it cannot process the given string into an integer for any reason, then it throws an error.
    /// If the given base is `0`, then it attempts to parse the string based on how it starts:
    /// - `0x` and `0X` parse as hexadecimal (e.g. `"0xC0FFEE"` is parsed as 12,648,430)
    /// - A non-zero starting number parses as decimal (e.g. `"420"` is parsed as 420)
    /// - All other strings starting with `0` are parsed as octal (e.g. `01234` is parsed as 668)
    /// - If `base` is greater than 32, an error is thrown
    ///
    /// The libgit2 function also automatically ignores preceding whitespace, and returns the pointer to the character where it stopped parsing.
    ///
    /// This function mimics that behavior, and also includes the following:
    /// - Allows the base to be `nil`, which means the same as `0`
    /// - If the base is `1`, this considers that the same as `0` (because unary is, practically speaking, never used)
    /// - Strings starting with `0o` parse as octal
    /// - Strings starting with `0b` parse as binary (e.g. `"0b01000101"` is parsed as 69)
    /// - The same code works for all integer types, not just 64- and 32-bit signed binary integers
    /// - Automatically ignores both preceding & trailing whitespace
    ///
    /// This function also opts to not return the location where it stopped parsing. If you need that functionality, please file an issue at
    /// https://github.com/KyNorthstar/libgit2.swift/issues/new/choose
    ///
    ///
    /// - Parameters:
    ///   - gitNumberString: The string to parse into a number
    ///   - base:            The base (radix) of the number.
    ///                      Must be `nil` or in `0...32`.
    ///                      If `nil`, `0`, or `1`, then this attempts to detect the base automatically.
    ///
    /// - Throws:
    ///   - A `GitError` if the given number string couldn't be parsed into a number
    // TODO: Test rigorously
    static func parse(gitNumberString: String, base: UInt8?)
    -> ParseResult {
        @inline(__always) let untrimmedNumberString = gitNumberString
        let trimmedNumberString = untrimmedNumberString.trimmingPrefixAndSuffix(while: CharacterSet.whitespacesAndNewlines.contains)
        
        guard !trimmedNumberString.isEmpty else {
            return ParseResult(parsed: .failure(.couldNotParseStringToInteger()),
                               parseRange: untrimmedNumberString.indexClosedRange)
        }
        
        
        @inline(__always)
        func match<Output>(_ regex: Regex<Output>) -> Output? {
            // According to the documentation,
            // > The `firstMatch(in:)` method can throw an error if this regex includes a transformation closure that throws an error.
            // Since this regex doesn't, it won't. We can safely ignore this error if the Regex API honors its contract
            
            do {
                return try regex.firstMatch(in: trimmedNumberString)?.output
            }
            catch {
                print("Regex API violated its contract", error)
                return nil
            }
        }
        
        
        @inline(__always)
        func parse(base: Int, sign: Substring?, digits: Substring) -> ParseResult {
            let range = (sign?.startIndex ?? digits.startIndex) ... digits.index(before: digits.endIndex)
            
            if let number = Self.init((sign ?? "") + digits, radix: base) {
                return ParseResult(parsed: .success(number), parseRange: range)
            }
            else {
                return ParseResult(parsed: .failure(.couldNotParseStringToInteger()), parseRange: range)
            }
        }
        
        
        @inline(__always)
        let validCharacters = CharacterSet(charactersIn: "+-").union(.alphanumerics)
        
        @inline(__always)
        let lastAlphanumericIndex = untrimmedNumberString.lastIndex(where: validCharacters.contains)
            ?? untrimmedNumberString.startIndex
        
        let (_, sign, baseIndicator, digits): (Substring, Substring?, Substring?, Substring)
        
        guard let m = match(/(?<sign>[+-])?(?<baseIndicator>0[Xbox]?)?(?<digits>[A-Za-z0-9]+)/) else {
            
            return ParseResult(parsed: .failure(.couldNotParseStringToInteger()),
                               parseRange: trimmedNumberString.startIndex ... lastAlphanumericIndex)
        }
        
        (_, sign, baseIndicator, digits) = m
        
        if let base,
           0 != base {
            guard base < 32 else {
                return ParseResult(parsed: .failure(.couldNotParseStringToInteger()),
                                   parseRange: trimmedNumberString.startIndex ... lastAlphanumericIndex)
            }
            
            return parse(base: .init(base), sign: sign, digits: digits)
        }
        else {
            switch baseIndicator {
            case nil:
                return parse(base: 10, sign: sign, digits: digits)
                
            case "0X", "0x":
                return parse(base: 0x10, sign: sign, digits: digits)
                
            case "0b":
                return parse(base: 0b10, sign: sign, digits: digits)
                
            case "0", "0o":
                fallthrough
                
            default:
                return parse(base: 0o10, sign: sign, digits: digits)
            }
        }
    }
    
    
    
    typealias ParseResult = (parsed: Result<Self, GitError>, parseRange: ClosedRange<String.Index>)
}



private extension GitError {
    static func couldNotParseStringToInteger(cause: (any Error)? = nil) -> Self {
        .init(message: "failed to convert string to long \(nil == cause ? ": not a number" : "")",
              kind: .invalid,
              cause: cause)
    }
}



public extension Collection {
    
    /// Performs a binary search of this collection to find the index of the given element, or where it would be in this collection
    /// 
    /// - Parameters:
    ///   - needle:     The value to search for
    ///   - comparator: _optional_ - The function which compares each value in the search. You may exclude this if the collection is filled with `Comparable` elements, but it is required otherwise.
    ///
    /// - Returns: A tuple containing the position where the element is or would be inserted if not found. If not found, `error` is set to `.objectNotFound`.
    func binarySearch(for needle: Element, comparator: AnyTypeComparator<Element>) -> (position: Index, error: GitError?) {
        guard !isEmpty else {
            return (startIndex, .objectNotFound)
        }
        
        var low = startIndex
        var high = endIndex
        
        while low < high {
            let mid = index(low, offsetBy: distance(from: low, to: high) / 2)
            let midVal = self[mid]
            
            switch comparator(midVal, needle) {
            case .orderedAscending: // midVal < needle
                // Search right half; increase low just above mid
                low = index(after: mid)
                
            case .orderedDescending: // midVal > needle
                // Search left half; reduce high down to mid
                high = mid
                
            case .orderedSame: // midVal == needle
                // Found the value
                return (mid, nil)
            }
        }
        
        // `while` loop only exits when low == high and the value wasn't found, so this is the insertion point
        return (low, .objectNotFound)
        
        // The above code translates this original C code:
        //
        // int git__bsearch(
        //     void **array,
        //     size_t array_len,
        //     const void *key,
        //     int (*compare)(const void *, const void *),
        //     size_t *position)
        // {
        //     size_t lim;
        //     int cmp = -1;
        //     void **part, **base = array;
        //
        //     for (lim = array_len; lim != 0; lim >>= 1) {
        //         part = base + (lim >> 1);
        //         cmp = (*compare)(key, *part);
        //         if (cmp == 0) {
        //             base = part;
        //             break;
        //         }
        //         if (cmp > 0) { /* key > p; take right partition */
        //             base = part + 1;
        //             lim--;
        //         } /* else take left partition */
        //     }
        //
        //     if (position)
        //         *position = (base - array);
        //
        //     return (cmp == 0) ? 0 : GIT_ENOTFOUND;
        // }
    }
}



public extension Collection where Element: Comparable & AnyTypeProtocol {
    func binarySearch(for value: Element) -> (position: Index, error: GitError?) {
        binarySearch(for: value) { lhs, rhs in
            if lhs == rhs {
                return .orderedSame
            }
            else if lhs < rhs {
                return .orderedAscending
            }
            else {
                return .orderedDescending
            }
        }
    }
}



// MARK: - tsort.c

/// The result of searching a collection for an item, or the best place to insert an item
private enum SearchResult<Index: Comparable> {
    
    /// The needle was found in the haystack at this index
    case found(at: Index)
    
    /// The needle wasn't found in the haystack, but it'd fit if inserted at this index
    case notFound(insertionPoint: Index)
    
    
    /// The index where the element was found, or where it should be inserted
    @inline(__always)
    var insertionPoint: Index {
        switch self {
        case .found(at: let i),
                .notFound(insertionPoint: let i):
            return i
        }
    }
    
    
    /// `true` iff this represents an element which was actually found in the collection
    @inline(__always)
    var isFound: Bool {
        switch self {
        case .found:    true
        case .notFound: false
        }
    }
}



/// Performs a binary search for the given needle, returning its index if it's found (or `nil` if it isn't)
///
/// - Parameters:
///   - haystack:   The collection to search
///   - needle:     The element to find
///   - comparator: Compares values in the haystack against the needle. This function is called many times in rapid succession, so make sure it's efficient
///
/// - Returns: The index of `x` if it's found (or `nil` if it isn't)
private func binsearch<Element>(
    haystack: [Element],
    needle: Element,
    comparator: Comparator<Element>)
-> SearchResult<[Element].Index> {
    guard !haystack.isEmpty else {
        return .notFound(insertionPoint: 0)
    }
    
    @inline(__always) let lx: Element = haystack[0] // original was `dst[l]` but `l` at this point is always 0
    
    // Check beginning conditions
    let initialComparison = comparator(needle, lx) // original code did this twice lol
    
    if case .orderedAscending = initialComparison {
        return .notFound(insertionPoint: 0)
    }
    else if initialComparison == .orderedSame {
        return .found(at: (1 ..< haystack.endIndex)
            .first(where: { .orderedSame != comparator(needle, haystack[$0]) })
                      ?? haystack.endIndex
        )
    }
    
    var lowerBound: Int = haystack.startIndex
    var upperBound: Int = haystack.endIndex - 1
    var currentIndex: Int = upperBound >> 1 // ?
    
    // Binary search loop
    var currentElement = haystack[currentIndex]
    while true {
        let val = comparator(needle, currentElement)
        
        if case .orderedAscending = val { // The needle is definitely before this index
            guard currentIndex > (lowerBound + 1) else {
                return .notFound(insertionPoint: currentIndex)
            }
            upperBound = currentIndex
        }
        else if case .orderedDescending = val { // The needle is definitely after this index
            guard upperBound > (currentIndex + 1) else {
                return .notFound(insertionPoint: currentIndex + 1)
            }
            lowerBound = currentIndex
        }
        else { // Found!
            // Advance past all equal elements and return the index after that run so the last element can be viewed, or a new identical element will be appended to the run
            repeat {
                currentIndex += 1
            } while currentIndex < haystack.count && comparator(needle, haystack[currentIndex]) == .orderedSame
            
            return .found(at: currentIndex)
        }
        
        currentIndex = lowerBound + ((upperBound - lowerBound) >> 1)
        currentElement = haystack[currentIndex]
    }
    
    /*
    var l: Int = haystack.startIndex
    var r: Int = haystack.endIndex - 1
    var c: Int = r >> 1 // ?
    var lx: Element = haystack[0] // original was `dst[l]` but `l` at this point is always 0
    var cx: Element
    
    /* check for beginning conditions */
    if case .orderedAscending = comparator(needle, lx, payload) {
        return 0
    }
    else if case .orderedSame = comparator(needle, lx, payload) {
        return (1 ..< haystack.endIndex)
            .first { comparator(needle, haystack[$0], payload) == .orderedSame }
    }
    
    /* guaranteed not to be >= rx */
    cx = haystack[c]
    while true {
        let val = comparator(needle, cx, payload)
        if case .orderedAscending = val {
            if (c - l) <= 1 { return c }
            r = c
        }
        else if val > 0 {
            if (r - c) <= 1 { return c + 1 }
            l = c
            lx = cx
        }
        else {
            do {
                cx = haystack[++c]
            } while (comparator(needle, cx, payload) == 0);
            return c;
        }
        c = l + ((r - l) >> 1);
        cx = haystack[c];
    }
     */
}

/* Binary insertion sort, but knowing that the first "start" entries are sorted. Used in timsort. */
private func bisort<Element>(dst: inout [Element], start: Int, size: Int, comparisonCurrier _: git__sort_r_cmp<Element>, comparator: Comparator<Element>) {
    let i: [Element].Index
    let x: Element
    let location: SearchResult<[Element].Index>

    for i in start ..< size {
        /* If this entry is already correct, just move along */
        switch comparator(dst[i - 1], dst[i]) {
        case .orderedDescending,
                .orderedSame:
            continue
            
        case .orderedAscending:
            break
        }
        
        /* Else we need to find the right place, shift everything over, and squeeze in */
        x = dst[i];
        location = binsearch(haystack: dst, needle: x, comparator: comparator)
        //for (j = (int)i - 1; j >= location; j--) {
        for j in stride(from: i - 1, through: location.insertionPoint, by: -1) {
            dst[j + 1] = dst[j];
        }
        dst[location.insertionPoint] = x;
    }
}



/* timsort implementation, based on timsort.txt */
private struct tsort_run {
    var start: UInt
    var length: UInt
}



private struct tsort_store<Element> {
    var alloc: Int
    var cmp: git__sort_r_cmp<Element>
    var payload: Any
    var storage: SafePointer<Any>
}



// Original had `payload` as a `void*`... unsure why
@inline(__always)
private func tsort_r_cmp<Element>(a: Element, b: Element, payload: git__tsort_cmp<Element>) -> ComparisonResult {
    payload(a, b)
}


private func git__tsort_r<Element>(dst: inout [Element], cmp: git__sort_r_cmp<Element>, payload: Any)
{
    var size: Int { dst.count }
    
    let _store: tsort_store<Element>
    let store: tsort_store<Element>
    var run_stack: [tsort_run] = .init()
    run_stack.reserveCapacity(128)
    
    var stack_curr: UInt = 0
    var len: UInt
    var run: UInt
    var curr: UInt = 0
    var minrun: UInt

    if (size < 64) {
        bisort(dst, 1, size, cmp, payload);
        return;
    }

    /* compute the minimum run length */
    minrun = (ssize_t)compute_minrun(size);

    /* temporary storage for merges */
    store->alloc = 0;
    store->storage = NULL;
    store->cmp = cmp;
    store->payload = payload;

    PUSH_NEXT();
    PUSH_NEXT();
    PUSH_NEXT();

    while (1) {
        if (!check_invariant(run_stack, stack_curr)) {
            stack_curr = collapse(dst, run_stack, stack_curr, store, size);
            continue;
        }

        PUSH_NEXT();
    }
}



// MARK: - Migration

@available(*, unavailable, renamed: "array.count", message: "Just use Swift's builtin array.count lol")
public func ARRAY_SIZE(_ array: [any Any]) -> Int { fatalError() }

@available(*, unavailable, renamed: "_getEnv(name:)")
public func git__getenv(_: inout git_str, _: String) -> CInt { fatalError() }


@available(*, unavailable, renamed: "Int64.parse(gitNumberString:base:)")
public func git__strntol64(_: inout __int64_t, _: CharStar, _: size_t, _: inout CharStar, _: CInt) -> CInt { fatalError() }

@available(*, unavailable, renamed: "Int32.parse(gitNumberString:base:)")
public func git__strntol32(_: inout __int32_t, _: CharStar, _: size_t, _: inout CharStar, _: CInt) -> CInt { fatalError() }

@available(*, unavailable, renamed: "Bool.parse(gitNumberString:)")
public func git__parse_bool(_: inout CInt, _: CharStar) -> CInt { fatalError() }

@available(*, unavailable, renamed: "array.binarySearch(for:)", message: "Most of these parameters are unnecessary in Swift; their state is managed within the rewritten function.")
public func git__bsearch(_: [Any], _: size_t, _: Any, _: (_: Any, _: Any) -> CInt, _: inout size_t) { fatalError() }

@available(*, unavailable, renamed: "Comparator")
public typealias git__tsort_cmp<Element> = Comparator<Element>

@available(*, unavailable, message: "This was a C function that takes a comparator, probably because function pointers are opaque in C. In Swift, we don't have that overhead, so we can just use a regular `Comparator` directly instead.")
public typealias git__sort_r_cmp<Element> = (_ a: Element, _ b: Element, _ comparator: Comparator<Element>) -> ComparisonResult


@available(*, unavailable, renamed: "git__tsort(dst:comparator:)", message: "The Swift version of this doesn't need to take a separate array size parameter")
public func git__tsort<Element>(_: inout [Element], _: size_t, _: Comparator<Element>) -> Void { fatalError() }

@available(*, unavailable, renamed: "git__tsort_r(dst:comparator:)", message: "The Swift version of this doesn't need to take a separate array size parameter, nor does it need the extra `git__sort_r_cmp` indirection.")
public func git__tsort_r<Element>(_: inout [Element], _:size_t, _: git__sort_r_cmp<Element>, _: Comparator<Element>) -> Void { fatalError() }
