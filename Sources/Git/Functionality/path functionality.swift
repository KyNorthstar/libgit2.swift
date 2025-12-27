//
// path functionality.swift
//
// Written by Ky on 2025-09-11.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public func git_path_str_is_valid(repo: Repository, path: String, file_mode: UInt16, flags: FilesystemPathRejectionFlags) -> Bool {
    var flags = flags
    
    /* Upgrade the ".git" checks based on platform */
    if flags.contains(.dotGit) {
        flags = dotgit_flags(repo: repo, flags: flags)
    }

    /* Update the length checks based on platform */
    if flags.contains(GIT_FS_PATH_REJECT_LONG_PATHS) {
        flags = length_flags(repo, flags);
    }

    let data: repository_path_validate_data = .init(repo: repo, file_mode: file_mode, flags: flags)

    return git_fs_path_str_is_valid_ext(path, flags, NULL, validate_repo_component, NULL, &data);
}



@inlinable
public func git_path_validate_str_length(repo: Repository, path: String) throws(GitError) {
    guard git_path_str_is_valid(repo, path, 0, GIT_FS_PATH_REJECT_LONG_PATHS) else {
        throw GitError(message: "path too long: \(path)", kind: .filesystem, code: .generic)
    }
}



// MARK: - Private

private struct repository_path_validate_data {
    let repo: Repository?
    let file_mode: UInt16
    let flags: FilesystemPathRejectionFlags
}



@inline(__always)
private func dotgit_flags(
repo: Repository,
flags: FilesystemPathRejectionFlags)
-> FilesystemPathRejectionFlags
{
    var flags = flags
    var protectHFS = false
    var protectNTFS = true
    
    flags.insert(.dotGitLiteral)

#if canImport(Darwin)
    protectHFS = true
#endif

    if nil != repo, !protectHFS {
        try git_repository__configmap_lookup(&protectHFS, repo, GIT_CONFIGMAP_PROTECTHFS);
    }
    if (!error && protectHFS)
        flags |= GIT_PATH_REJECT_DOT_GIT_HFS;

    if (repo)
        error = git_repository__configmap_lookup(&protectNTFS, repo, GIT_CONFIGMAP_PROTECTNTFS);
    if (!error && protectNTFS)
        flags |= GIT_PATH_REJECT_DOT_GIT_NTFS;

    return flags;
}



@inline(__always)
private func length_flags(
    repo: Repository,
    flags: FilesystemPathRejectionFlags)
-> CUnsignedInt
{
    var flags = flags
#if os(Windows)
    var allow: Bool = false

    if (repo &&
        git_repository__configmap_lookup(&allow, repo, GIT_CONFIGMAP_LONGPATHS) < 0) {
        allow = false
    }

    if (allow) {
        flags &= ~GIT_FS_PATH_REJECT_LONG_PATHS;
    }

#else
    flags &= ~GIT_FS_PATH_REJECT_LONG_PATHS;
    flags.insert(~.longPaths)
#endif

    return flags;
}
