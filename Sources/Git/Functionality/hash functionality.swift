//
// global functionality.swift
//
// Written by Ky on 2024-12-07.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



public struct GitHash<Context: ShaContext>: AnyStructProtocol {
    var context: HashContext<Context>
}



public extension GitHash {
    // Analogous to `git_hash_ctx_init`
    init() {
        self.init(context: HashContext.init())
        
        // The above code translates this original C code:
        //
        // int error;
        //
        // switch (algorithm) {
        // case GIT_HASH_ALGORITHM_SHA1:
        //     error = git_hash_sha1_ctx_init(&ctx->ctx.sha1);
        //     break;
        // case GIT_HASH_ALGORITHM_SHA256:
        //     error = git_hash_sha256_ctx_init(&ctx->ctx.sha256);
        //     break;
        // default:
        //     git_error_set(GIT_ERROR_INTERNAL, "unknown hash algorithm");
        //     error = -1;
        // }
        //
        // ctx->algorithm = algorithm;
        // return error;
    }
}



extension GitHash: ShaContext {
    public static var algorithm: HashAlgorithm { Context.algorithm }
    
    
    // Analogous to `git_hash_update`
    mutating public func update(with data: Data) {
        self.context.update(with: data)
        
        // The above code translates this original C code:
        //
        // switch (ctx->algorithm) {
        // case GIT_HASH_ALGORITHM_SHA1:
        //     return git_hash_sha1_update(&ctx->ctx.sha1, data, len);
        // case GIT_HASH_ALGORITHM_SHA256:
        //     return git_hash_sha256_update(&ctx->ctx.sha256, data, len);
        // default:
        //     /* unreachable */ ;
        // }
        //
        // git_error_set(GIT_ERROR_INTERNAL, "unknown hash algorithm");
        // return -1;
    }
    
    
    // Analogous to `git_hash_final`
    public mutating func resolved() -> Data? {
        self.context.resolved()
    }
    
    
    @available(*, deprecated, renamed: "resolved()", message: "You shouldn't need to provide an initial string")
    public mutating func resolved(__advanced__initialData out: Data) -> Data? {
        self.context.resolved(__advanced__initialData: out)
        
        // The above code translates this original C code:
        //
        // switch (ctx->algorithm) {
        // case GIT_HASH_ALGORITHM_SHA1:
        //     return git_hash_sha1_final(out, &ctx->ctx.sha1);
        // case GIT_HASH_ALGORITHM_SHA256:
        //     return git_hash_sha256_final(out, &ctx->ctx.sha256);
        // default:
        //     /* unreachable */ ;
        // }
        //
        // git_error_set(GIT_ERROR_INTERNAL, "unknown hash algorithm");
        // return -1;
    }
}



internal extension GitHash {
    /// Creates a new context, then updates it with each of the given hash datas, then retuns the final resolved hash
    /// - Parameter hashDatas: The data to hash
    /// - Returns: The hash of the given data
    // Analogous to `git_hash_buf`
    func updateAndResolve(with hashData: Data) -> Data? {
        var ctx = HashContext<Context>()
        ctx.update(with: hashData)
        return ctx.resolved()
        
        
        // The above code translates this original C code:
        //
        // git_hash_ctx ctx;
        // int error = 0;
        //
        // if (git_hash_ctx_init(&ctx, algorithm) < 0)
        //     return -1;
        //
        // if ((error = git_hash_update(&ctx, data, len)) >= 0)
        //     error = git_hash_final(out, &ctx);
        //
        // git_hash_ctx_cleanup(&ctx);
        //
        // return error;
    }
    
    
    /// Creates a new context, then updates it with each of the given hash datas, then retuns the final resolved hash
    /// - Parameter hashDatas: The data to hash
    /// - Returns: The hash of the given data
    // Analogous to `git_hash_vec`
    static func updateAndResolve(each hashDatas: [Data]) -> Data? {
        var ctx = HashContext<Context>()
        
        for hashData in hashDatas {
            ctx.update(with: hashData)
        }
        
        return ctx.resolved()
        
        // The above code translates this original C code:
        //
        //     git_hash_ctx ctx;
        //     size_t i;
        //     int error = 0;
        //
        //     if (git_hash_ctx_init(&ctx, algorithm) < 0)
        //         return -1;
        //
        //     for (i = 0; i < n; i++) {
        //         if ((error = git_hash_update(&ctx, vec[i].data, vec[i].len)) < 0)
        //             goto done;
        //     }
        //
        //     error = git_hash_final(out, &ctx);
        //
        // done:
        //     git_hash_ctx_cleanup(&ctx);
        //
        //     return error;
    }
    
    
    @inline(__always)
    func format(hash: Data) -> String {
        hash.hexEncodedString
    }
    
    
    @inline(__always)
    static var hashSize: size_t {
        Self.algorithm.hashSize
    }
}



// MARK: - Migration

@available(*, unavailable, message: "Unneded in libgit2.swift (was solely dealloc)")
public func git_hash_global_init() -> CInt { fatalError() }

@available(*, unavailable, message: "Unneded in libgit2.swift (was solely dealloc)")
public func git_hash_ctx_cleanup(_ ctx: inout git_hash_ctx?) { fatalError() }

@available(*, unavailable, renamed: "git_hash_ctx()")
public func git_hash_init(_: inout git_hash_ctx) -> CInt { fatalError() }

@available(*, unavailable, renamed: "GitHash.updateAndResolve(with:)")
public func git_hash_buf(_: inout [CUnsignedChar]?, _: VoidStar, _: size_t, _: git_hash_algorithm_t) -> CInt { fatalError() }

@available(*, unavailable, renamed: "GitHash.resolved()")
public func git_hash_final(_: inout [CUnsignedChar], _: inout git_hash_ctx) -> CInt { fatalError() }

@available(*, unavailable, renamed: "GitHash.updateAndResolve")
public func git_hash_vec(_: inout [CUnsignedChar], _: git_str_vec, _: size_t, _: git_hash_algorithm_t) -> CInt { fatalError() }

@available(*, unavailable, renamed: "GitHash.format(hash:)")
public func git_hash_fmt(_: inout [CChar], _: [CUnsignedChar], _: size_t) -> CInt { fatalError() }


@available(*, unavailable, renamed: "HashAlgorithm.hashSize")
public func git_hash_size(_: git_hash_algorithm_t) -> size_t { fatalError() }
