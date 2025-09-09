const std = @import("std");
const Io = std.Io;
const fs = std.fs;
const Allocator = std.mem.Allocator;
const fmt = std.fmt;

const zli = @import("zli");

const update = @import("update.zig");
const version = @import("version.zig");

pub fn build(writer: *Io.Writer, allocator: Allocator) !*zli.Command {
    const root = try zli.Command.init(writer, allocator, .{
        .name = "cm",
        .description = "Cumul: A utility to cumulate all files into one for LLMs",
        .version = std.SemanticVersion.parse("0.1.6") catch unreachable,
    }, run);

    try root.addCommands(&.{
        try update.register(writer, allocator),
        try version.register(writer, allocator),
    });

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

    try root.addFlag(exclude_flag);
    try root.addFlag(prefix_flag);

    const arg = zli.PositionalArg{
        .name = "directory",
        .required = false,
        .description = "The directory to scan",
    };

    try root.addPositionalArg(arg);

    return root;
}

fn run(ctx: zli.CommandContext) !void {
    const writer = ctx.writer;
    const allocator = ctx.allocator;
    const prefix = ctx.flag("prefix", []const u8);
    const exclude = ctx.flag("exclude", []const u8);
    const pos_args = ctx.positional_args;

    // Process given path
    var path: []const u8 = undefined;
    if (pos_args.len == 0) {
        path = ".";
    } else {
        path = pos_args[0];
    }

    const cwd = fs.cwd();

    // Get the real path and base directory name
    var obuf: [fs.max_path_bytes]u8 = undefined;
    const real_path = cwd.realpath(path, &obuf) catch |err| {
        if (err == error.FileNotFound) try writer.print("Path '{s}' not found.\n", .{path});

        return;
    };
    const base_name = fs.path.basename(real_path);

    // Walk the directories of the path provided
    var dir = cwd.openDir(path, .{ .iterate = true }) catch |err| {
        if (err == error.FileNotFound) try writer.print("Path '{s}' not found.\n", .{path});
        return;
    };
    defer dir.close();
    var it = try dir.walk(allocator);
    defer it.deinit();

    // Build the final filename and create the file
    const cumul_filename = if (prefix.len > 0) try fmt.allocPrint(allocator, "{s}-{s}-cumul.txt", .{ prefix, base_name }) else try fmt.allocPrint(allocator, "{s}-cumul.txt", .{base_name});
    defer allocator.free(cumul_filename);

    const cumul_file = try fs.cwd().createFile(cumul_filename, .{});
    defer cumul_file.close();

    var num_files: u32 = 0;

    var is_gitignore: bool = false;
    var gitignoreFile: ?fs.File = null;

    if (cwd.openFile(".gitignore", .{ .mode = .read_only })) |file| {
        gitignoreFile = file;
        is_gitignore = true;
    } else |err| switch (err) {
        error.FileNotFound => {
            is_gitignore = false;
        },
        else => return err,
    }
    defer if (gitignoreFile) |f| f.close();

    var list = try allocator.alloc([]const u8, 0);
    if (is_gitignore) {
        list = try getSkippablefilesFromGitIgnore(allocator, gitignoreFile.?);
    }
    defer {
        for (list) |l| allocator.free(l);
        allocator.free(list);
    }

    var excl_list = std.ArrayList([]const u8).empty;
    defer excl_list.deinit(allocator);

    if (exclude.len > 0) {
        var excl_it = std.mem.splitScalar(u8, exclude, ',');
        while (excl_it.next()) |e| {
            try excl_list.append(allocator, e);
        }
    }

    outer: while (try it.next()) |e| {
        if (e.kind != .file) continue;
        if (std.mem.startsWith(u8, e.path, ".")) continue; // any dot files
        if (std.mem.endsWith(u8, e.path, "-cumul.txt")) continue;
        if (std.mem.endsWith(u8, e.path, ".exe")) continue;
        if (std.mem.endsWith(u8, e.path, ".ico")) continue;
        if (std.mem.endsWith(u8, e.path, ".png")) continue;
        if (std.mem.endsWith(u8, e.path, ".jpg")) continue;
        if (std.mem.endsWith(u8, e.path, ".jpeg")) continue;
        if (std.mem.endsWith(u8, e.path, ".woff")) continue;
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
            try writer.print("Skipping {s}: {s}\n", .{ e.path, @errorName(err) });
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
        try cumul_file.writeAll("-------- FILE: ");
        try cumul_file.writeAll(e.path);
        try cumul_file.writeAll(" --------\n");
        try cumul_file.writeAll(content);
        try cumul_file.writeAll("\n");

        num_files += 1;
    }

    const cumul_file_final = try cwd.openFile(cumul_filename, .{ .mode = .read_only });
    defer cumul_file_final.close();

    const stat = try cumul_file_final.stat();
    const byte_size = stat.size;
    const file_size = try formatSizeToHumanReadable(allocator, byte_size);
    defer allocator.free(file_size);

    const num_lines = try getNumberOfLinesInFile(allocator, &cumul_file_final, byte_size);

    try writer.print(
        \\Number of files cumulated: {d}
        \\Number of lines: {d}
        \\Final file size: {s}
        \\Written to: {s}
        \\
    , .{ num_files, num_lines, file_size, cumul_filename });
}

/// Need to free memory after
fn formatSizeToHumanReadable(allocator: Allocator, size: u64) ![]u8 {
    if (size < 1024) {
        return fmt.allocPrint(allocator, "{d} bytes", .{size});
    } else if (size < 1024 * 1024) {
        const size_kb = @as(f64, @floatFromInt(size)) / 1024.0;
        return fmt.allocPrint(allocator, "{d:.2} KB", .{size_kb});
    } else if (size < 1024 * 1024 * 1024) {
        const size_mb = @as(f64, @floatFromInt(size)) / (1024.0 * 1024.0);
        return fmt.allocPrint(allocator, "{d:.2} MB", .{size_mb});
    } else {
        const size_gb = @as(f64, @floatFromInt(size)) / (1024.0 * 1024.0 * 1024.0);
        return fmt.allocPrint(allocator, "{d:.2} GB", .{size_gb});
    }
}

/// No Need to free memory after
fn getNumberOfLinesInFile(allocator: Allocator, file: *const fs.File, size: u64) !u32 {
    const content = try allocator.alloc(u8, size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    var it = std.mem.splitScalar(u8, content, '\n');
    var num_lines: u32 = 0;

    while (it.next()) |_| {
        num_lines += 1;
    }

    return num_lines;
}

/// Need to free memory after
fn getSkippablefilesFromGitIgnore(allocator: Allocator, file: fs.File) ![][]const u8 {
    var array = std.ArrayList([]const u8).empty;
    errdefer array.deinit(allocator);

    const stat = try file.stat();

    const content = try allocator.alloc(u8, stat.size);
    defer allocator.free(content);
    _ = try file.readAll(content);

    var it = std.mem.splitScalar(u8, content, '\n');
    while (it.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t");
        if (trimmed.len == 0 or std.mem.startsWith(u8, trimmed, "#")) continue;
        try array.append(allocator, try allocator.dupe(u8, trimmed));
    }

    return array.toOwnedSlice(allocator);
}
