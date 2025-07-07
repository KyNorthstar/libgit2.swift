//
// filter functionality.swift
//
// Written by Ky on 2024-12-07.
// Copyright waived. No rights reserved.
//
// This file is part of libgit2.swift, distributed under the Fair License.
// For full terms, see the included LICENSE file.
//

import Foundation



// MARK: - git2/filter.h

public let GIT_FILTER_OPTIONS_VERSION = 1
public var GIT_FILTER_OPTIONS_INIT: Filter.Options { .init(version: CUnsignedInt(GIT_FILTER_OPTIONS_VERSION), flags: [], attributeLodingCommitId: nil) }


/**
 * Load the filter list for a given path.
 *
 * This will return 0 (success) but set the output git_filter_list to NULL
 * if no filters are requested for the given file.
 *
 * - Returns: Output newly created git_filter_list (or NULL if no filters are
 *         needed for the requested file)
 * - Parameter repo: Repository object that contains `path`
 * - Parameter blob: The blob to which the filter will be applied (if known)
 * - Parameter path: Relative path of the file to be filtered
 * - Parameter mode: Filtering direction (WT->ODB or ODB->WT)
 * - Parameter flags: Combination of `git_filter_flag_t` flags
 * - Throws: on error
 */
public func git_filter_list_load(
    repo: Repository,
    blob: git_blob?, /* can be NULL */
    path: String,
    mode: Filter.Mode,
    flags: Filter.Flag)
throws(GitError) -> git_filter_list? {
    var filter_session = git_filter_session()
    filter_session.options.flags = flags
    
    return try git_filter_list__load(repo: repo, blob: blob, path: path, mode: mode, filter_session: &filter_session)
}



/*
/**
 * Load the filter list for a given path.
 *
 * This will return 0 (success) but set the output git_filter_list to NULL
 * if no filters are requested for the given file.
 *
 * @param filters Output newly created git_filter_list (or NULL)
 * @param repo Repository object that contains `path`
 * @param blob The blob to which the filter will be applied (if known)
 * @param path Relative path of the file to be filtered
 * @param mode Filtering direction (WT->ODB or ODB->WT)
 * @param opts The `git_filter_options` to use when loading filters
 * @return 0 on success (which could still return NULL if no filters are
 *         needed for the requested file), <0 on error
 */
GIT_EXTERN(int) git_filter_list_load_ext(
    git_filter_list **filters,
    git_repository *repo,
    git_blob *blob,
    const char *path,
    git_filter_mode_t mode,
    git_filter_options *opts);

/**
 * Query the filter list to see if a given filter (by name) will run.
 * The built-in filters "crlf" and "ident" can be queried, otherwise this
 * is the name of the filter specified by the filter attribute.
 *
 * This will return 0 if the given filter is not in the list, or 1 if
 * the filter will be applied.
 *
 * @param filters A loaded git_filter_list (or NULL)
 * @param name The name of the filter to query
 * @return 1 if the filter is in the list, 0 otherwise
 */
GIT_EXTERN(int) git_filter_list_contains(
    git_filter_list *filters,
    const char *name);

/**
 * Apply filter list to a data buffer.
 *
 * @param out Buffer to store the result of the filtering
 * @param filters A loaded git_filter_list (or NULL)
 * @param in Buffer containing the data to filter
 * @param in_len The length of the input buffer
 * @return 0 on success, an error code otherwise
 */
GIT_EXTERN(int) git_filter_list_apply_to_buffer(
    git_buf *out,
    git_filter_list *filters,
    const char *in,
    size_t in_len);

/**
 * Apply a filter list to the contents of a file on disk
 *
 * @param out buffer into which to store the filtered file
 * @param filters the list of filters to apply
 * @param repo the repository in which to perform the filtering
 * @param path the path of the file to filter, a relative path will be
 * taken as relative to the workdir
 * @return 0 or an error code.
 */
GIT_EXTERN(int) git_filter_list_apply_to_file(
    git_buf *out,
    git_filter_list *filters,
    git_repository *repo,
    const char *path);

/**
 * Apply a filter list to the contents of a blob
 *
 * @param out buffer into which to store the filtered file
 * @param filters the list of filters to apply
 * @param blob the blob to filter
 * @return 0 or an error code.
 */
GIT_EXTERN(int) git_filter_list_apply_to_blob(
    git_buf *out,
    git_filter_list *filters,
    git_blob *blob);

/**
 * Apply a filter list to an arbitrary buffer as a stream
 *
 * @param filters the list of filters to apply
 * @param buffer the buffer to filter
 * @param len the size of the buffer
 * @param target the stream into which the data will be written
 * @return 0 or an error code.
 */
GIT_EXTERN(int) git_filter_list_stream_buffer(
    git_filter_list *filters,
    const char *buffer,
    size_t len,
    git_writestream *target);

/**
 * Apply a filter list to a file as a stream
 *
 * @param filters the list of filters to apply
 * @param repo the repository in which to perform the filtering
 * @param path the path of the file to filter, a relative path will be
 * taken as relative to the workdir
 * @param target the stream into which the data will be written
 * @return 0 or an error code.
 */
GIT_EXTERN(int) git_filter_list_stream_file(
    git_filter_list *filters,
    git_repository *repo,
    const char *path,
    git_writestream *target);

/**
 * Apply a filter list to a blob as a stream
 *
 * @param filters the list of filters to apply
 * @param blob the blob to filter
 * @param target the stream into which the data will be written
 * @return 0 or an error code.
 */
GIT_EXTERN(int) git_filter_list_stream_blob(
    git_filter_list *filters,
    git_blob *blob,
    git_writestream *target);

/**
 * Free a git_filter_list
 *
 * @param filters A git_filter_list created by `git_filter_list_load`
 */
GIT_EXTERN(void) git_filter_list_free(git_filter_list *filters);



// MARK: - git2/sys/filter.h

/**
 * Look up a filter by name
 *
 * @param name The name of the filter
 * @return Pointer to the filter object or NULL if not found
 */
GIT_EXTERN(git_filter *) git_filter_lookup(const char *name);

#define GIT_FILTER_CRLF  "crlf"
#define GIT_FILTER_IDENT "ident"

/**
 * This is priority that the internal CRLF filter will be registered with
 */
#define GIT_FILTER_CRLF_PRIORITY 0

/**
 * This is priority that the internal ident filter will be registered with
 */
#define GIT_FILTER_IDENT_PRIORITY 100

/**
 * This is priority to use with a custom filter to imitate a core Git
 * filter driver, so that it will be run last on checkout and first on
 * checkin.  You do not have to use this, but it helps compatibility.
 */
#define GIT_FILTER_DRIVER_PRIORITY 200

/**
 * Create a new empty filter list
 *
 * Normally you won't use this because `git_filter_list_load` will create
 * the filter list for you, but you can use this in combination with the
 * `git_filter_lookup` and `git_filter_list_push` functions to assemble
 * your own chains of filters.
 */
GIT_EXTERN(int) git_filter_list_new(
    git_filter_list **out,
    git_repository *repo,
    git_filter_mode_t mode,
    uint32_t options);

/**
 * Add a filter to a filter list with the given payload.
 *
 * Normally you won't have to do this because the filter list is created
 * by calling the "check" function on registered filters when the filter
 * attributes are set, but this does allow more direct manipulation of
 * filter lists when desired.
 *
 * Note that normally the "check" function can set up a payload for the
 * filter.  Using this function, you can either pass in a payload if you
 * know the expected payload format, or you can pass NULL.  Some filters
 * may fail with a NULL payload.  Good luck!
 */
GIT_EXTERN(int) git_filter_list_push(
    git_filter_list *fl, git_filter *filter, void *payload);

/**
 * Look up how many filters are in the list
 *
 * We will attempt to apply all of these filters to any data passed in,
 * but note that the filter apply action still has the option of skipping
 * data that is passed in (for example, the CRLF filter will skip data
 * that appears to be binary).
 *
 * @param fl A filter list
 * @return The number of filters in the list
 */
GIT_EXTERN(size_t) git_filter_list_length(const git_filter_list *fl);

/**
 * A filter source represents a file/blob to be processed
 */
typedef struct git_filter_source git_filter_source;

/**
 * Get the repository that the source data is coming from.
 */
GIT_EXTERN(git_repository *) git_filter_source_repo(const git_filter_source *src);

/**
 * Get the path that the source data is coming from.
 */
GIT_EXTERN(const char *) git_filter_source_path(const git_filter_source *src);

