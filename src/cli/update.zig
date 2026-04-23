const std = @import("std");
const Allocator = std.mem.Allocator;
const Io = std.Io;
const http = std.http;
const json = std.json;
const fmt = std.fmt;
const fs = std.fs;
const builtin = @import("builtin");

const zli = @import("zli");

pub fn register(init_opts: zli.InitOptions) !*zli.Command {
    return zli.Command.init(
        init_opts,
        .{
            .name = "update",
            .description = "Update cm to the latest version",
        },
        run,
    );
}

fn run(ctx: zli.CommandContext) !void {
    const spinner = ctx.spinner;
    const allocator = ctx.allocator;
    const io = ctx.io;

    var client = http.Client{ .io = ctx.io, .allocator = allocator };
    defer client.deinit();

    // ---- Init values
    const repo = "xcaeser/cm";
    const download_binary_name = "cm-" ++ @tagName(builtin.cpu.arch) ++ "-" ++ @tagName(builtin.os.tag);
    const download_filename = "cm.tar.gz";
    const download_url = try fmt.allocPrint(allocator, "https://github.com/{s}/releases/latest/download/{s}.tar.gz", .{ repo, download_binary_name });
    defer allocator.free(download_url);
    const default_install_path = "/usr/local/bin";
    const final_binary_name = "cm";

    // ---- Get latest version
    try spinner.start("Getting current installed version...", .{});

    const installed_version = ctx.root.cmd_options.version.?;
    try spinner.info("Installed version: {f}", .{installed_version});

    const github_version = try getLatestVersion(&ctx, &client, repo);
    try spinner.info("Latest version: {f}", .{github_version});

    // ---- Compare versions

    switch (installed_version.order(github_version)) {
        .gt, .eq => {
            try spinner.start("", .{});
            try spinner.succeed("Cumul is up to date!", .{});
            return;
        },
        .lt => {
            try spinner.start("", .{});
            if (std.os.linux.geteuid() != 0) {
                try spinner.fail(
                    \\Requires root privileges to install.
                    \\
                    \\→ Consider using `sudo`
                , .{});
                return;
            }

            // ---- Download info
            try spinner.info(
                \\Binary to download: {s}
                \\  Link: {s}
            , .{ download_binary_name, download_url });

            // ---- Create tmp directory
            var temp_dir = try TempDir.init(io, allocator);
            defer temp_dir.deinit();

            // ---- Start download
            const download_file = try downloadFile(
                &ctx,
                io,
                &client,
                download_filename,
                download_url,
                &temp_dir,
            );
            defer download_file.close(io);

            // ---- extract file in tmp dir
            try extractFileToDir(&ctx, download_file, temp_dir.dir);

            // ---- Install binary in /usr/local/bin
            const binary_tmp_path = try fmt.allocPrint(allocator, "{s}/{s}", .{ temp_dir.path, final_binary_name });
            defer allocator.free(binary_tmp_path);

            try installBinary(
                &ctx,
                temp_dir.dir,
                binary_tmp_path,
                default_install_path,
                final_binary_name,
            );
        },
    }
}

const Github_JSON_Response = struct {
    tag_name: []u8,
};

const TempDir = struct {
    path: []const u8,
    dir: Io.Dir,
    allocator: Allocator,
    io: Io,

    const Self = @This();

    pub fn init(io: Io, allocator: Allocator) !Self {
        const timestamp = std.Io.Clock.Timestamp.now(io, .real);
        var rand = std.Random.DefaultPrng.init(@intCast(timestamp.raw.toMilliseconds()));
        const rng = rand.random();

        var random_bytes: [4]u8 = undefined;
        rng.bytes(&random_bytes);

        const random_string = fmt.bytesToHex(&random_bytes, .lower);
        const temp_path = try std.mem.concat(allocator, u8, &.{
            "/tmp/tmp.",
            &random_string,
        });

        const temp_dir = try Io.Dir.cwd().createDirPathOpen(io, temp_path, .{ .open_options = .{ .iterate = true } });

        return .{
            .path = temp_path,
            .dir = temp_dir,
            .allocator = allocator,
            .io = io,
        };
    }

    pub fn deinit(self: *Self) void {
        self.dir.close(self.io);
        Io.Dir.cwd().deleteTree(self.io, self.path) catch {};
        self.allocator.free(self.path);
    }
};

