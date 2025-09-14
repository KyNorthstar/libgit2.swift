// ---------------------------------------------------------------------------
//  util functionality.swift
//  (subset of libgit2 Swift bindings)
//
//  The following helper implements a binary‑search that is an exact Swift
//  analogue of the C implementation `git__bsearch`.  The behaviour, return
//  values, and side‑effects are intentionally preserved so that existing
//  callers can use it interchangeably with the original C routine.
//
//  NOTE: `GIT_ENOTFOUND` is defined elsewhere in the project (typically
//        as a non‑zero integer).  Ensure that it is visible in this file.
// ---------------------------------------------------------------------------

import Foundation

/// Performs a binary search over *array* for the element pointed to by *key*.\
///
/// - Parameters:
///   - key:   The element to locate.
///   - array: An array of elements that must be sorted according to the
///            comparison function.
///   - compare: A comparison function that behaves like the C `int (*)(const
///            void*, const void*)` – it returns <0 if the first argument is
///            “less than” the second, 0 if they are equal, and >0 otherwise.
///   - position: If non‑nil, this parameter receives the index of the found
///            element (or the index where the search ended in the case of
///            failure).  The value is updated in place.
/// - Returns: `0` if *key* was found; otherwise `GIT_ENOTFOUND` (see C
///            source “git__bsearch”).  The original C function never
///            returns a pointer, only a status code and an optional position.
///
func binarySearch<T>(
    for key: T,
    in array: [T],
    compare: (T, T) -> Int,
    position: inout Int?
) -> Int {

    var lim = array.count
    var cmp = -1
    var baseIndex = 0

    // The loop reproduces the original “for‑loop” in C: at each step the
    // search interval is halved, then we decide whether to look in the
    // left or right half, and adjust *baseIndex* accordingly.
    while lim != 0 {
        // Compute the middle element of the current interval
        let partIndex = baseIndex + (lim >> 1)

        // Call the supplied comparison function
        cmp = compare(key, array[partIndex])

        // If we hit an exact match, remember it and break early
        if cmp == 0 {
            baseIndex = partIndex
            break
        }

        // If key > array[partIndex], we must search the right half.
        // The original C code also decrements the interval counter by one
        // before the next shift‑right, thereby excluding the pivot element.
        if cmp > 0 {
            baseIndex = partIndex + 1
            lim -= 1
        }
        // If key < array[partIndex] we simply keep the current `baseIndex`
        // and shrink the interval; nothing to do explicitly.

        lim >>= 1
    }

    // On exit `baseIndex` points to the first element NOT less than the key.
    // The original C implementation stores this into `position` so callers can
    // retrieve it later.  We do the same, but only if the caller actually
    // provided a storage location.
    if position != nil {
        position = baseIndex
    }

    // Return status similar to the C implementation:
    // 0 → found, non‑zero (GIT_ENOTFOUND) → not found.
    return (cmp == 0) ? 0 : GIT_ENOTFOUND
}
