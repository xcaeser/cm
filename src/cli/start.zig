const std = @import("std");
const Writer = std.Io.Writer;

const Progress = std.Progress;

const zli = @import("zli");
const cumul = @import("cumul");

const Spinner = zli.Spinner;

pub fn register(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    return zli.Command.init(writer, allocator, .{
        .name = "start",
        .shortcut = "s",
        .description = "testing",
    }, run);
}

fn run(ctx: zli.CommandContext) !void {
    // const writer = ctx.writer;

    var spinner = ctx.spinner;

    try spinner.start("Step 1", .{});
    std.Thread.sleep(2000 * std.time.ns_per_ms);

    try spinner.succeed("Step 1 success", .{});

    spinner.updateStyle(.{ .frames = Spinner.SpinnerStyles.none, .refresh_rate_ms = 80 });
    try spinner.start("Step 2", .{});
    std.Thread.sleep(2000 * std.time.ns_per_ms);

    std.Thread.sleep(1000 * std.time.ns_per_ms);
    try spinner.updateMessage("Calculating things", .{});
    const i = work();

    try spinner.info("Step 2 info: {d}", .{i});

    try spinner.start("Step 3", .{});
    std.Thread.sleep(2000 * std.time.ns_per_ms);
    try spinner.fail("Step 3 fail", .{});

    try spinner.print("ehe\n", .{});
}

fn work() u128 {
    var i: u128 = 1;
    for (0..100000000) |t| {
        i = (t + i);
    }

    return i;
}