/**
 * Get the file mode of the source file
 * If the mode is unknown, this will return 0
 */
GIT_EXTERN(uint16_t) git_filter_source_filemode(const git_filter_source *src);

/**
 * Get the OID of the source
 * If the OID is unknown (often the case with GIT_FILTER_CLEAN) then
 * this will return NULL.
 */
GIT_EXTERN(const git_oid *) git_filter_source_id(const git_filter_source *src);

/**
 * Get the git_filter_mode_t to be used
 */
GIT_EXTERN(git_filter_mode_t) git_filter_source_mode(const git_filter_source *src);

/**
 * Get the combination git_filter_flag_t options to be applied
 */
GIT_EXTERN(uint32_t) git_filter_source_flags(const git_filter_source *src);

/**
 * Initialize callback on filter
 *
 * Specified as `filter.initialize`, this is an optional callback invoked
 * before a filter is first used.  It will be called once at most.
 *
 * If non-NULL, the filter's `initialize` callback will be invoked right
 * before the first use of the filter, so you can defer expensive
 * initialization operations (in case libgit2 is being used in a way that
 * doesn't need the filter).
 */
typedef int GIT_CALLBACK(git_filter_init_fn)(git_filter *self);

/**
 * Shutdown callback on filter
 *
 * Specified as `filter.shutdown`, this is an optional callback invoked
 * when the filter is unregistered or when libgit2 is shutting down.  It
 * will be called once at most and should release resources as needed.
 * This may be called even if the `initialize` callback was not made.
 *
 * Typically this function will free the `git_filter` object itself.
 */
typedef void GIT_CALLBACK(git_filter_shutdown_fn)(git_filter *self);

/**
 * Callback to decide if a given source needs this filter
 *
 * Specified as `filter.check`, this is an optional callback that checks
 * if filtering is needed for a given source.
 *
 * It should return 0 if the filter should be applied (i.e. success),
 * GIT_PASSTHROUGH if the filter should not be applied, or an error code
 * to fail out of the filter processing pipeline and return to the caller.
 *
 * The `attr_values` will be set to the values of any attributes given in
 * the filter definition.  See `git_filter` below for more detail.
 *
 * The `payload` will be a pointer to a reference payload for the filter.
 * This will start as NULL, but `check` can assign to this pointer for
 * later use by the `stream` callback.  Note that the value should be heap
 * allocated (not stack), so that it doesn't go away before the `stream`
 * callback can use it.  If a filter allocates and assigns a value to the
 * `payload`, it will need a `cleanup` callback to free the payload.
 */
typedef int GIT_CALLBACK(git_filter_check_fn)(
    git_filter              *self,
    void                   **payload, /* NULL on entry, may be set */
    const git_filter_source *src,
    const char             **attr_values);

#ifndef GIT_DEPRECATE_HARD
/**
 * Callback to actually perform the data filtering
 *
 * Specified as `filter.apply`, this is the callback that actually filters
 * data.  If it successfully writes the output, it should return 0.  Like
 * `check`, it can return GIT_PASSTHROUGH to indicate that the filter
 * doesn't want to run.  Other error codes will stop filter processing and
 * return to the caller.
 *
 * The `payload` value will refer to any payload that was set by the
 * `check` callback.  It may be read from or written to as needed.
 *
 * @deprecated use git_filter_stream_fn
 */
typedef int GIT_CALLBACK(git_filter_apply_fn)(
    git_filter              *self,
    void                   **payload, /* may be read and/or set */
    git_buf                 *to,
    const git_buf           *from,
    const git_filter_source *src);
#endif

/**
 * Callback to perform the data filtering.
 *
 * Specified as `filter.stream`, this is a callback that filters data
 * in a streaming manner.  This function will provide a
 * `git_writestream` that will the original data will be written to;
 * with that data, the `git_writestream` will then perform the filter
 * translation and stream the filtered data out to the `next` location.
 */
typedef int GIT_CALLBACK(git_filter_stream_fn)(
    git_writestream        **out,
    git_filter              *self,
    void                   **payload,
    const git_filter_source *src,
    git_writestream         *next);

/**
 * Callback to clean up after filtering has been applied
 *
 * Specified as `filter.cleanup`, this is an optional callback invoked
 * after the filter has been applied.  If the `check`, `apply`, or
 * `stream` callbacks allocated a `payload` to keep per-source filter
 * state, use this callback to free that payload and release resources
 * as required.
 */
typedef void GIT_CALLBACK(git_filter_cleanup_fn)(
    git_filter              *self,
    void                    *payload);

/**
 * Filter structure used to register custom filters.
 *
 * To associate extra data with a filter, allocate extra data and put the
 * `git_filter` struct at the start of your data buffer, then cast the
 * `self` pointer to your larger structure when your callback is invoked.
 */
struct git_filter {
    /** The `version` field should be set to `GIT_FILTER_VERSION`. */
    unsigned int           version;

     /**
     * A whitespace-separated list of attribute names to check for this
     * filter (e.g. "eol crlf text").  If the attribute name is bare, it
     * will be simply loaded and passed to the `check` callback.  If it
     * has a value (i.e. "name=value"), the attribute must match that
     * value for the filter to be applied.  The value may be a wildcard
     * (eg, "name=*"), in which case the filter will be invoked for any
     * value for the given attribute name.  See the attribute parameter
     * of the `check` callback for the attribute value that was specified.
     */
    const char            *attributes;

    /** Called when the filter is first used for any file. */
    git_filter_init_fn     initialize;

    /** Called when the filter is removed or unregistered from the system. */
    git_filter_shutdown_fn shutdown;

    /**
     * Called to determine whether the filter should be invoked for a
     * given file.  If this function returns `GIT_PASSTHROUGH` then the
     * `stream` or `apply` functions will not be invoked and the
     * contents will be passed through unmodified.
     */
    git_filter_check_fn    check;

#ifdef GIT_DEPRECATE_HARD
    void *reserved;
#else
    /**
     * Provided for backward compatibility; this will apply the
     * filter to the given contents in a `git_buf`.  Callers should
     * provide a `stream` function instead.
     */
    git_filter_apply_fn    apply;
#endif

    /**
     * Called to apply the filter, this function will provide a
     * `git_writestream` that will the original data will be
     * written to; with that data, the `git_writestream` will then
     * perform the filter translation and stream the filtered data
     * out to the `next` location.
     */
    git_filter_stream_fn   stream;

    /** Called when the system is done filtering for a file. */
    git_filter_cleanup_fn  cleanup;
};

#define GIT_FILTER_VERSION 1
#define GIT_FILTER_INIT {GIT_FILTER_VERSION}

/**
 * Initializes a `git_filter` with default values. Equivalent to
 * creating an instance with GIT_FILTER_INIT.
 *
 * @param filter the `git_filter` struct to initialize.
 * @param version Version the struct; pass `GIT_FILTER_VERSION`
 * @return Zero on success; -1 on failure.
 */
GIT_EXTERN(int) git_filter_init(git_filter *filter, unsigned int version);

/**
 * Register a filter under a given name with a given priority.
 *
 * As mentioned elsewhere, the initialize callback will not be invoked
 * immediately.  It is deferred until the filter is used in some way.
 *
 * A filter's attribute checks and `check` and `stream` (or `apply`)
 * callbacks will be issued in order of `priority` on smudge (to
 * workdir), and in reverse order of `priority` on clean (to odb).
 *
 * Two filters are preregistered with libgit2:
 * - GIT_FILTER_CRLF with priority 0
 * - GIT_FILTER_IDENT with priority 100
 *
 * Currently the filter registry is not thread safe, so any registering or
 * deregistering of filters must be done outside of any possible usage of
 * the filters (i.e. during application setup or shutdown).
 *
 * @param name A name by which the filter can be referenced.  Attempting
 *             to register with an in-use name will return GIT_EEXISTS.
 * @param filter The filter definition.  This pointer will be stored as is
 *             by libgit2 so it must be a durable allocation (either static
 *             or on the heap).
 * @param priority The priority for filter application
 * @return 0 on successful registry, error code <0 on failure
 */
GIT_EXTERN(int) git_filter_register(
    const char *name, git_filter *filter, int priority);

/**
 * Remove the filter with the given name
 *
 * Attempting to remove the builtin libgit2 filters is not permitted and
 * will return an error.
 *
 * Currently the filter registry is not thread safe, so any registering or
 * deregistering of filters must be done outside of any possible usage of
 * the filters (i.e. during application setup or shutdown).
 *
 * @param name The name under which the filter was registered
 * @return 0 on success, error code <0 on failure
 */
