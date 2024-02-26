const std = @import("std");

var test_name: []const u8 = "unknown";

pub inline fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn setTestName(name: []const u8) void {
    std.debug.print("\n", .{});
    test_name = name;
}

pub fn expect(test_kind: []const u8, msg: []const u8, is_ok: bool) !void {
    if (is_ok) {
        std.debug.print("[{s}] {s: >7} succes: {s}\n", .{ test_name, test_kind, msg });
        return;
    }
    std.debug.print("[{s}] {s: >7} failed: {s}\n", .{ test_name, test_kind, msg });

    if (!is_ok) {
        return error.NeetCodeTestFailed;
    }
}

pub fn isOk(msg: []const u8, is_ok: bool) !void {
    return expect("isOk", msg, is_ok);
}

pub fn isNotOk(msg: []const u8, is_ok: bool) !void {
    return expect("isNotOk", msg, !is_ok);
}

pub fn isOkFmt(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(msg);
    return expect("isOkFmt", msg, is_ok);
}

pub fn isNotOkFmt(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(msg);
    return expect("isNotOkFmt", msg, !is_ok);
}
