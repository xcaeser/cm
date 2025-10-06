const std = @import("std");

pub const cli = @import("cli/root.zig");
pub const utils = @import("lib/utils.zig");

comptime {
    std.testing.refAllDecls(@This());
}
