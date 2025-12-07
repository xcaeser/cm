const std = @import("std");
const Io = std.Io;

const zli = @import("zli");

pub fn register(io: Io, writer: *Io.Writer, reader: *Io.Reader, allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(io, writer, reader, allocator, .{
        .name = "version",
        .description = "Show CLI version",
    }, show);
}

fn show(ctx: zli.CommandContext) !void {
    try ctx.root.printVersion();
}
