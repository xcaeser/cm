const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const fmt = std.fmt;
const builtin = @import("builtin");

const zli = @import("zli");

const utils = @import("../lib/utils.zig");
const update = @import("update.zig");
const version = @import("version.zig");

const exclude_flag = zli.Flag{
    .name = "exclude",
    .shortcut = "e",
    .description = "list of files and extenstion separated by a comma. ex: .md,.ico,src/cli/root.zig,LICENSE etc...",
    .type = .String,
    .default_value = .{ .String = "" },
};

const prefix_flag = zli.Flag{
    .name = "prefix",
    .shortcut = "p",
    .description = "prefix to the filename generated",
    .type = .String,
    .default_value = .{ .String = "" },
};

const arg = zli.PositionalArg{
    .name = "directory",
    .required = false,
    .description = "The directory to scan",
};

/// cli entrypoint
pub fn build(writer: *Io.Writer, allocator: Allocator) !*zli.Command {
    const root = try zli.Command.init(writer, allocator, .{
        .name = "cm",
        .description = "Cumul: A utility to cumulate all files into one for LLMs",
        .version = std.SemanticVersion.parse("0.1.9") catch unreachable,
    }, run);

    if (builtin.os.tag != .windows) try root.addCommand(try update.register(writer, allocator));
    try root.addCommand(try version.register(writer, allocator));

    try root.addFlag(exclude_flag);
    try root.addFlag(prefix_flag);

    try root.addPositionalArg(arg);

    return root;
}

fn run(ctx: zli.CommandContext) !void {
    const spinner = ctx.spinner;
    const allocator = ctx.allocator;

    const prefix = ctx.flag("prefix", []const u8);
    const user_exclude_list = ctx.flag("exclude", []const u8);
    const pos_args = ctx.positional_args;

    const cwd = fs.cwd();

    var is_gitignore: bool = false;
    var gitignore_file: ?fs.File = null;

    // Process given path
    var path: []const u8 = ".";
    if (pos_args.len > 0) {
        path = pos_args[0];
    }

    try spinner.start("Cumul is working...", .{});

    // read .gitignore file if it exists
    if (cwd.openFile(".gitignore", .{ .mode = .read_only })) |file| {
        gitignore_file = file;
        is_gitignore = true;
    } else |err| switch (err) {
        error.FileNotFound => {
            is_gitignore = false;
        },
        else => return err,
    }
    defer if (gitignore_file) |f| f.close();

    var list = try allocator.alloc([]const u8, 0);
    if (is_gitignore) {
        list = try utils.getSkippablefilesFromGitIgnore(allocator, gitignore_file.?);
    }
    defer {
        for (list) |l| allocator.free(l);
        allocator.free(list);
    }

    var excl_list = std.ArrayList([]const u8).empty;
    defer excl_list.deinit(allocator);

    try excl_list.appendSlice(allocator, &.{
        "-cumul.txt",
        ".exe",
        ".ico",
        ".png",
        ".jpg",
        ".jpeg",
        ".woff",
        ".tmp",
        ".bak",
        ".o",
        ".obj",
        ".gif",
        ".svg",
    });

    if (user_exclude_list.len > 0) {
        var excl_it = std.mem.splitScalar(u8, user_exclude_list, ',');
        while (excl_it.next()) |e| {
            try excl_list.append(allocator, e);
        }
    }

    // Get the real path and base directory name
    var obuf: [fs.max_path_bytes]u8 = undefined;
    const real_path = cwd.realpath(path, &obuf) catch |err| {
        if (err == error.FileNotFound) try spinner.fail("Path '{s}' not found.\n", .{path});

        return;
    };
    const base_name = fs.path.basename(real_path);

    // Walk the directories of the path provided
    var dir = cwd.openDir(path, .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) try spinner.fail("Path '{s}' not found.\n", .{path});
        return;
    };
    defer dir.close();
    var dir_it = try dir.walk(allocator);
    defer dir_it.deinit();

    // Build the final filename and create the file
    const cumul_filename = if (prefix.len > 0) try fmt.allocPrint(allocator, "{s}-{s}-cumul.txt", .{ prefix, base_name }) else try fmt.allocPrint(allocator, "{s}-cumul.txt", .{base_name});
    defer allocator.free(cumul_filename);

    const cumul_file = try cwd.createFile(cumul_filename, .{ .read = true });
    defer cumul_file.close();

    var cumul_file_writer = cumul_file.writer(&.{});
    var writer = &cumul_file_writer.interface;

    var num_files: u18 = 0;

    outer: while (try dir_it.next()) |e| {
        if (e.kind != .file) continue;
        if (std.mem.startsWith(u8, e.path, ".")) continue; // any dot files

        for (excl_list.items) |ex| {
            if (std.mem.endsWith(u8, e.path, ex)) continue :outer;
        }

        // doesn't handle src/*.zig pattern... etc.. might pull in fnmatch or glob.h
        if (is_gitignore) {
            for (list) |pattern| {
                const star_index = std.mem.indexOf(u8, pattern, "*");
                if (star_index) |i| {
                    if (i == 0) {
                        // Handle *.ext patterns
                        const suffix = pattern[i + 1 ..];
                        if (std.mem.endsWith(u8, e.basename, suffix)) continue :outer;
                    } else {
                        // Handle prefix* patterns
                        const prfx = pattern[0..i];
                        if (std.mem.startsWith(u8, e.basename, prfx)) continue :outer;
                    }
                } else {
                    // Handle exact or directory patterns
                    if (std.mem.indexOf(u8, e.path, pattern) != null) continue :outer;
                }
            }
        }

        // Open the file and read its content
        var f = dir.openFile(e.path, .{ .mode = .read_only }) catch |err| {
            try spinner.print("Skipping {s}: {s}\n", .{ e.path, @errorName(err) });
            continue;
        };
        defer f.close();

        const stat = try f.stat();

        // Read file contents safely
        const rbuf = try allocator.alloc(u8, stat.size);
        defer allocator.free(rbuf);
        _ = try f.readAll(rbuf);
        if (rbuf.len == 0) continue;

        const content = std.mem.trim(u8, rbuf, " \n");

        // Write to the new file

        try writer.writeAll("-------- FILE: ");
        try writer.writeAll(e.path);
        try writer.writeAll(" --------\n");
        try writer.writeAll(content);
        try writer.writeAll("\n");

        num_files += 1;
    }

    try writer.flush();

    const stat = try cumul_file.stat();
    const byte_size = stat.size;
    const file_size = try utils.formatSizeToHumanReadable(allocator, byte_size);
    defer allocator.free(file_size);

    const num_lines = try utils.getNumberOfLinesInFile(allocator, &cumul_file, byte_size);

    try spinner.succeed(
        \\Done.
        \\
        \\------ Cumul Summary ------
        \\- Number of files cumulated: {d}
        \\- Number of lines: {d}
        \\- Final file size: {s}
        \\- Written to: {s}
        \\---------------------------
        \\
    , .{ num_files, num_lines, file_size, cumul_filename });
}
