//
//  File.swift
//  libgit2.swift
//
//  Created by Ky on 2025-08-11.
//

import Foundation



/**
 *    core.autocrlf
 *        Setting this variable to "true" is almost the same as setting
 *    the text attribute to "auto" on all files except that text files are
 *    not guaranteed to be normalized: files that contain CRLF in the
 *    repository will not be touched. Use this setting if you want to have
 *    CRLF line endings in your working directory even though the repository
 *    does not have normalized line endings. This variable can be set to input,
 *    in which case no output conversion is performed.
 */
internal let _configmap_autocrlf: [git_configmap] = [
    .init(type: git_configmap_value.false, str_match: nil, map_value: GIT_AUTO_CRLF_FALSE),
    .init(type: git_configmap_t.true, str_match: nil, map_value: GIT_AUTO_CRLF_TRUE),
    .init(type: git_configmap_t.string, str_match: "input", map_value: GIT_AUTO_CRLF_INPUT),
]

internal let _configmap_safecrlf: [git_configmap] = [
    .init(type: GIT_CONFIGMAP_FALSE, str_match: nil, map_value: GIT_SAFE_CRLF_FALSE),
    .init(type: GIT_CONFIGMAP_TRUE, str_match: nil, map_value: GIT_SAFE_CRLF_FAIL),
    .init(type: GIT_CONFIGMAP_STRING, str_match: "warn", map_value: GIT_SAFE_CRLF_WARN),
]

internal let _configmap_logallrefupdates: [git_configmap] = [
    .init(type: GIT_CONFIGMAP_FALSE, str_match: nil, map_value: GIT_LOGALLREFUPDATES_FALSE),
    .init(type: GIT_CONFIGMAP_TRUE, str_match: nil, map_value: GIT_LOGALLREFUPDATES_TRUE),
    .init(type: GIT_CONFIGMAP_STRING, str_match: "always", map_value: GIT_LOGALLREFUPDATES_ALWAYS),
]



internal let _configmaps: [map_data] = [
    .init(name: "core.autocrlf", maps: _configmap_autocrlf, map_count: ARRAY_SIZE(_configmap_autocrlf), default_value: GIT_AUTO_CRLF_DEFAULT),
    .init(name: "core.eol", maps: _configmap_eol, map_count: ARRAY_SIZE(_configmap_eol), default_value: GIT_EOL_DEFAULT),
    .init(name: "core.symlinks", maps: nil, map_count: 0, default_value: GIT_SYMLINKS_DEFAULT ),
    .init(name: "core.ignorecase", maps: nil, map_count: 0, default_value: GIT_IGNORECASE_DEFAULT ),
    .init(name: "core.filemode", maps: nil, map_count: 0, default_value: GIT_FILEMODE_DEFAULT ),
    .init(name: "core.ignorestat", maps: nil, map_count: 0, default_value: GIT_IGNORESTAT_DEFAULT ),
    .init(name: "core.trustctime", maps: nil, map_count: 0, default_value: GIT_TRUSTCTIME_DEFAULT ),
    .init(name: "core.abbrev", maps: _configmap_int, map_count: 1, default_value: GIT_ABBREV_DEFAULT ),
    .init(name: "core.precomposeunicode", maps: nil, map_count: 0, default_value: GIT_PRECOMPOSE_DEFAULT ),
    .init(name: "core.safecrlf", maps: _configmap_safecrlf, map_count: ARRAY_SIZE(_configmap_safecrlf), default_value: GIT_SAFE_CRLF_DEFAULT),
    .init(name: "core.logallrefupdates", maps: _configmap_logallrefupdates, map_count: ARRAY_SIZE(_configmap_logallrefupdates), default_value: GIT_LOGALLREFUPDATES_DEFAULT),
    .init(name: "core.protecthfs", maps: nil, map_count: 0, default_value: GIT_PROTECTHFS_DEFAULT ),
    .init(name: "core.protectntfs", maps: nil, map_count: 0, default_value: GIT_PROTECTNTFS_DEFAULT ),
    .init(name: "core.fsyncobjectfiles", maps: nil, map_count: 0, default_value: GIT_FSYNCOBJECTFILES_DEFAULT ),
    .init(name: "core.longpaths", maps: nil, map_count: 0, default_value: GIT_LONGPATHS_DEFAULT ),
]
