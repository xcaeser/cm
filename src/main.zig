const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const builtin = @import("builtin");

const cli = @import("cumul").cli;

pub fn main() !void {
    var dbg = std.heap.DebugAllocator(.{}).init;

    const allocator = switch (builtin.mode) {
        .Debug => dbg.allocator(),
        .ReleaseFast, .ReleaseSafe, .ReleaseSmall => std.heap.smp_allocator,
    };

    defer if (builtin.mode == .Debug) std.debug.assert(dbg.deinit() == .ok);

    var wfile = fs.File.stdout().writerStreaming(&.{});
    var writer = &wfile.interface;

    var buf: [4096]u8 = undefined;
    var rfile = fs.File.stdin().readerStreaming(&buf);
    const reader = &rfile.interface;

    const root = try cli.build(writer, reader, allocator);
    defer root.deinit();

    try root.execute(.{});

    try writer.flush();
}
