const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;

const zli = @import("zli");

pub fn register(writer: *Io.Writer, allocator: Allocator) !*zli.Command {
    return zli.Command.init(
        writer,
        allocator,
        .{
            .name = "update",
            .description = "(WIP) Update cm to the latest version",
        },
        run,
    );
}

fn run(ctx: zli.CommandContext) !void {
    const writer = ctx.writer;
    _ = writer; // autofix
    const allocator = ctx.allocator;
    _ = allocator; // autofix

    // get current installed version

    // get github release version

    // if match, then say nothing to do

    // if not match, start downloading based on the platform

    // define platform, and cpu arch

    // download executable

    std.debug.print("Not yet implemented \n", .{});
}
