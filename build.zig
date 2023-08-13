const std = @import("std");

pub fn build(b: *std.Build) void {
    _ = b.addModule("zgl", .{ .source_file = .{ .path = "zgl.zig" } });
}
