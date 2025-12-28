#  Important usage notes

While We don't recommend you use this library directly, We still write it with that in-mind. If possible, We recommend you instead use [Gitsune](https://GitHub.com/KyNorthstar/Gitsune), which is a more-Swiftey wrapper around this package

If you're going to use it directly, then you **must** read these important usage notes!



### Please don't try to import both this library and also libgit2 at the same time

```
// 🚨⛔️⚠️🛑 UNDEFINED BEHVIOR
import libgit2 // ❌ NEVER import both
import Git     // ❌ NEVER import both
```

While Swift can happily use C code like libgit2, this library contains migration-only code with identical signatures as those in libgit2, to aid in porting code from samples and your own prior knowledge.

If you import both of these, I assume the compiler will complain about ambiguity. However, there's a chance it won't, in which case I don't know what would happen.

So consider it **undefined behvior** (read: bad & discouraged) to use both libgit2 nd libgit2.swift in the same file.



### File Names

Since this is a 1-to-1 rewrite of libgit2, very nearly all code is arranged into files with the same names as used in libgit2. For example, if some code is in `commit.h`/`commit.c` in libgit2, then the analogous code here is in `commit.swift` libgit2.swift!

This pattern is only broken where some code is split across a header file with one name and an implementation file with another. In those cases, the header file's name is used.
 
For instance, the function `git_libgit2_init` is declared in the header `global.h`, but it's implemented in `libgit2.c`. So, libgit2.swift places this in `global.swift`.



### Code Names

Included types have been given more-Swiftey names, often along with more Swiftey paradigms.

For example, `git_commit` contains "`git_`"  because C doesn't have namespacing.
Since Swift has namespacing in the form of module names, `git_commit` has been renamed to `Commit` in this package. If you need to disambiguate, you can include the module: `Git.Commit`.

In order to make that easier on users of this package coming from libgit2, this package also includes typealiases so if you try to use the libgit2 name, it'll tell you the correct Swift name to use:

```swift
~/test.swift:12:18: error: 'GIT_OBJECT_BLOB' has been renamed to 'Object.Kind.blob'
let objectType = GIT_OBJECT_BLOB
                 ^~~~~~~~~~~~~~~
                 Object.Kind.blob
```

Public functions & others get this treatment as well. Implementation-only functions (e.g. those only declared in `.c` files) aren't included in this migration sugar for obvious reasons.


Some types have simply been omitted in favor of Swift types.

For example, `git_str` exists because C has no builtin string type and libgit2 doesn't want to rely on much external to itself. So here, `git_str` (and `char *` and similar) has been replaced with Swift's `String`. Same story with all the various forms of arrays.


### Methods & Initializers

Swift supports methods and initializers on types, so this package does too.

This means that top-level functions that initialize a type, are instead initializers on that type. Same with top-level functions which are dedicated to reading/mutating/etc. an instance of a type. Hooray!


### Concurrency

This assumes concurrency is desired!

That is to say, anywhere in libgit2 where concurrency is offered optionally (i.e. with `#if GIT_THREADS`), this package implements the version with concurrency.

Obviously, since this is Swift, the long-`await`ed structured concurrency is used!


### Error translation

libgit2 signifies error conditions with functions which return negative numbers, like this:

```c
// libgit2

int git_old_style(void)
{
    int error = 0;
    
    if ((error = git_setup_operation()) < 0 ||
        (error = git_process_operation()) < 0)
        return error;
    
    return 0;
}
```

Because Swift has an error-handling system, that's used instead. So wherever a number is returned solely to communicate an error condition, the function throws instead:

```swift
// libgit2.swift

func newStyle() throws(GitError) {
    try setupOperation()
    try processOperation()
}
```

Of coruse, if the original code throws a specific error code when any is caught, or only checks for specific error codes, this library replicates that behavior faithfully:

```c
// libgit2

int git_old_style(void)
{
    if (git_setup_operation() < 0 ||
        git_process_operation() < 0)
        return -1;
    
    return 0;
}
```
```swift
// libgit2.swift

func newStyle() throws(GitError) {
    do {
        try setupOperation()
        try processOperation()
    }
    catch {
        throw .generic
    }
}
```

> **Note:** The original code usually checks `git_something() < 0`, which would discard all positive error codes. This rewrite assumes they're always negative because that's the common case, making special exceptions when that's false. Because of that, there are no checks for whether the error code is negative; the thrown error is just rethrown.



#### Side-channel errors

libgit2 also includes side-channel errors. That is to say, sometimes it will return a negative number to signify that an error has occurred, and then set a global error variable. Sometimes it sets that global error variable in other circumstances, such as `GIT_ADD_SIZET_OVERFLOW` and its ilk. 

This is a common C pattern (see also: `errno`), because C does not have any built-in error handling mechanism.
Since Swift _does_ have a built-in error-handling mechanism in the form of `throw`/`catch`/`try`/etc., libgit2.swift uses that instead. This means that **side-channel error handling is removed from this package**, in favor of Swift's builtin error handling.