GIT_EXTERN(int) git_filter_unregister(const char *name);



// MARK: - libgit2/filter.h

/* Amount of file to examine for NUL byte when checking binary-ness */
#define GIT_FILTER_BYTES_TO_CHECK_NUL 8000
 */



public struct git_filter_session: AnyStructProtocol {
    public var options: Filter.Options
    public var attr_session: git_attr_session?
    public var temp_buf: String? = nil
    
    public init(
        options: Filter.Options,
        attr_session: git_attr_session?,
        temp_buf: String? = nil)
    {
        self.options = options
        self.attr_session = attr_session
        self.temp_buf = temp_buf
    }
    
    
    public init() {
        self.init(
            options: GIT_FILTER_OPTIONS_INIT,
            attr_session: nil)
    }
}



@available(*, unavailable, renamed: "git_filter_session()")
public var GIT_FILTER_SESSION_INIT: git_filter_session { fatalError() }



/*
extern int git_filter_global_init(void);

extern void git_filter_free(git_filter *filter);

extern int git_filter_list__load(
    git_filter_list **filters,
    git_repository *repo,
    git_blob *blob, /* can be NULL */
    const char *path,
    git_filter_mode_t mode,
    git_filter_session *filter_session);

int git_filter_list__apply_to_buffer(
    git_str *out,
    git_filter_list *filters,
    const char *in,
    size_t in_len);
int git_filter_list__apply_to_file(
    git_str *out,
    git_filter_list *filters,
    git_repository *repo,
    const char *path);
int git_filter_list__apply_to_blob(
    git_str *out,
    git_filter_list *filters,
    git_blob *blob);

/*
 * The given input buffer will be converted to the given output buffer.
 * The input buffer will be freed (_if_ it was allocated).
 */
extern int git_filter_list__convert_buf(
    git_str *out,
    git_filter_list *filters,
    git_str *in);

extern int git_filter_list__apply_to_file(
    git_str *out,
    git_filter_list *filters,
    git_repository *repo,
    const char *path);

/*
 * Available filters
 */

extern git_filter *git_crlf_filter_new(void);
extern git_filter *git_ident_filter_new(void);

extern int git_filter_buffered_stream_new(
    git_writestream **out,
    git_filter *filter,
    int (*write_fn)(git_filter *, void **, git_str *, const git_str *, const git_filter_source *),
    git_str *temp_buf,
    void **payload,
    const git_filter_source *source,
    git_writestream *target);



// MARK: - libgit2/filter.c

struct git_filter_source {
    git_repository    *repo;
    const char        *path;
    git_oid            oid;  /* zero if unknown (which is likely) */
    uint16_t           filemode; /* zero if unknown */
    git_filter_mode_t  mode;
    git_filter_options options;
};
 */



private struct git_filter_entry: AnyStructProtocol {
    var filter_name: String
    var filter: Filter
    var payload: AnyTypeProtocol
}



public struct git_filter_list: AnyStructProtocol {
    fileprivate var filters: Array<git_filter_entry>
    fileprivate var source: Filter.Source
    fileprivate var temp_buf: String
    fileprivate let path: String
}



private struct git_filter_def: AnyStructProtocol {
    var filter_name: String
    var filter: Filter
    var priority: CInt
    var initialized: CInt
    var nattrs: size_t
    var nmatches: size_t
    var attrdata: String
    var attrs: [String]
}



/*
static int filter_def_priority_cmp(const void *a, const void *b)
{
    int pa = ((const git_filter_def *)a)->priority;
    int pb = ((const git_filter_def *)b)->priority;
    return (pa < pb) ? -1 : (pa > pb) ? 1 : 0;
}
 */



@Volatile
private struct git_filter_registry {
    var filters: SelfSortingArray<Filter> = []
}



private let filter_registry = git_filter_registry()



/*
static void git_filter_global_shutdown(void);


static int filter_def_scan_attrs(
    git_str *attrs, size_t *nattr, size_t *nmatch, const char *attr_str)
{
    const char *start, *scan = attr_str;
    int has_eq;

    *nattr = *nmatch = 0;

    if (!scan)
        return 0;

    while (*scan) {
        while (git__isspace(*scan)) scan++;

        for (start = scan, has_eq = 0; *scan && !git__isspace(*scan); ++scan) {
            if (*scan == '=')
                has_eq = 1;
        }

        if (scan > start) {
            (*nattr)++;
            if (has_eq || *start == '-' || *start == '+' || *start == '!')
                (*nmatch)++;

            if (has_eq)
                git_str_putc(attrs, '=');
            git_str_put(attrs, start, scan - start);
            git_str_putc(attrs, '\0');
        }
    }

    return 0;
}

static void filter_def_set_attrs(git_filter_def *fdef)
{
    char *scan = fdef->attrdata;
    size_t i;

    for (i = 0; i < fdef->nattrs; ++i) {
        const char *name, *value;

        switch (*scan) {
        case '=':
            name = scan + 1;
            for (scan++; *scan != '='; scan++) /* find '=' */;
            *scan++ = '\0';
            value = scan;
            break;
        case '-':
            name = scan + 1; value = git_attr__false; break;
        case '+':
            name = scan + 1; value = git_attr__true;  break;
        case '!':
            name = scan + 1; value = git_attr__unset; break;
        default:
            name = scan;     value = NULL; break;
        }

        fdef->attrs[i] = name;
        fdef->attrs[i + fdef->nattrs] = value;

        scan += strlen(scan) + 1;
    }
}

static int filter_def_name_key_check(const void *key, const void *fdef)
{
    const char *name =
        fdef ? ((const git_filter_def *)fdef)->filter_name : NULL;
    return name ? git__strcmp(key, name) : -1;
}

static int filter_def_filter_key_check(const void *key, const void *fdef)
{
    const void *filter = fdef ? ((const git_filter_def *)fdef)->filter : NULL;
    return (key == filter) ? 0 : -1;
}

/* Note: callers must lock the registry before calling this function */
static int filter_registry_insert(
    const char *name, git_filter *filter, int priority)
{
    git_filter_def *fdef;
    size_t nattr = 0, nmatch = 0, alloc_len;
    git_str attrs = GIT_STR_INIT;

    if (filter_def_scan_attrs(&attrs, &nattr, &nmatch, filter->attributes) < 0)
        return -1;

    GIT_ERROR_CHECK_ALLOC_MULTIPLY(&alloc_len, nattr, 2);
    GIT_ERROR_CHECK_ALLOC_MULTIPLY(&alloc_len, alloc_len, sizeof(char *));
    GIT_ERROR_CHECK_ALLOC_ADD(&alloc_len, alloc_len, sizeof(git_filter_def));

    fdef = git__calloc(1, alloc_len);
    GIT_ERROR_CHECK_ALLOC(fdef);

    fdef->filter_name = git__strdup(name);
    GIT_ERROR_CHECK_ALLOC(fdef->filter_name);

    fdef->filter      = filter;
    fdef->priority    = priority;
    fdef->nattrs      = nattr;
    fdef->nmatches    = nmatch;
    fdef->attrdata    = git_str_detach(&attrs);

    filter_def_set_attrs(fdef);

    if (git_vector_insert(&filter_registry.filters, fdef) < 0) {
        git__free(fdef->filter_name);
        git__free(fdef->attrdata);
        git__free(fdef);
        return -1;
    }

    git_vector_sort(&filter_registry.filters);
    return 0;
}

int git_filter_global_init(void)
{
    git_filter *crlf = NULL, *ident = NULL;
    int error = 0;

    if (git_rwlock_init(&filter_registry.lock) < 0)
        return -1;

    if ((error = git_vector_init(&filter_registry.filters, 2,
        filter_def_priority_cmp)) < 0)
        goto done;

    if ((crlf = git_crlf_filter_new()) == NULL ||
        filter_registry_insert(
            GIT_FILTER_CRLF, crlf, GIT_FILTER_CRLF_PRIORITY) < 0 ||
        (ident = git_ident_filter_new()) == NULL ||
        filter_registry_insert(
            GIT_FILTER_IDENT, ident, GIT_FILTER_IDENT_PRIORITY) < 0)
        error = -1;

    if (!error)
        error = git_runtime_shutdown_register(git_filter_global_shutdown);

done:
    if (error) {
        git_filter_free(crlf);
        git_filter_free(ident);
    }

    return error;
}

