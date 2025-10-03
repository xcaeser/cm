const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const http = std.http;
const json = std.json;
const fmt = std.fmt;
const fs = std.fs;
const builtin = @import("builtin");

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
    const spinner = ctx.spinner;
    const allocator = ctx.allocator;

    try spinner.start("Getting current installed version...", .{});

    const installed_version = ctx.root.options.version.?;
    const installed_major = installed_version.major;
    const installed_minor = installed_version.minor;
    const installed_patch = installed_version.patch;
    try spinner.info("Installed version: {f}", .{installed_version});

    try spinner.start("Getting latest online version...", .{});

    const repo = "xcaeser/cm";
    const api_url = "https://api.github.com/repos/" ++ repo ++ "/releases/latest";

    var allocating_writer = Io.Writer.Allocating.init(allocator);
    defer allocating_writer.deinit();

    var client = http.Client{ .allocator = allocator };
    defer client.deinit();
    _ = try client.fetch(.{
        .response_writer = &allocating_writer.writer,
        .location = .{ .url = api_url },
    });

    const data = allocating_writer.written();

    const Github_JSON_Response = struct { tag_name: []u8 };
    const parsed = try json.parseFromSlice(Github_JSON_Response, allocator, data, .{
        .ignore_unknown_fields = true,
        .parse_numbers = false,
    });
    defer parsed.deinit();

    const root = parsed.value;

    const github_version_str = root.tag_name[1..];
    const github_version = std.SemanticVersion.parse(github_version_str) catch unreachable;

    try spinner.info("Latest version: {f}", .{github_version});

    try spinner.start("", .{});
    const github_major = github_version.major;
    const github_minor = github_version.minor;
    const github_patch = github_version.patch;

    if (installed_major >= github_major and installed_minor >= github_minor and installed_patch >= github_patch) {
        try spinner.succeed("Cumul is up to date", .{});

        // return;
    }

    try spinner.start("", .{});
    const binary_name = "cm-" ++ @tagName(builtin.cpu.arch) ++ "-" ++ @tagName(builtin.os.tag);

    const default_install_dir = "/usr/local/bin";
    _ = default_install_dir; // autofix

    // download executable
    const download_url = try fmt.allocPrint(allocator, "https://github.com/{s}/releases/latest/download/{s}.tar.gz", .{ repo, binary_name });
    defer allocator.free(download_url);

    try spinner.succeed(
        \\Binary to download: {s}
        \\  Link: {s}
    , .{ binary_name, download_url });

    // make temp dir
    try makeTempDir();
}

fn makeTempDir() !void {
    const pid = std.Thread.getCurrentId();
    var rand = std.Random.DefaultPrng.init(pid);
    var random_bytes: [4]u8 = undefined;
    rand.fill(&random_bytes);
    const random_string = fmt.bytesToHex(&random_bytes, .lower);

    const temp_path = "/tmp/tmp." ++ random_string;
    try fs.cwd().makeDir(temp_path);
    std.debug.print("Path: {s}\n", .{temp_path});

    var d = try fs.cwd().openDir(temp_path, .{ .iterate = true });
    defer d.close();
    try d.chmod(0o700);

    // try std.process.changeCurDir(temp_path);
}
