const std = @import("std");
const testing = std.testing;

// Helper to consume a run of '*' and decide if it's `**`
fn eatStars(pat: []const u8, start: usize) struct { next: usize, cross: bool } {
    var i = start;
    var count: usize = 0;
    while (i < pat.len and pat[i] == '*') : (i += 1) count += 1;

    const cross = count >= 2; // two or more '*' behave like `**`

    // Common convenience: treat `**/` as a single unit (zero-or-more dirs).
    if (cross and i < pat.len and pat[i] == '/') {
        i += 1;
    }
    return .{ .next = i, .cross = cross };
}

/// Glob match for paths supporting `?`, `*`, and `**`.
/// - `?`  matches exactly one non-`/` character
/// - `*`  matches zero or more non-`/` characters
/// - `**` matches zero or more characters including `/` (can cross directories)
pub fn matchPath(pattern: []const u8, path: []const u8) bool {
    var pi: usize = 0; // pattern index
    var ti: usize = 0; // text index

    // Backtracking state for the most recent wildcard group
    var back_pat_i: ?usize = null; // index in pattern to resume after wildcard
    var back_txt_i: usize = 0; // next char in text to try for that wildcard
    var back_cross_slash: bool = false; // true for `**`, false for `*`

    while (true) {
        if (ti < path.len and pi < pattern.len) {
            const pc = pattern[pi];

            if (pc == '*') {
                const info = eatStars(pattern, pi);
                // Save backtrack point: wildcard can match empty; try longer on mismatch.
                back_pat_i = info.next;
                back_txt_i = ti;
                back_cross_slash = info.cross;
                pi = info.next;
                continue;
            } else if (pc == '?') {
                if (path[ti] == '/') {
                    // `?` cannot consume slash -> fall through to backtrack
                } else {
                    pi += 1;
                    ti += 1;
                    continue;
                }
            } else if (pc == path[ti]) {
                pi += 1;
                ti += 1;
                continue;
            }
            // mismatch below…
        }

        // If we reached end of path, we may still have trailing stars in pattern
        if (ti == path.len) {
            // Consume any trailing `*` or `**/`
            while (pi < pattern.len and pattern[pi] == '*') {
                const info = eatStars(pattern, pi);
                pi = info.next;
            }
            return pi == pattern.len;
        }

        // Mismatch while text remains: can we extend the last wildcard?
        if (back_pat_i) |resume_pi| {
            if (back_txt_i < path.len) {
                const ch = path[back_txt_i];
                if (!back_cross_slash and ch == '/') {
                    // Single `*` cannot cross directories; this wildcard is exhausted.
                    // Clear it and continue to see if an earlier wildcard existed (we track only the most recent).
                    back_pat_i = null;
                } else {
                    // Let the wildcard eat one more char and retry from its resume point.
                    back_txt_i += 1;
                    ti = back_txt_i;
                    pi = resume_pi;
                    continue;
                }
            } else {
                back_pat_i = null; // nothing left to consume
            }
        }

        return false; // hard mismatch
    }
}

test "glob path: ** and ?" {
    // Your example: any depth under src/, file name must end with one extra char.
    try testing.expect(matchPath("src/**/*?", "src/a/b/cx"));
    try testing.expect(matchPath("src/**/*?", "src/x")); // '*' empty + '?' = one char
    try testing.expect(!matchPath("src/**/*?", "src/")); // needs at least one char for '?'

    // `**` crosses directories, `*` doesn't.
    try testing.expect(matchPath("src/**/a.txt", "src/a.txt"));
    try testing.expect(matchPath("src/**/a.txt", "src/foo/bar/a.txt"));
    try testing.expect(matchPath("src/*/a.txt", "src/foo/a.txt"));
    try testing.expect(!matchPath("src/*/a.txt", "src/foo/bar/a.txt")); // single `*` can't cross '/'

    // `?` and `*` do not match '/'
    try testing.expect(!matchPath("a?b", "a/b"));
    try testing.expect(!matchPath("a*b", "a/b"));
}
