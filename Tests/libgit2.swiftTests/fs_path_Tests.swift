//
//  fs_path_Tests.swift
//  libgit2.swift
//
//  Created by Ky on 2025-12-05.
//

import Testing
import Git

struct fs_path_Tests {

    @Test func test_git_fs_path_equal_or_prefixed() async throws {
        struct Test {
            let parent: String
            let child:  String
            let expected: FSPathCompareResult
        }

        let tests: [Test] = [
            Test(parent: "/foo",  child: "/foo",      expected: .equal(prefixLength: 4)),
            Test(parent: "/foo",  child: "/foo/bar",  expected: .prefix(prefixLength: 3)),
            Test(parent: "/foo/", child: "/foo/bar",  expected: .prefix(prefixLength: 3)),
            Test(parent: "/foo",  child: "/foobar",   expected: .notEqual),
            Test(parent: "",      child: "/foo",      expected: .prefix(prefixLength: 0)),
            Test(parent: "",      child: "foo",       expected: .notEqual),
        ]

        for t in tests {
            let result = git_fs_path_equal_or_prefixed(parent: t.parent, child: t.child)
            assert(result == t.expected, "Failed \(t.parent) vs \(t.child): \(result) ≠ \(t.expected)")
        }
        print("All tests passed.")
    }

}