static void git_filter_global_shutdown(void)
{
    size_t pos;
    git_filter_def *fdef;

    if (git_rwlock_wrlock(&filter_registry.lock) < 0)
        return;

    git_vector_foreach(&filter_registry.filters, pos, fdef) {
        if (fdef->filter && fdef->filter->shutdown) {
            fdef->filter->shutdown(fdef->filter);
            fdef->initialized = false;
        }

        git__free(fdef->filter_name);
        git__free(fdef->attrdata);
        git__free(fdef);
    }

    git_vector_free(&filter_registry.filters);

    git_rwlock_wrunlock(&filter_registry.lock);
    git_rwlock_free(&filter_registry.lock);
}

/* Note: callers must lock the registry before calling this function */
static int filter_registry_find(size_t *pos, const char *name)
{
    return git_vector_search2(
        pos, &filter_registry.filters, filter_def_name_key_check, name);
}

/* Note: callers must lock the registry before calling this function */
static git_filter_def *filter_registry_lookup(size_t *pos, const char *name)
{
    git_filter_def *fdef = NULL;

    if (!filter_registry_find(pos, name))
        fdef = git_vector_get(&filter_registry.filters, *pos);

    return fdef;
}


int git_filter_register(
    const char *name, git_filter *filter, int priority)
{
    int error;

    GIT_ASSERT_ARG(name);
    GIT_ASSERT_ARG(filter);

    if (git_rwlock_wrlock(&filter_registry.lock) < 0) {
        git_error_set(GIT_ERROR_OS, "failed to lock filter registry");
        return -1;
    }

    if (!filter_registry_find(NULL, name)) {
        git_error_set(
            GIT_ERROR_FILTER, "attempt to reregister existing filter '%s'", name);
        error = GIT_EEXISTS;
        goto done;
    }

    error = filter_registry_insert(name, filter, priority);

done:
    git_rwlock_wrunlock(&filter_registry.lock);
    return error;
}

int git_filter_unregister(const char *name)
{
    size_t pos;
    git_filter_def *fdef;
    int error = 0;

    GIT_ASSERT_ARG(name);

    /* cannot unregister default filters */
    if (!strcmp(GIT_FILTER_CRLF, name) || !strcmp(GIT_FILTER_IDENT, name)) {
        git_error_set(GIT_ERROR_FILTER, "cannot unregister filter '%s'", name);
        return -1;
    }

    if (git_rwlock_wrlock(&filter_registry.lock) < 0) {
        git_error_set(GIT_ERROR_OS, "failed to lock filter registry");
        return -1;
    }

    if ((fdef = filter_registry_lookup(&pos, name)) == NULL) {
        git_error_set(GIT_ERROR_FILTER, "cannot find filter '%s' to unregister", name);
        error = GIT_ENOTFOUND;
        goto done;
    }

    git_vector_remove(&filter_registry.filters, pos);

    if (fdef->initialized && fdef->filter && fdef->filter->shutdown) {
        fdef->filter->shutdown(fdef->filter);
        fdef->initialized = false;
    }

    git__free(fdef->filter_name);
    git__free(fdef->attrdata);
    git__free(fdef);

done:
    git_rwlock_wrunlock(&filter_registry.lock);
    return error;
}

static int filter_initialize(git_filter_def *fdef)
{
    int error = 0;

    if (!fdef->initialized && fdef->filter && fdef->filter->initialize) {
        if ((error = fdef->filter->initialize(fdef->filter)) < 0)
            return error;
    }

    fdef->initialized = true;
    return 0;
}

git_filter *git_filter_lookup(const char *name)
{
    size_t pos;
    git_filter_def *fdef;
    git_filter *filter = NULL;

    if (git_rwlock_rdlock(&filter_registry.lock) < 0) {
        git_error_set(GIT_ERROR_OS, "failed to lock filter registry");
        return NULL;
    }

    if ((fdef = filter_registry_lookup(&pos, name)) == NULL ||
        (!fdef->initialized && filter_initialize(fdef) < 0))
        goto done;

    filter = fdef->filter;

done:
    git_rwlock_rdunlock(&filter_registry.lock);
    return filter;
}

void git_filter_free(git_filter *filter)
{
    git__free(filter);
}

git_repository *git_filter_source_repo(const git_filter_source *src)
{
    return src->repo;
}

const char *git_filter_source_path(const git_filter_source *src)
{
    return src->path;
}

uint16_t git_filter_source_filemode(const git_filter_source *src)
{
    return src->filemode;
}

const git_oid *git_filter_source_id(const git_filter_source *src)
{
    return git_oid_is_zero(&src->oid) ? NULL : &src->oid;
}

git_filter_mode_t git_filter_source_mode(const git_filter_source *src)
{
    return src->mode;
}

uint32_t git_filter_source_flags(const git_filter_source *src)
{
    return src->options.flags;
}

static int filter_list_new(
    git_filter_list **out, const git_filter_source *src)
{
    git_filter_list *fl = NULL;
    size_t pathlen = src->path ? strlen(src->path) : 0, alloclen;

    GIT_ERROR_CHECK_ALLOC_ADD(&alloclen, sizeof(git_filter_list), pathlen);
    GIT_ERROR_CHECK_ALLOC_ADD(&alloclen, alloclen, 1);

    fl = git__calloc(1, alloclen);
    GIT_ERROR_CHECK_ALLOC(fl);

    if (src->path)
        memcpy(fl->path, src->path, pathlen);
    fl->source.repo = src->repo;
    fl->source.path = fl->path;
    fl->source.mode = src->mode;

    memcpy(&fl->source.options, &src->options, sizeof(git_filter_options));

    *out = fl;
    return 0;
}
 
 */

private func filter_list_check_attributes(
    repo: Repository,
    filter_session: git_filter_session,
    fdef: git_filter_def,
    src: Filter.Source)
throws(GitError) -> String?
{
    let strs: [String?] = .init(repeating: nil, count: fdef.nattrs)
    var attr_opts = GIT_ATTR_OPTIONS_INIT
    var i: size_t
    var error: GitError
    
    if let options = src.options {
        if options.flags.contains(.noSystemAttributes) {
            attr_opts.flags.insert(.GIT_ATTR_CHECK_NO_SYSTEM)
        }
        
        if options.flags.contains(.noSystemAttributes) {
            attr_opts.flags.insert(.GIT_ATTR_CHECK_NO_SYSTEM)
        }
        
        if options.flags.contains(.attributesFromHead) {
            attr_opts.flags.insert(.GIT_ATTR_CHECK_INCLUDE_HEAD)
        }
        
        if options.flags.contains(.attributesFromCommit) {
            attr_opts.flags.insert(.GIT_ATTR_CHECK_INCLUDE_COMMIT)
            
            // The following code translates this original C code:
            //
            // git_oid_cpy(&attr_opts.attr_commit_id, &src->options.attr_commit_id);
            
            do {
                attr_opts.attr_commit_id = try src.options?.attributeLodingCommitId?.copy()
            }
            catch {
                // Ignore errors
            }
        }
    }

    do {
        try git_attr_get_many_with_session(
            strs, repo, filter_session->attr_session, &attr_opts, src->path, fdef->nattrs, fdef->attrs);
    }
    catch let error where error.code == GIT_ENOTFOUND && (0 == fdef.nmatches) {
        /* if no values were found but no matches are needed, it's okay! */
        return nil
    }
    // The above code translates this original C code:
    //
    // error = git_attr_get_many_with_session(
    //     strs, repo, filter_session->attr_session, &attr_opts, src->path, fdef->nattrs, fdef->attrs);
    // if (error == GIT_ENOTFOUND && !fdef->nmatches) {
    //     git_error_clear();
    //     git__free((void *)strs);
    //     return 0;
    // }
        
    
    for (i = 0; !error && i < fdef->nattrs; ++i) {
        const char *want = fdef->attrs[fdef->nattrs + i];
        git_attr_value_t want_type, found_type;

        if (!want)
            continue;

        want_type  = git_attr_value(want);
        found_type = git_attr_value(strs[i]);

        if (want_type != found_type)
            error = GIT_ENOTFOUND;
        else if (want_type == GIT_ATTR_VALUE_STRING &&
                strcmp(want, strs[i]) &&
                strcmp(want, "*"))
            error = GIT_ENOTFOUND;
    }
    
    if (error)
        git__free((void *)strs);
    else
        *out = strs;

    return error;
}