That will mostly work exactly the same. It will often include more information for recovery, as well (e.g. stack traces).

However, there are some situations where it won't work the same. For example, there are situations in libgit2 where it sets that side-channel error, but _does not return a negative number_. This can be seen with the macro `GIT_ASSERT_WITH_RETVAL` and its ilk, which save an error value to that side channel if some value is `null`, and then set that missing value to be a backup value and continue with the program instead of returning. Or `GIT_ADD_SIZET_OVERFLOW`, which set that side-channel error if there's overflow, then returns a `true` or `false` indicating overflow, as well as outputting the overflown error.

In libgit2.swift, **these situations do not set any such error nor throw a Swift error**, but otherwise behave the same.

For example, this code in libgit2:
```c
git_error_set(GIT_ERROR_REPOSITORY, "repository has no working directory");
return GIT_EBAREREPO;
```

is written like this in libgit2.swift:
```swift
throw GitError(message: "repository has no working directory", kind: .repository, code: .operationNotAllowed_bareRepo)
```


#### Fewer errors???

You might start using this and notice that some functions which "throw errors" in libgit2 (e.g. return `-1`) aren't marked as `throws` in libgit2.swift.

Perhaps you're worried that this means libgit2.swift ignores these errors and might crash if it encounters those branches. Worry not; this isn't dangerous, it's intentional and happy!
As it turns out, a lot of those errors libgit2 handles simply aren't possible in Swift.

For example, because libgit2 is platform-agnostic, it comes with nearly everything it needs, which means it implements most of the features it uses which are traditionally platform features. That means that things like variable-length arrays aren't used in libgit2, so all the arrays whose contents vary in amount are actually static-length arrays with some checks to see what the most-recently-added item's index is. So those will return `-1` if you try to add more values than it was compiled to handle.

Swift, however, has dynamic-length arrays built-in! So no such error would be thrown. So any functions where that's the only reason it would return an error code, instead always succeed!

There's also places where libgit2 throws errors when an argument passed in is `nil` but it shouldn't be (`GIT_ASSERT_ARG` etc.). Swift can guarantee at compile-time that such arguments are non-`nil`, so those errors are eliminated as well. 

That also means that libtit2.swift can handle some edge cases libgit2 can't, since it won't fail to handle operations which stack more items into these arrays.


##### Intentionally ignored error states

###### Path lengths
A lot of code in libgit2 concerns itself with ensuring file path strings are short enough to fit into memory, usually around copying them into new variables.

libgit2.swift intentionally ignores that error state, because it assumes that if it is running within a condition where a file path cannot fit into memory, that's a problem which is out-of-scope of Git to be handling.

Additionally, Swift's copy-on-write runtime feature makes this a notably less likely condition than libgit2's simpler C-style string handling.

Instead of returning an error code, the program will behave however the Swift runtime/stdlib decides is best (likely crashing with an OOM error of some sort).


### Nullability

With the exception of a handful of `// comments`, libgit2 makes no use of any form of nullability marking. As such, libgit2.swift makes deliberate choices about what is and what isn't presented as `Optional`.

This might be opinionated at times, but most often is driven by how the translated functions work, whether the original code checks for nullability, whether nullability is useful/neccessary, whether a function would crash/assert if given a null value, etc.

This might result in the nullability of fields/parameters/etc. changing in future releases. Lo siento.



### Hash algorithms

libgit2 uses SHA-1 as the default hash algorithm, and chooses various backends to perform hashing operations with, depending on the platform. 
It also hides SHA-256 behind compiler flags... mostly. 

This package always allows SHA-256, with no flags to disable/hide it.
This package also chooses _only_ CommonCrypto as the hash creation backend for all hashes.



### Primitive types

The following describes how primitives appear in libgit2, and how libgit2.swift translates them in situations:

|    libgit2     |          note          |     libgit2.swift    |
| -------------- | ---------------------- | -------------------- |
| `int`          | As the default integer | `Int`                |
| `int`          | As error code          | `GitError`           |
| `int`          | As comparison result   | `ComparisonResult`   |
| `int8_t`       |                        | `Int8`               |
| `int16_t`      |                        | `Int16`              |
| `int32_t`      |                        | `Int32`              |
| `int64_t`      |                        | `Int64`              |
| `unsigned`     |                        | `UInt`               |
| `unsigned int` |                        | `UInt`               |
| `uint8_t`      |                        | `UInt8`              |
| `uint16_t`     |                        | `UInt16`             |
| `uint32_t`     |                        | `UInt32`             |
| `uint64_t`     |                        | `UInt64`             |
| `size_t`       | For collection indices | `<collection>.Index` |
| `size_t`       | For collection counts  | `Int` or discarded   |
| `ssize_t`      | For collection counts  | `UInt` or discarded  |
| `void*`        | As unknown type        | `Any`                |
| `void*`        | As flexible type       | `<generic>`          |

