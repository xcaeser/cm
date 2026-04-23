const std = @import("std");
const Allocator = std.mem.Allocator;
const fs = std.fs;
const fmt = std.fmt;
const Io = std.Io;

/// Need to free memory after
pub fn formatSizeToHumanReadable(allocator: Allocator, size: u64) ![]u8 {
    if (size < 1024) {
        return fmt.allocPrint(allocator, "{d} bytes", .{size});
    } else if (size < 1024 * 1024) {
        const size_kb = @as(f64, @floatFromInt(size)) / 1024.0;
        return fmt.allocPrint(allocator, "{d:.2} KB", .{size_kb});
    } else if (size < 1024 * 1024 * 1024) {
        const size_mb = @as(f64, @floatFromInt(size)) / (1024.0 * 1024.0);
        return fmt.allocPrint(allocator, "{d:.2} MB", .{size_mb});
    } else {
        const size_gb = @as(f64, @floatFromInt(size)) / (1024.0 * 1024.0 * 1024.0);
        return fmt.allocPrint(allocator, "{d:.2} GB", .{size_gb});
    }
}

/// No Need to free memory after
pub fn getNumberOfLinesInFile(io: Io, allocator: Allocator, file: *const Io.File, size: u64) !u32 {
    const content = try allocator.alloc(u8, size);
    defer allocator.free(content);
    _ = try file.readPositionalAll(io, content, 0); // @TO CHECK

    var it = std.mem.splitScalar(u8, content, '\n');
    var num_lines: u32 = 0;

    while (it.next()) |_| {
        num_lines += 1;
    }

    return num_lines;
}

/// Need to free memory after
pub fn getSkippablefilesFromGitIgnore(io: Io, allocator: Allocator, file: Io.File) ![][]const u8 {
    var array = std.ArrayList([]const u8).empty;
    errdefer array.deinit(allocator);

    var buf: [4096]u8 = undefined;
    _ = try file.readStreaming(io, &.{&buf});

    var it = std.mem.splitScalar(u8, &buf, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) continue;
        try array.append(allocator, try allocator.dupe(u8, trimmed));
    }

    return array.toOwnedSlice(allocator);
}