/*

 int git_filter_list_new(
    git_filter_list **out,
    git_repository *repo,
    git_filter_mode_t mode,
    uint32_t flags)
{
    git_filter_source src = { 0 };
    src.repo = repo;
    src.path = NULL;
    src.mode = mode;
    src.options.flags = flags;
    return filter_list_new(out, &src);
}
*/


func git_filter_list__load(
    repo: Repository,
    blob: git_blob?, /* can be NULL */
    path: String,
    mode: Filter.Mode,
    filter_session: inout git_filter_session)
throws(GitError)
-> git_filter_list?
{
    var error: GitError.Code? = nil
    var fl: git_filter_list? = nil
    var src: Filter.Source = .init()
    var fe: git_filter_entry
    var idx: size_t
    var fdef: git_filter_def
    
    Volatile.run {
        src.repo = repo
        src.path = path
        src.mode = mode
        src.options = filter_session.options
        
        if let blob {
            src.oid = git_blob_id(obj: blob)
        }
        
        // for ((idx) = 0; (idx) < (filter_registry.filters)->length && ((fdef) = (filter_registry.filters)->contents[(idx)], 1); (idx)++ )
    filterLoop:
        for fdef in filter_registry.filters {
            let values: [String]? = nil
            var payload: Any? = nil
            
            guard nil != fdef?.filter else {
                continue filterLoop
            }
            
            if (fdef.nattrs > 0) {
                do {
                    filter_list_check_attributes(
                        &values, repo,
                        filter_session, fdef, &src)
                }
                catch let error where error.code == GIT_ENOTFOUND {
                    continue filterLoop
                }
                catch let error where error.code != nil {
                    break filterLoop
                }
                
                // The above code translates this original C code:
                //
                // error = filter_list_check_attributes(
                //     &values, repo,
                //     filter_session, fdef, &src);
                //
                // if (error == GIT_ENOTFOUND) {
                //     error = 0;
                //     continue;
                // } else if (error < 0)
                //             break;
            }
            
            if (!fdef->initialized && (error = filter_initialize(fdef)) < 0)
                break;
            
            if (fdef->filter->check)
                error = fdef->filter->check(
                    fdef->filter, &payload, &src, values);
            
            git__free((void *)values);
            
            if (error == GIT_PASSTHROUGH)
                error = 0;
            else if (error < 0)
                        break;
            else {
                if (!fl) {
                    if ((error = filter_list_new(&fl, &src)) < 0)
                        break;
                    
                    fl->temp_buf = filter_session->temp_buf;
                }
                
                fe = git_array_alloc(fl->filters);
                GIT_ERROR_CHECK_ALLOC(fe);
                
                fe->filter = fdef->filter;
                fe->filter_name = fdef->filter_name;
                fe->payload = payload;
            }
        }
    }
    
    if (error && fl != NULL) {
        git_array_clear(fl->filters);
        git__free(fl);
        fl = NULL;
    }

    *filters = fl;
    return error;
}



/*
int git_filter_list_load_ext(
    git_filter_list **filters,
    git_repository *repo,
    git_blob *blob, /* can be NULL */
    const char *path,
    git_filter_mode_t mode,
    git_filter_options *opts)
{
    git_filter_session filter_session = GIT_FILTER_SESSION_INIT;

    if (opts)
        memcpy(&filter_session.options, opts, sizeof(git_filter_options));

    return git_filter_list__load(
        filters, repo, blob, path, mode, &filter_session);
}

int git_filter_list_load(
    git_filter_list **filters,
    git_repository *repo,
    git_blob *blob, /* can be NULL */
    const char *path,
    git_filter_mode_t mode,
    uint32_t flags)
{
    git_filter_session filter_session = GIT_FILTER_SESSION_INIT;

    filter_session.options.flags = flags;

    return git_filter_list__load(
        filters, repo, blob, path, mode, &filter_session);
}

void git_filter_list_free(git_filter_list *fl)
{
    uint32_t i;

    if (!fl)
        return;

    for (i = 0; i < git_array_size(fl->filters); ++i) {
        git_filter_entry *fe = git_array_get(fl->filters, i);
        if (fe->filter->cleanup)
            fe->filter->cleanup(fe->filter, fe->payload);
    }

    git_array_clear(fl->filters);
    git__free(fl);
}

int git_filter_list_contains(
    git_filter_list *fl,
    const char *name)
{
    size_t i;

    GIT_ASSERT_ARG(name);

    if (!fl)
        return 0;

    for (i = 0; i < fl->filters.size; i++) {
        if (strcmp(fl->filters.ptr[i].filter_name, name) == 0)
            return 1;
    }

    return 0;
}

int git_filter_list_push(
    git_filter_list *fl, git_filter *filter, void *payload)
{
    int error = 0;
    size_t pos;
    git_filter_def *fdef = NULL;
    git_filter_entry *fe;

    GIT_ASSERT_ARG(fl);
    GIT_ASSERT_ARG(filter);

    if (git_rwlock_rdlock(&filter_registry.lock) < 0) {
        git_error_set(GIT_ERROR_OS, "failed to lock filter registry");
        return -1;
    }

    if (git_vector_search2(
            &pos, &filter_registry.filters,
            filter_def_filter_key_check, filter) == 0)
        fdef = git_vector_get(&filter_registry.filters, pos);

    git_rwlock_rdunlock(&filter_registry.lock);

    if (fdef == NULL) {
        git_error_set(GIT_ERROR_FILTER, "cannot use an unregistered filter");
        return -1;
    }

    if (!fdef->initialized && (error = filter_initialize(fdef)) < 0)
        return error;

    fe = git_array_alloc(fl->filters);
    GIT_ERROR_CHECK_ALLOC(fe);
    fe->filter  = filter;
    fe->payload = payload;

    return 0;
}

size_t git_filter_list_length(const git_filter_list *fl)
{
    return fl ? git_array_size(fl->filters) : 0;
}

struct buf_stream {
    git_writestream parent;
    git_str *target;
    bool complete;
};

static int buf_stream_write(
    git_writestream *s, const char *buffer, size_t len)
{
    struct buf_stream *buf_stream = (struct buf_stream *)s;
    GIT_ASSERT_ARG(buf_stream);
    GIT_ASSERT(buf_stream->complete == 0);

    return git_str_put(buf_stream->target, buffer, len);
}

static int buf_stream_close(git_writestream *s)
{
    struct buf_stream *buf_stream = (struct buf_stream *)s;
    GIT_ASSERT_ARG(buf_stream);

    GIT_ASSERT(buf_stream->complete == 0);
    buf_stream->complete = 1;

    return 0;
}

static void buf_stream_free(git_writestream *s)
{
    GIT_UNUSED(s);
}

static void buf_stream_init(struct buf_stream *writer, git_str *target)
{
    memset(writer, 0, sizeof(struct buf_stream));

    writer->parent.write = buf_stream_write;
    writer->parent.close = buf_stream_close;
    writer->parent.free = buf_stream_free;
    writer->target = target;

    git_str_clear(target);
}

int git_filter_list_apply_to_buffer(
    git_buf *out,
    git_filter_list *filters,
    const char *in,
    size_t in_len)
{
    GIT_BUF_WRAP_PRIVATE(out, git_filter_list__apply_to_buffer, filters, in, in_len);
}

int git_filter_list__apply_to_buffer(
    git_str *out,
    git_filter_list *filters,
    const char *in,
    size_t in_len)
{
    struct buf_stream writer;
    int error;

    buf_stream_init(&writer, out);

    if ((error = git_filter_list_stream_buffer(filters,
        in, in_len, &writer.parent)) < 0)
            return error;

    GIT_ASSERT(writer.complete);
    return error;
}

int git_filter_list__convert_buf(
    git_str *out,
    git_filter_list *filters,
    git_str *in)
{
    int error;

    if (!filters || git_filter_list_length(filters) == 0) {
        git_str_swap(out, in);
        git_str_dispose(in);
        return 0;
    }

    error = git_filter_list__apply_to_buffer(out, filters,
        in->ptr, in->size);

    if (!error)
        git_str_dispose(in);

    return error;
}

int git_filter_list_apply_to_file(
    git_buf *out,
    git_filter_list *filters,
    git_repository *repo,
    const char *path)
{
    GIT_BUF_WRAP_PRIVATE(out, git_filter_list__apply_to_file, filters, repo, path);
}

