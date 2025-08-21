const std = @import("std");
const Writer = std.Io.Writer;

const zli = @import("zli");

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(writer, allocator, .{
        .name = "version",
        .shortcut = "v",
        .description = "Show CLI version",
    }, show);
}

fn show(ctx: zli.CommandContext) !void {
    try ctx.root.showVersion();
}
