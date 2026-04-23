const std = @import("std");
const Io = std.Io;

const zli = @import("zli");

pub fn register(init_opts: zli.InitOptions) !*zli.Command {
    return zli.Command.init(init_opts, .{
        .name = "version",
        .description = "Show CLI version",
    }, show);
}

fn show(ctx: zli.CommandContext) !void {
    try ctx.root.printVersion();
}