int git_filter_list__apply_to_file(
    git_str *out,
    git_filter_list *filters,
    git_repository *repo,
    const char *path)
{
    struct buf_stream writer;
    int error;

    buf_stream_init(&writer, out);

    if ((error = git_filter_list_stream_file(
        filters, repo, path, &writer.parent)) < 0)
            return error;

    GIT_ASSERT(writer.complete);
    return error;
}

static int buf_from_blob(git_str *out, git_blob *blob)
{
    git_object_size_t rawsize = git_blob_rawsize(blob);

    if (!git__is_sizet(rawsize)) {
        git_error_set(GIT_ERROR_OS, "blob is too large to filter");
        return -1;
    }

    git_str_attach_notowned(out, git_blob_rawcontent(blob), (size_t)rawsize);
    return 0;
}

int git_filter_list_apply_to_blob(
    git_buf *out,
    git_filter_list *filters,
    git_blob *blob)
{
    GIT_BUF_WRAP_PRIVATE(out, git_filter_list__apply_to_blob, filters, blob);
}

int git_filter_list__apply_to_blob(
    git_str *out,
    git_filter_list *filters,
    git_blob *blob)
{
    struct buf_stream writer;
    int error;

    buf_stream_init(&writer, out);

    if ((error = git_filter_list_stream_blob(
        filters, blob, &writer.parent)) < 0)
            return error;

    GIT_ASSERT(writer.complete);
    return error;
}

struct buffered_stream {
    git_writestream parent;
    git_filter *filter;
    int (*write_fn)(git_filter *, void **, git_str *, const git_str *, const git_filter_source *);
    int (*legacy_write_fn)(git_filter *, void **, git_buf *, const git_buf *, const git_filter_source *);
    const git_filter_source *source;
    void **payload;
    git_str input;
    git_str temp_buf;
    git_str *output;
    git_writestream *target;
};

static int buffered_stream_write(
    git_writestream *s, const char *buffer, size_t len)
{
    struct buffered_stream *buffered_stream = (struct buffered_stream *)s;
    GIT_ASSERT_ARG(buffered_stream);

    return git_str_put(&buffered_stream->input, buffer, len);
}

#ifndef GIT_DEPRECATE_HARD
# define BUF_TO_STRUCT(b, s) \
    (b)->ptr = (s)->ptr; \
    (b)->size = (s)->size;  \
    (b)->reserved = (s)->asize;
# define STRUCT_TO_BUF(s, b) \
    (s)->ptr = (b)->ptr; \
    (s)->size = (b)->size; \
    (s)->asize = (b)->reserved;
#endif

static int buffered_stream_close(git_writestream *s)
{
    struct buffered_stream *buffered_stream = (struct buffered_stream *)s;
    git_str *writebuf;
    git_error *last_error;
    int error;

    GIT_ASSERT_ARG(buffered_stream);

#ifndef GIT_DEPRECATE_HARD
    if (buffered_stream->write_fn == NULL) {
        git_buf legacy_output = GIT_BUF_INIT,
                legacy_input = GIT_BUF_INIT;

        BUF_TO_STRUCT(&legacy_output, buffered_stream->output);
        BUF_TO_STRUCT(&legacy_input, &buffered_stream->input);

        error = buffered_stream->legacy_write_fn(
            buffered_stream->filter,
            buffered_stream->payload,
            &legacy_output,
            &legacy_input,
            buffered_stream->source);

        STRUCT_TO_BUF(buffered_stream->output, &legacy_output);
        STRUCT_TO_BUF(&buffered_stream->input, &legacy_input);
    } else
#endif
    error = buffered_stream->write_fn(
        buffered_stream->filter,
        buffered_stream->payload,
        buffered_stream->output,
        &buffered_stream->input,
        buffered_stream->source);

    if (error == GIT_PASSTHROUGH) {
        writebuf = &buffered_stream->input;
    } else if (error == 0) {
        writebuf = buffered_stream->output;
    } else {
        /* close stream before erroring out taking care
         * to preserve the original error */
        git_error_save(&last_error);
        buffered_stream->target->close(buffered_stream->target);
        git_error_restore(last_error);
        return error;
    }

    if ((error = buffered_stream->target->write(
            buffered_stream->target, writebuf->ptr, writebuf->size)) == 0)
        error = buffered_stream->target->close(buffered_stream->target);

    return error;
}

static void buffered_stream_free(git_writestream *s)
{
    struct buffered_stream *buffered_stream = (struct buffered_stream *)s;

    if (buffered_stream) {
        git_str_dispose(&buffered_stream->input);
        git_str_dispose(&buffered_stream->temp_buf);
        git__free(buffered_stream);
    }
}

int git_filter_buffered_stream_new(
    git_writestream **out,
    git_filter *filter,
    int (*write_fn)(git_filter *, void **, git_str *, const git_str *, const git_filter_source *),
    git_str *temp_buf,
    void **payload,
    const git_filter_source *source,
    git_writestream *target)
{
    struct buffered_stream *buffered_stream = git__calloc(1, sizeof(struct buffered_stream));
    GIT_ERROR_CHECK_ALLOC(buffered_stream);

    buffered_stream->parent.write = buffered_stream_write;
    buffered_stream->parent.close = buffered_stream_close;
    buffered_stream->parent.free = buffered_stream_free;
    buffered_stream->filter = filter;
    buffered_stream->write_fn = write_fn;
    buffered_stream->output = temp_buf ? temp_buf : &buffered_stream->temp_buf;
    buffered_stream->payload = payload;
    buffered_stream->source = source;
    buffered_stream->target = target;

    if (temp_buf)
        git_str_clear(temp_buf);

    *out = (git_writestream *)buffered_stream;
    return 0;
}

#ifndef GIT_DEPRECATE_HARD
static int buffered_legacy_stream_new(
    git_writestream **out,
    git_filter *filter,
    int (*legacy_write_fn)(git_filter *, void **, git_buf *, const git_buf *, const git_filter_source *),
    git_str *temp_buf,
    void **payload,
    const git_filter_source *source,
    git_writestream *target)
{
    struct buffered_stream *buffered_stream = git__calloc(1, sizeof(struct buffered_stream));
    GIT_ERROR_CHECK_ALLOC(buffered_stream);

    buffered_stream->parent.write = buffered_stream_write;
    buffered_stream->parent.close = buffered_stream_close;
    buffered_stream->parent.free = buffered_stream_free;
    buffered_stream->filter = filter;
    buffered_stream->legacy_write_fn = legacy_write_fn;
    buffered_stream->output = temp_buf ? temp_buf : &buffered_stream->temp_buf;
    buffered_stream->payload = payload;
    buffered_stream->source = source;
    buffered_stream->target = target;

    if (temp_buf)
        git_str_clear(temp_buf);

    *out = (git_writestream *)buffered_stream;
    return 0;
}
#endif

static int setup_stream(
    git_writestream **out,
    git_filter_entry *fe,
    git_filter_list *filters,
    git_writestream *last_stream)
{
#ifndef GIT_DEPRECATE_HARD
    GIT_ASSERT(fe->filter->stream || fe->filter->apply);

    /*
     * If necessary, create a stream that proxies the traditional
     * application.
     */
    if (!fe->filter->stream) {
        /* Create a stream that proxies the one-shot apply */
        return buffered_legacy_stream_new(out,
            fe->filter, fe->filter->apply, filters->temp_buf,
            &fe->payload, &filters->source, last_stream);
    }
#endif

    GIT_ASSERT(fe->filter->stream);
    return fe->filter->stream(out, fe->filter,
        &fe->payload, &filters->source, last_stream);
}

static int stream_list_init(
    git_writestream **out,
    git_vector *streams,
    git_filter_list *filters,
    git_writestream *target)
{
    git_writestream *last_stream = target;
    size_t i;
    int error = 0;

    *out = NULL;

    if (!filters) {
        *out = target;
        return 0;
    }

    /* Create filters last to first to get the chaining direction */
    for (i = 0; i < git_array_size(filters->filters); ++i) {
        size_t filter_idx = (filters->source.mode == GIT_FILTER_TO_WORKTREE) ?
            git_array_size(filters->filters) - 1 - i : i;

        git_filter_entry *fe = git_array_get(filters->filters, filter_idx);
        git_writestream *filter_stream;

        error = setup_stream(&filter_stream, fe, filters, last_stream);

        if (error < 0)
            goto out;

        git_vector_insert(streams, filter_stream);
        last_stream = filter_stream;
    }

out:
    if (error)
        last_stream->close(last_stream);
    else
        *out = last_stream;

    return error;
}

