const std = @import("std");
const Writer = std.Io.Writer;

const zli = @import("zli");
const cumul = @import("cumul");

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(writer, allocator, .{
        .name = "start",
        .shortcut = "s",
        .description = "testing",
    }, run);
}

fn run(ctx: zli.CommandContext) !void {
    _ = ctx;

    const zon_f = @import("build.zig.zon");
    std.debug.print("{s}\n", .{zon_f});
}
