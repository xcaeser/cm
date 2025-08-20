const std = @import("std");

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
pub fn match(pattern: []const u8, target: []const u8) !bool {
    var pattern_index: usize = 0;

    main_loop: while (pattern_index < pattern.len) {
        const current_pattern_char = pattern[pattern_index];
        _ = current_pattern_char; // autofix

        if (std.mem.startsWith(u8, pattern, "*")) {
            const fixed_to_match = pattern[pattern_index + 1 ..];
            if (std.mem.endsWith(u8, target, fixed_to_match)) {
                return true;
            }
        } else if (std.mem.endsWith(u8, pattern, "*")) {
            const fixed_to_match = pattern[0..pattern_index];
            if (std.mem.startsWith(u8, pattern, fixed_to_match)) {
                return true;
            }
        }

        pattern_index += 1;
        continue :main_loop;
    }

    return false;
}