static void filter_streams_free(git_vector *streams)
{
    git_writestream *stream;
    size_t i;

    git_vector_foreach(streams, i, stream)
        stream->free(stream);
    git_vector_free(streams);
}

int git_filter_list_stream_file(
    git_filter_list *filters,
    git_repository *repo,
    const char *path,
    git_writestream *target)
{
    char buf[GIT_BUFSIZE_FILTERIO];
    git_str abspath = GIT_STR_INIT;
    const char *base = repo ? git_repository_workdir(repo) : NULL;
    git_vector filter_streams = GIT_VECTOR_INIT;
    git_writestream *stream_start;
    ssize_t readlen;
    int fd = -1, error, initialized = 0;

    if ((error = stream_list_init(
            &stream_start, &filter_streams, filters, target)) < 0 ||
        (error = git_fs_path_join_unrooted(&abspath, path, base, NULL)) < 0 ||
        (error = git_path_validate_str_length(repo, &abspath)) < 0)
        goto done;

    initialized = 1;

    if ((fd = git_futils_open_ro(abspath.ptr)) < 0) {
        error = fd;
        goto done;
    }

    while ((readlen = p_read(fd, buf, sizeof(buf))) > 0) {
        if ((error = stream_start->write(stream_start, buf, readlen)) < 0)
            goto done;
    }

    if (readlen < 0)
        error = -1;

done:
    if (initialized)
        error |= stream_start->close(stream_start);

    if (fd >= 0)
        p_close(fd);
    filter_streams_free(&filter_streams);
    git_str_dispose(&abspath);
    return error;
}

int git_filter_list_stream_buffer(
    git_filter_list *filters,
    const char *buffer,
    size_t len,
    git_writestream *target)
{
    git_vector filter_streams = GIT_VECTOR_INIT;
    git_writestream *stream_start;
    int error, initialized = 0;

    if ((error = stream_list_init(&stream_start, &filter_streams, filters, target)) < 0)
        goto out;
    initialized = 1;

    if ((error = stream_start->write(stream_start, buffer, len)) < 0)
        goto out;

out:
    if (initialized)
        error |= stream_start->close(stream_start);

    filter_streams_free(&filter_streams);
    return error;
}

int git_filter_list_stream_blob(
    git_filter_list *filters,
    git_blob *blob,
    git_writestream *target)
{
    git_str in = GIT_STR_INIT;

    if (buf_from_blob(&in, blob) < 0)
        return -1;

    if (filters)
        git_oid_cpy(&filters->source.oid, git_blob_id(blob));

    return git_filter_list_stream_buffer(filters, in.ptr, in.size, target);
}

int git_filter_init(git_filter *filter, unsigned int version)
{
    GIT_INIT_STRUCTURE_FROM_TEMPLATE(filter, version, git_filter, GIT_FILTER_INIT);
    return 0;
}

#ifndef GIT_DEPRECATE_HARD

int git_filter_list_stream_data(
    git_filter_list *filters,
    git_buf *data,
    git_writestream *target)
{
    return git_filter_list_stream_buffer(filters, data->ptr, data->size, target);
}

int git_filter_list_apply_to_data(
    git_buf *tgt, git_filter_list *filters, git_buf *src)
{
    return git_filter_list_apply_to_buffer(tgt, filters, src->ptr, src->size);
}

#endif



// MARK: - libgit2/crlf.c

typedef enum {
    GIT_CRLF_UNDEFINED,
    GIT_CRLF_BINARY,
    GIT_CRLF_TEXT,
    GIT_CRLF_TEXT_INPUT,
    GIT_CRLF_TEXT_CRLF,
    GIT_CRLF_AUTO,
    GIT_CRLF_AUTO_INPUT,
    GIT_CRLF_AUTO_CRLF
} git_crlf_t;

struct crlf_attrs {
    int attr_action; /* the .gitattributes setting */
    int crlf_action; /* the core.autocrlf setting */

    int auto_crlf;
    int safe_crlf;
    int core_eol;
};

struct crlf_filter {
    git_filter f;
};

static git_crlf_t check_crlf(const char *value)
{
    if (GIT_ATTR_IS_TRUE(value))
        return GIT_CRLF_TEXT;
    else if (GIT_ATTR_IS_FALSE(value))
        return GIT_CRLF_BINARY;
    else if (GIT_ATTR_IS_UNSPECIFIED(value))
        ;
    else if (strcmp(value, "input") == 0)
        return GIT_CRLF_TEXT_INPUT;
    else if (strcmp(value, "auto") == 0)
        return GIT_CRLF_AUTO;

    return GIT_CRLF_UNDEFINED;
}

static git_configmap_value check_eol(const char *value)
{
    if (GIT_ATTR_IS_UNSPECIFIED(value))
        ;
    else if (strcmp(value, "lf") == 0)
        return GIT_EOL_LF;
    else if (strcmp(value, "crlf") == 0)
        return GIT_EOL_CRLF;

    return GIT_EOL_UNSET;
}

static int has_cr_in_index(const git_filter_source *src)
{
    git_repository *repo = git_filter_source_repo(src);
    const char *path = git_filter_source_path(src);
    git_index *index;
    const git_index_entry *entry;
    git_blob *blob;
    const void *blobcontent;
    git_object_size_t blobsize;
    bool found_cr;

    if (!path)
        return false;

    if (git_repository_index__weakptr(&index, repo) < 0) {
        git_error_clear();
        return false;
    }

    if (!(entry = git_index_get_bypath(index, path, 0)) &&
        !(entry = git_index_get_bypath(index, path, 1)))
        return false;

    if (!S_ISREG(entry->mode)) /* don't crlf filter non-blobs */
        return true;

    if (git_blob_lookup(&blob, repo, &entry->id) < 0)
        return false;

    blobcontent = git_blob_rawcontent(blob);
    blobsize    = git_blob_rawsize(blob);
    if (!git__is_sizet(blobsize))
        blobsize = (size_t)-1;

    found_cr = (blobcontent != NULL &&
        blobsize > 0 &&
        memchr(blobcontent, '\r', (size_t)blobsize) != NULL);

    git_blob_free(blob);
    return found_cr;
}

static int text_eol_is_crlf(struct crlf_attrs *ca)
{
    if (ca->auto_crlf == GIT_AUTO_CRLF_TRUE)
        return 1;
    else if (ca->auto_crlf == GIT_AUTO_CRLF_INPUT)
        return 0;

    if (ca->core_eol == GIT_EOL_CRLF)
        return 1;
    if (ca->core_eol == GIT_EOL_UNSET && GIT_EOL_NATIVE == GIT_EOL_CRLF)
        return 1;

    return 0;
}

static git_configmap_value output_eol(struct crlf_attrs *ca)
{
    switch (ca->crlf_action) {
    case GIT_CRLF_BINARY:
        return GIT_EOL_UNSET;
    case GIT_CRLF_TEXT_CRLF:
        return GIT_EOL_CRLF;
    case GIT_CRLF_TEXT_INPUT:
        return GIT_EOL_LF;
    case GIT_CRLF_UNDEFINED:
    case GIT_CRLF_AUTO_CRLF:
        return GIT_EOL_CRLF;
    case GIT_CRLF_AUTO_INPUT:
        return GIT_EOL_LF;
    case GIT_CRLF_TEXT:
    case GIT_CRLF_AUTO:
        return text_eol_is_crlf(ca) ? GIT_EOL_CRLF : GIT_EOL_LF;
    }

    /* TODO: warn when available */
    return ca->core_eol;
}

GIT_INLINE(int) check_safecrlf(
    struct crlf_attrs *ca,
    const git_filter_source *src,
    git_str_text_stats *stats)
{
    const char *filename = git_filter_source_path(src);

    if (!ca->safe_crlf)
        return 0;

    if (output_eol(ca) == GIT_EOL_LF) {
        /*
         * CRLFs would not be restored by checkout:
         * check if we'd remove CRLFs
         */
        if (stats->crlf) {
            if (ca->safe_crlf == GIT_SAFE_CRLF_WARN) {
                /* TODO: issue a warning when available */
            } else {
                if (filename && *filename)
                    git_error_set(
                        GIT_ERROR_FILTER, "CRLF would be replaced by LF in '%s'",
                        filename);
                else
                    git_error_set(
                        GIT_ERROR_FILTER, "CRLF would be replaced by LF");

                return -1;
            }
        }
    } else if (output_eol(ca) == GIT_EOL_CRLF) {
        /*
         * CRLFs would be added by checkout:
         * check if we have "naked" LFs
         */
        if (stats->crlf != stats->lf) {
            if (ca->safe_crlf == GIT_SAFE_CRLF_WARN) {
                /* TODO: issue a warning when available */
            } else {
                if (filename && *filename)
                    git_error_set(
                        GIT_ERROR_FILTER, "LF would be replaced by CRLF in '%s'",
                        filename);
                else
                    git_error_set(
                        GIT_ERROR_FILTER, "LF would be replaced by CRLF");

                return -1;
            }
        }
    }

    return 0;
}

