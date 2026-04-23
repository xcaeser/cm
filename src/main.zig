const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const builtin = @import("builtin");

const cli = @import("cumul").cli;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var argsIterator = init.minimal.args.iterate();

    var wbuf: [4096]u8 = undefined;
    var stdout_writer = Io.File.stdout().writerStreaming(io, &wbuf);
    var stdout = &stdout_writer.interface;

    var rbuf: [4096]u8 = undefined;
    var stdin_reader = Io.File.stdin().readerStreaming(io, &rbuf);
    const stdin = &stdin_reader.interface;

    const root = try cli.build(.{
        .io = io,
        .allocator = allocator,
        .writer = stdout,
        .reader = stdin,
    });
    defer root.deinit();

    try root.execute(&argsIterator, .{});

    try stdout.flush();
}
