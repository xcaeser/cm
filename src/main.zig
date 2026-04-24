const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const builtin = @import("builtin");

const cli = @import("cumul").cli;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    var argsIterator = try init.minimal.args.iterateAllocator(allocator);
    defer argsIterator.deinit();

    var wbuf: [1024]u8 = undefined;
    var stdout_file_writer = Io.File.Writer.init(.stdout(), io, &wbuf);
    const stdout = &stdout_file_writer.interface;

    var rbuf: [1024]u8 = undefined;
    var stdin_reader = Io.File.Reader.init(.stdin(), io, &rbuf);
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