static int crlf_apply_to_odb(
    struct crlf_attrs *ca,
    git_str *to,
    const git_str *from,
    const git_filter_source *src)
{
    git_str_text_stats stats;
    bool is_binary;
    int error;

    /* Binary attribute? Empty file? Nothing to do */
    if (ca->crlf_action == GIT_CRLF_BINARY || from->size == 0)
        return GIT_PASSTHROUGH;

    is_binary = git_str_gather_text_stats(&stats, from, false);

    /* Heuristics to see if we can skip the conversion.
     * Straight from Core Git.
     */
    if (ca->crlf_action == GIT_CRLF_AUTO ||
        ca->crlf_action == GIT_CRLF_AUTO_INPUT ||
        ca->crlf_action == GIT_CRLF_AUTO_CRLF) {

        if (is_binary)
            return GIT_PASSTHROUGH;

        /*
         * If the file in the index has any CR in it, do not convert.
         * This is the new safer autocrlf handling.
         */
        if (has_cr_in_index(src))
            return GIT_PASSTHROUGH;
    }

    if ((error = check_safecrlf(ca, src, &stats)) < 0)
        return error;

    /* If there are no CR characters to filter out, then just pass */
    if (!stats.crlf)
        return GIT_PASSTHROUGH;

    /* Actually drop the carriage returns */
    return git_str_crlf_to_lf(to, from);
}

static int crlf_apply_to_workdir(
    struct crlf_attrs *ca,
    git_str *to,
    const git_str *from)
{
    git_str_text_stats stats;
    bool is_binary;

    /* Empty file? Nothing to do. */
    if (git_str_len(from) == 0 || output_eol(ca) != GIT_EOL_CRLF)
        return GIT_PASSTHROUGH;

    is_binary = git_str_gather_text_stats(&stats, from, false);

    /* If there are no LFs, or all LFs are part of a CRLF, nothing to do */
    if (stats.lf == 0 || stats.lf == stats.crlf)
        return GIT_PASSTHROUGH;

    if (ca->crlf_action == GIT_CRLF_AUTO ||
        ca->crlf_action == GIT_CRLF_AUTO_INPUT ||
        ca->crlf_action == GIT_CRLF_AUTO_CRLF) {

        /* If we have any existing CR or CRLF line endings, do nothing */
        if (stats.cr > 0)
            return GIT_PASSTHROUGH;

        /* Don't filter binary files */
        if (is_binary)
            return GIT_PASSTHROUGH;
    }

    return git_str_lf_to_crlf(to, from);
}

static int convert_attrs(
    struct crlf_attrs *ca,
    const char **attr_values,
    const git_filter_source *src)
{
    int error;

    memset(ca, 0, sizeof(struct crlf_attrs));

    if ((error = git_repository__configmap_lookup(&ca->auto_crlf,
         git_filter_source_repo(src), GIT_CONFIGMAP_AUTO_CRLF)) < 0 ||
        (error = git_repository__configmap_lookup(&ca->safe_crlf,
         git_filter_source_repo(src), GIT_CONFIGMAP_SAFE_CRLF)) < 0 ||
        (error = git_repository__configmap_lookup(&ca->core_eol,
         git_filter_source_repo(src), GIT_CONFIGMAP_EOL)) < 0)
        return error;

    /* downgrade FAIL to WARN if ALLOW_UNSAFE option is used */
    if ((git_filter_source_flags(src) & GIT_FILTER_ALLOW_UNSAFE) &&
        ca->safe_crlf == GIT_SAFE_CRLF_FAIL)
        ca->safe_crlf = GIT_SAFE_CRLF_WARN;

    if (attr_values) {
        /* load the text attribute */
        ca->crlf_action = check_crlf(attr_values[2]); /* text */

        if (ca->crlf_action == GIT_CRLF_UNDEFINED)
            ca->crlf_action = check_crlf(attr_values[0]); /* crlf */

        if (ca->crlf_action != GIT_CRLF_BINARY) {
            /* load the eol attribute */
            int eol_attr = check_eol(attr_values[1]);

            if (ca->crlf_action == GIT_CRLF_AUTO && eol_attr == GIT_EOL_LF)
                ca->crlf_action = GIT_CRLF_AUTO_INPUT;
            else if (ca->crlf_action == GIT_CRLF_AUTO && eol_attr == GIT_EOL_CRLF)
                ca->crlf_action = GIT_CRLF_AUTO_CRLF;
            else if (eol_attr == GIT_EOL_LF)
                ca->crlf_action = GIT_CRLF_TEXT_INPUT;
            else if (eol_attr == GIT_EOL_CRLF)
                ca->crlf_action = GIT_CRLF_TEXT_CRLF;
        }

        ca->attr_action = ca->crlf_action;
    } else {
        ca->crlf_action = GIT_CRLF_UNDEFINED;
    }

    if (ca->crlf_action == GIT_CRLF_TEXT)
        ca->crlf_action = text_eol_is_crlf(ca) ? GIT_CRLF_TEXT_CRLF : GIT_CRLF_TEXT_INPUT;
    if (ca->crlf_action == GIT_CRLF_UNDEFINED && ca->auto_crlf == GIT_AUTO_CRLF_FALSE)
        ca->crlf_action = GIT_CRLF_BINARY;
    if (ca->crlf_action == GIT_CRLF_UNDEFINED && ca->auto_crlf == GIT_AUTO_CRLF_TRUE)
        ca->crlf_action = GIT_CRLF_AUTO_CRLF;
    if (ca->crlf_action == GIT_CRLF_UNDEFINED && ca->auto_crlf == GIT_AUTO_CRLF_INPUT)
        ca->crlf_action = GIT_CRLF_AUTO_INPUT;

    return 0;
}

static int crlf_check(
    git_filter *self,
    void **payload, /* points to NULL ptr on entry, may be set */
    const git_filter_source *src,
    const char **attr_values)
{
    struct crlf_attrs ca;

    GIT_UNUSED(self);

    convert_attrs(&ca, attr_values, src);

    if (ca.crlf_action == GIT_CRLF_BINARY)
        return GIT_PASSTHROUGH;

    *payload = git__malloc(sizeof(ca));
    GIT_ERROR_CHECK_ALLOC(*payload);
    memcpy(*payload, &ca, sizeof(ca));

    return 0;
}

static int crlf_apply(
    git_filter *self,
    void **payload, /* may be read and/or set */
    git_str *to,
    const git_str *from,
    const git_filter_source *src)
{
    int error = 0;

    /* initialize payload in case `check` was bypassed */
    if (!*payload) {
        if ((error = crlf_check(self, payload, src, NULL)) < 0)
            return error;
    }

    if (git_filter_source_mode(src) == GIT_FILTER_SMUDGE)
        error = crlf_apply_to_workdir(*payload, to, from);
    else
        error = crlf_apply_to_odb(*payload, to, from, src);

    return error;
}

static int crlf_stream(
    git_writestream **out,
    git_filter *self,
    void **payload,
    const git_filter_source *src,
    git_writestream *next)
{
    return git_filter_buffered_stream_new(out,
        self, crlf_apply, NULL, payload, src, next);
}

static void crlf_cleanup(
    git_filter *self,
    void       *payload)
{
    GIT_UNUSED(self);
    git__free(payload);
}

git_filter *git_crlf_filter_new(void)
{
    struct crlf_filter *f = git__calloc(1, sizeof(struct crlf_filter));
    if (f == NULL)
        return NULL;

    f->f.version = GIT_FILTER_VERSION;
    f->f.attributes = "crlf eol text";
    f->f.initialize = NULL;
    f->f.shutdown = git_filter_free;
    f->f.check    = crlf_check;
    f->f.stream   = crlf_stream;
    f->f.cleanup  = crlf_cleanup;

    return (git_filter *)f;
}
*/
