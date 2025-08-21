const std = @import("std");
const Io = std.Io;
const fs = std.fs;

const cli = @import("cli/root.zig");

pub fn main() !void {
    var dbg = std.heap.DebugAllocator(.{}).init;
    defer std.debug.assert(dbg.deinit() == .ok);
    const allocator = dbg.allocator();
    // const allocator = std.heap.smp_allocator;

    const file = fs.File.stdout();
    var writer = file.writerStreaming(&.{}).interface;

    const root = try cli.build(&writer, allocator);
    defer root.deinit();

    try root.execute(.{});

    try writer.flush();
}
