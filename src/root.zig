const std = @import("std");
pub const cli = @import("cli/root.zig");

comptime {
    std.testing.refAllDecls(@This());
}
