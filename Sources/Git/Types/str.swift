//
// str.swift
//
// Written by Ky on 2024-11-09.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//


@available(*, unavailable, renamed: "String", message: "Just use String lol")
public typealias git_str = String



@available(*, unavailable, renamed: "StringMap")
public typealias git_strmap = StringMap

public typealias StringMap = [String : any (AnyTypeProtocol & Sendable)]
