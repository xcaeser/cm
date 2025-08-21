const std = @import("std");
pub const glob = @import("glob.zig");

comptime {
    std.testing.refAllDecls(@This());
}
