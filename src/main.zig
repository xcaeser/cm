const std = @import("std");
const Io = std.Io;
const fs = std.fs;

const cli = @import("cumul").cli;

pub fn main() !void {
    // var dbg = std.heap.DebugAllocator(.{}).init;
    // defer std.debug.assert(dbg.deinit() == .ok);
    // const allocator = dbg.allocator();
    const allocator = std.heap.smp_allocator;

    const wfile = fs.File.stdout();
    var writer = wfile.writerStreaming(&.{});

    const root = try cli.build(&writer.interface, allocator);
    defer root.deinit();

    try root.execute(.{});

    try writer.end();
}