> There are situations where another type is used which better describes the value (e.g. an `enum`), but which are excluded from this table because they're specific usecases and not general guidance on how to use this library



### Strings

libgit2.swift uses the Swift native `String` type wherever the concpet of a text string exists in libgit.
Anywhere libgit uses a `char *`, a `git_str`, or any other text string concept, libgit2.swift uses `String`.

That means that all strings throughout this library support full Unicode and all the other fancy things Swift strings support.

That means that some places where libgit2 might handle Unicode strings (e.g. UTF-8) could either fail or produce unexpected/undefined behavior, but in libgit2.swift they work correctly. For example, if a filename has characters which use multiple bytes (like 한), libgit2 would miscount the number of bytes as the nubmer of characters, but libgit2.swift correctly counts the number of characters.


#### String Processing

String (and character) processing functions in libgit2.swift are entirely conducted with Swift's builtin mechanisms.

This diverges from libgit2, which uses Unix C string processing (or implements its own for Windows).

The consequence of this is that libgit2.swift will handle strings in a more universally-correct way (read: Unicode compliant, etc.), but will diverge from how libgit2 handles strings. This will result in fewer internal crashes, but might result in breaking behvior.

For example, libgit2 might\* only change a character to lower/uppercase if it's an ASCII latin letter (A~Z and a~z), whereas libgit2.swift applies standard Unicode case changes for all applicable Unicode codepoints.

For example, when you ask libgit2 to make the string `"Voilà"` all-caps, it will give you `"VOILà"`, but libgit2.swift will give you `"VOILÀ"`.


> \*"might" because this is the explicit behavior when compiled for Windows, but when compiling for Unix, it's up to the specific operating system what that behavior will be.



### Runtime

libgit2 implements & ships with its own runtime. libgit2.swift instead opts to use Swift's builtin runtime.

This means that rote platform/runtime things which C needs (like arrays, allocating/freeing memory, etc.) were skipped because Swift already has a very good way to handle everything those handle.

Aside from that, all original (Git-specific) types from libgit2 are included here, mostly with Swifty names.



### Copy-on-Write

libgit2 (and most C code) uses pointers to pass around a value without having to copy it each time. 

Swift has a runtime subsystem to allow this to happen with pure-value-types (like `struct`s), providing the semantics & behavior of copying it each time but not actually copying until one of those is written to.

A non-pointer value in C (like `struct my_struct`) can be thought of as a value type, and a pointer to that value (like `my_struct*`) can be thought of as a reference type.

In Swift, value vs reference are implemented as distinct kinds of types. Values are `enum`/`struct`/etc. and references are `class`/`actor`.

This library foregoes using reference types unless absolutely necessary.



### Randomness

libgit2 provides public functionality to specifically seed its random number generator, allowing for deterministic pseudo-randomness.

libgit2.swift does not provide this functionality, instead using Swift's builtin random subsystem (which automatically stirs/seeds the random number generator), resulting in non-deterministic pseudo-randomness (or true randomness, depending on the implementation used).



### Platform detection

#### Windows platforms

libgit2 uses a custom `GIT_WIN32` compiler define to switch compile-time implementations depending on whether it's being compiled for Windows. This is defined when `_WIN32` is detected _but not_ `__CYGWIN__`

Swift Package Manager 


#### Apple platforms

libgit2 uses C's compiler directives like `#if __APPLE__` to detect whether it's being compiled for an Apple operating system, like macOS or iOS.

Swift has some similar mechanisms, but none which do exactly this.

As a workaround, libgit2.swift currently uses `#if canImport(Darwin)` to check if the Darwin operating system libraries can be imported, and assume that says whether this is an Apple operating system.

That is _not_ a perfect solition, but it's the best one available in 2025. Should a better solution become available (such as the proposed `#if os(Darwin)`), that should be adopted instead. In such a case, please let Ky know or fork this project to do that work.



### Deprecation

There are parts of libgit2 which are deprecated (e.g. under `git2/deprecated.h` andor marked `GIT_DEPRECATE_HARD`).

These are not included in libgit2.swift, under the assumption that they were deprecated with good reason and that the maintainers of libgit2 would like to remove them.

That is to say, anything wrapped in a `#ifdef GIT_DEPRECATE_HARD` **is included**, and anything wrapped in `#ifndef GIT_DEPRECATE_HARD` **is excluded** from this library.



### Documentation

If documentation is missing, that's because libgit2 didn't have any. Fuckers.

We tried to fill in the blanks where We could.

If you see doc comments like `/**` then you know it's almost entirely from the original C library.
If it's like `///` then you know We rewrote that doc comment, so it's more correct for this package.

The same (usually) goes for `/*` and `//` inline comments.
