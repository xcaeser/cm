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

    var stdout_writer = fs.File.stdout().writerStreaming(&.{});
    var stdout = &stdout_writer.interface;

    var buf: [4096]u8 = undefined;
    var stdin_reader = fs.File.stdin().readerStreaming(&buf);
    const stdin = &stdin_reader.interface;

    const root = try cli.build(stdout, stdin, allocator);
    defer root.deinit();

    try root.execute(.{});

    try stdout.flush();
}
