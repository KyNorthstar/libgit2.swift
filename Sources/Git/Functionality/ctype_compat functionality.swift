//
// ctype_compat functionality.swift
//
// Written by Ky on 2025-01-04.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



#if os(Windows)

func git__tolower(_ c: int) -> int
{
    return (c >= "A" && c <= "Z") ? (c + 32) : c;
}

func git__toupper(_ c: int) -> int
{
    return (c >= "a" && c <= "z") ? (c - 32) : c;
}

func git__isalpha(_ c: int) -> bool
{
    return ((c >= "A" && c <= "Z") || (c >= "a" && c <= "z"));
}

func git__isdigit(_ c: int) -> bool
{
    return (c >= "0" && c <= "9");
}

func git__isalnum(_ c: int) -> bool
{
    return git__isalpha(c) || git__isdigit(c);
}

func git__isspace(_ c: int) -> bool
{
    return (c == " " || c == "\t" || c == "\n" || c == "\u{12}" || c == "\r" || c == "\u{11}");
}

func git__isxdigit(_ c: int) -> bool
{
    return ((c >= "0" && c <= "9") || (c >= "a" && c <= "f") || (c >= "A" && c <= "F"));
}

func git__isprint(_ c: int) -> bool
{
    return (c >= " " && c <= "~");
}

#else
@available(*, deprecated, renamed: "Character.lowercased()", message: "Use Swift's builtin text processing")
@inline(__always) public func git__tolower(_ a: Character) -> String { a.lowercased() }

@available(*, deprecated, renamed: "Character.uppercased()", message: "Use Swift's builtin text processing")
@inline(__always) public func git__toupper(_ a: Character) -> String { a.uppercased() }


@available(*, deprecated, renamed: "Character.isLetter", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isalpha(_ a: Character) -> Bool { a.isLetter }

@available(*, deprecated, renamed: "CharacterSet.decimalDigits.contains", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isdigit(_ a: Character) -> Bool { CharacterSet.decimalDigits.contains(a) }

@available(*, deprecated, renamed: "CharacterSet.alphanumerics.contains", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isalnum(_ a: Character) -> Bool { CharacterSet.alphanumerics.contains(a) }

@available(*, deprecated, renamed: "CharacterSet.whitespacesAndNewlines.contains", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isspace(_ a: Character) -> Bool { CharacterSet.whitespacesAndNewlines.contains(a) }

@available(*, deprecated, renamed: "Character.isHexDigit", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isxdigit(_ a: Character) -> Bool { a.isHexDigit }

@available(*, deprecated, renamed: "CharacterSet.controlCharacters.inverted.contains", message: "Use Swift's builtin text processing")
@inline(__always) public func git__isprint(_ a: Character) -> Bool { !CharacterSet.controlCharacters.contains(a) }
#endif
