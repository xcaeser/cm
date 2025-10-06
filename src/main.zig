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

    const wfile = fs.File.stdout();
    var writer = wfile.writerStreaming(&.{});

    const root = try cli.build(&writer.interface, allocator);
    defer root.deinit();

    try root.execute(.{});

    try writer.end();
}