fn getLatestVersion(ctx: *const zli.CommandContext, client: *http.Client, repo: []const u8) !std.SemanticVersion {
    const spinner = ctx.spinner;
    const allocator = ctx.allocator;

    try spinner.start("Getting latest online version...", .{});

    const api_url = try fmt.allocPrint(allocator, "https://api.github.com/repos/{s}/releases/latest", .{repo});
    defer allocator.free(api_url);

    var allocating_writer = Io.Writer.Allocating.init(allocator);
    defer allocating_writer.deinit();

    _ = try client.fetch(.{
        .response_writer = &allocating_writer.writer,
        .location = .{ .url = api_url },
    });

    const data = allocating_writer.written();

    const parsed = try json.parseFromSlice(Github_JSON_Response, allocator, data, .{
        .ignore_unknown_fields = true,
        .parse_numbers = false,
    });
    defer parsed.deinit();

    const root = parsed.value;

    const github_version_str = root.tag_name[1..];
    const github_version = std.SemanticVersion.parse(github_version_str) catch unreachable;
    return github_version;
}

fn downloadFile(ctx: *const zli.CommandContext, io: Io, client: *http.Client, download_filename: []const u8, download_url: []const u8, temp_dir: *TempDir) !Io.File {
    const spinner = ctx.spinner;
    const allocator = ctx.allocator;

    spinner.updateStyle(.{ .frames = zli.SpinnerStyles.earth });
    try spinner.start("Downloading file...", .{});

    const download_file_path = try fmt.allocPrint(allocator, "{s}/{s}", .{ temp_dir.path, download_filename });
    defer allocator.free(download_file_path);

    const download_file = try temp_dir.dir.createFile(io, download_filename, .{ .read = true });
    errdefer download_file.close(io);

    var download_file_writer = download_file.writer(io, &.{});
    _ = try client.fetch(.{
        .response_writer = &download_file_writer.interface,
        .location = .{ .url = download_url },
    });

    try spinner.succeed("Download successful", .{});

    return download_file;
}

fn extractFileToDir(ctx: *const zli.CommandContext, file: Io.File, out_dir: Io.Dir) !void {
    const spinner = ctx.spinner;

    spinner.updateStyle(.{ .frames = zli.SpinnerStyles.dots });
    try spinner.start("Extracting file...", .{});

    var fbuf: [4096]u8 = undefined;
    var file_reader = file.readerStreaming(ctx.io, &fbuf);

    var buf: [std.compress.flate.max_window_len]u8 = undefined;
    var decompress = std.compress.flate.Decompress.init(
        &file_reader.interface,
        .gzip,
        &buf,
    );

    try std.tar.pipeToFileSystem(
        ctx.io,
        out_dir,
        &decompress.reader,
        .{},
    );
}

fn installBinary(ctx: *const zli.CommandContext, source_dir: Io.Dir, source_path: []const u8, install_path: []const u8, binary_name: []const u8) !void {
    const spinner = ctx.spinner;

    try spinner.start("Installing to {s}...", .{install_path});

    var install_dir = try Io.Dir.cwd().createDirPathOpen(ctx.io, install_path, .{ .open_options = .{
        .access_sub_paths = true,
    } });
    defer install_dir.close(ctx.io);

    try source_dir.copyFile(source_path, install_dir, binary_name, ctx.io, .{
        .permissions = .fromMode(0o755),
    });

    try spinner.succeed(
        \\Successfully installed! 
        \\
        \\
        \\    Enjoy cumul (cm)
        \\
        \\    → Run cm -h or cm --help to get started
        \\
        \\
    , .{});
}
