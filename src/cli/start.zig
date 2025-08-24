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
    var spinner = ctx.spinner;
    spinner.updateStyle(.{ .frames = Spinner.SpinnerStyles.earth, .refresh_rate_ms = 150 }); // many styles available

    // Step 1
    try spinner.start("Step 1", .{}); // New line
    std.Thread.sleep(2000 * std.time.ns_per_ms);

    try spinner.succeed("Step 1 success", .{}); // each start must be closed with succeed, fail, info, preserve

    spinner.updateStyle(.{ .frames = Spinner.SpinnerStyles.weather, .refresh_rate_ms = 150 }); // many styles available

    // Step 2
    try spinner.start("Step 2", .{}); // New line
    std.Thread.sleep(3000 * std.time.ns_per_ms);

    spinner.updateStyle(.{ .frames = Spinner.SpinnerStyles.dots, .refresh_rate_ms = 150 }); // many styles available
    try spinner.updateMessage("Step 2: Calculating things...", .{}); // update the text of step 2

    const i = work(); // do some work

    try spinner.info("Step 2 info: {d}", .{i});

    // Step 3
    try spinner.start("Step 3", .{});
    std.Thread.sleep(2000 * std.time.ns_per_ms);

    try spinner.fail("Step 3 fail", .{});

    try spinner.print("Finish\n", .{});
}

fn work() u128 {
    var i: u128 = 1;
    for (0..100000000) |t| {
        i = (t + i);
    }

    return i;
}
