#  libgit2.swift

A reimplementation of [libgit2](https://github.com/libgit2/libgit2) in Swift.

**Based on libgit2 1.8.4** because that was the most recent release when We started writing it.
Tho some of that was a bit silly (like `util/unix/realpath.c` didn't compile on Open BSD) so We took some from 1.9.1 too.

Written by Ky, who doesn't recommend you use this. Instead, they recommend you use their package [Gitsune](https://GitHub.com/KyNorthstar/Gitsune), which is a more-Swiftey wrapper around this package.

This package attempts to be a 1-to-1 Swift rewrite of libgit2, and as such it doesn't attempt to introduce any sugar or other refinements (outside basic things like using Swift's error system). Gitsune's goal is to be fully Swift-first, rather than just a rewrite.



## Why?

We like Swift better than C and feel like it'll be a good langauge to rewrite libit2 in. Safer and compile-guaranteed and all that.



## How?

How do you use it?

Well, mostly just like libgit2, just without unnecessary C bullshit like pointer-juggling and explicit freeing.

```swift
import Git

// TODO: EXAMPLE CODE HERE
```



## Important Usage Notes

While We don't recommend you use this library directly, We still write it with that in-mind. If possible, We recommend you instead use [Gitsune](https://GitHub.com/KyNorthstar/Gitsune), which is a more-Swiftey wrapper around this package

If you're going to use it, then you **must** read [IMPORTANT USAGE NOTES.md](./IMPORTANT USAGE NOTES.md)



## Windows

No Windows support yet, sadly. Putting in a bunch of placeholder Windows code but won't be able to make sure it compiles & runs on Windows til We have a Windows machine to test it on.



## Feedback

If you have an improvement idea, or just feel strongly about any of the decisions which cause this package to diverge from libgit2 (for example, using platform randomness and denying deterministic PRNG), please file an issue at https://github.com/KyLeggiero/libgit2.swift/issues/new/choose



## History

This started in November of 2024 by just copying the C files for libgit2 and translating each one. 
