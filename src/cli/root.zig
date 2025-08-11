const std = @import("std");
const Writer = std.Io.Writer;
const fs = std.fs;

const cumul = @import("cumul");
const zli = cumul.zli;

const version = @import("version.zig");

pub fn build(writer: *Writer, allocator: std.mem.Allocator) !*zli.Command {
    const root = try zli.Command.init(writer, allocator, .{
        .name = "cumul",
        .description = "A utility to cumulate all files into one for LLMs",
        .version = std.SemanticVersion.parse("1.0.0") catch unreachable,
    }, run);

    try root.addCommand(try version.register(writer, allocator));

    const arg = zli.PositionalArg{
        .name = "directory",
        .required = false,
        .description = "The directory to scan",
    };

    try root.addPositionalArg(arg);

    return root;
}

fn run(ctx: zli.CommandContext) !void {
    const pos_args = ctx.positional_args;

    // Process given path
    var path: []const u8 = undefined;
    if (pos_args.len == 0) {
        path = ".";
    } else {
        path = pos_args[0];
    }

    const writer = ctx.command.writer;
    const allocator = ctx.allocator;

    const cwd = fs.cwd();

    // Get the real path and base directory name
    var obuf: [fs.max_path_bytes]u8 = undefined;
    const real_path = try cwd.realpath(path, &obuf);
    const base_name = fs.path.basename(real_path);

    // Walk the directories of the path provided
    var dir = try cwd.openDir(path, .{ .iterate = true });
    defer dir.close();
    var it = try dir.walk(allocator);
    defer it.deinit();

    // Build the final filename and create the file
    const cumul_filename = try std.fmt.allocPrint(allocator, "{s}-cumul.txt", .{base_name});
    defer allocator.free(cumul_filename);

    const new_file = try fs.cwd().createFile(cumul_filename, .{});
    defer new_file.close();

    while (try it.next()) |e| {
        // Skip any unwanted files/folders
        if (std.mem.startsWith(u8, e.path, ".")) continue; // any dot files
        if (std.mem.startsWith(u8, e.path, "zig-out")) continue;
        if (std.mem.eql(u8, e.basename, cumul_filename)) continue;

        switch (e.kind) {
            .file => {

                // Open the file and read its content
                var f = dir.openFile(e.path, .{ .mode = .read_only }) catch |err| {
                    try writer.print("Skipping {s}: {s}\n", .{ e.path, @errorName(err) });
                    continue;
                };
                defer f.close();

                // Read file contents safely
                const rbuf = try f.readToEndAlloc(allocator, 1024 * 1024 * 10); // Max 10MB
                defer allocator.free(rbuf);
                if (rbuf.len == 0) continue;

                // Write to the new file
                try new_file.writeAll("-------- FILE: ");
                try new_file.writeAll(e.path);
                try new_file.writeAll(" --------\n");
                try new_file.writeAll(rbuf);
                try new_file.writeAll("\n");
                try writer.print("{s}  - {s}\n", .{ e.basename, e.path });
            },
            else => continue,
        }
    }
}
