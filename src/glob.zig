const std = @import("std");
const testing = std.testing;
const Matcher = @This();

/// Asterisk (*):
/// Matches zero or more characters.
/// Example: *.txt matches all files ending with .txt.
/// Example: data* matches all files starting with data.
/// Example: *report* matches all files containing "report" in their name.
///
/// Question Mark (?):
/// Matches any single character.
/// Example: file?.log matches file1.log, fileA.log, but not file12.log.
///
/// Brackets ([]):
/// Matches any single character within the specified set.
/// Example: [abc].txt matches a.txt, b.txt, or c.txt.
/// Example: [0-9].csv matches any single digit followed by .csv.
///
/// Braces ({}):
/// Matches one of a comma-separated list of alternatives. This is often an extended glob feature.
/// Example: .{jpg,png} matches files ending with either .jpg or .png.
///
/// Double Asterisk (``)**
/// Matches zero or more directories and subdirectories recursively. This is also typically an extended glob feature.
/// Example: src/**/*.js matches all .js files within the src directory and any of its subdirectories.
///
pub fn match(pattern: []const u8, target: []const u8) bool {
    var left_ok: bool = false;
    var right_ok: bool = false;

    // xx*x$xxx
    //    ^
    if (std.mem.indexOfScalar(u8, pattern, '*')) |pattern_index| {
        const left_side = pattern[0..pattern_index];
        const right_side = pattern[pattern_index + 1 ..];

        if (left_side.len > 0) {
            std.debug.print("Left : {s}\n", .{left_side});

            const clip = target[0..left_side.len];
            std.debug.print("Clipping: {s}\n", .{clip});

            if (std.mem.eql(u8, clip, left_side)) {
                std.debug.print("Left side Matching!!!\n", .{});

                left_ok = true;
            }
        } else left_ok = true;
        if (right_side.len > 0) {
            std.debug.print("Right : {s}\n", .{right_side});

            const clip = target[target.len - right_side.len .. target.len];
            std.debug.print("Clipping: {s}\n", .{clip});

            if (std.mem.eql(u8, clip, right_side)) {
                std.debug.print("Right side Matching!!!\n", .{});

                right_ok = true;
            }
        } else right_ok = true;
    }

    return left_ok and right_ok;
}

test "Glob zig" {
    const star_start = match("a*d.txt", "anaoufalmamasitad.txt");

    std.debug.print("* Start Matched: {}\n", .{star_start});
}
