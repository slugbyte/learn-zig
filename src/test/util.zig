const std = @import("std");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const SourceLocation = std.builtin.SourceLocation;

const DISBLE_LOG = false;

var TEST_NAME: []const u8 = "unknown";
var TOTAL_ASSERT_ACC: u64 = 0;
var TEST_ASSERT_ACC: u64 = 0;
var TEST_COUNT_ACC: u64 = 0;

pub const color_red = "\x1b[31m";
pub const color_green = "\x1b[32m";
pub const color_yellow = "\x1b[33m";
pub const color_blue = "\x1b[34m";
pub const color_pink = "\x1b[35m";
pub const color_aqua = "\x1b[36m";
pub const color_light_grey = "\x1b[37m";
pub const color_dark_grey = "\x1b[38m";
pub const color_reset = "\x1b[0m";

pub const ASSET_DATA_JSON_NOTE_ITEM = @embedFile("./asset/json/note_item.json");
pub const ASSET_DATA_JSON_NOTE_LIST = @embedFile("./asset/json/note_list.json");

pub fn xxd(comptime fmt: []const u8, args: anytype) void {
    if (DISBLE_LOG) {
        return;
    }
    std.debug.print(fmt, args);
}

pub fn xxp(comptime fmt: []const u8, args: anytype) void {
    if (DISBLE_LOG) {
        return;
    }
    const msg = std.fmt.allocPrint(std.testing.allocator, fmt, args) catch return;
    defer std.testing.allocator.free(msg);
    std.debug.print("{s}\n", .{msg});
}

pub fn xxpRed(comptime fmt: []const u8, args: anytype) void {
    if (DISBLE_LOG) {
        return;
    }
    const msg = std.fmt.allocPrint(std.testing.allocator, fmt, args) catch return;
    defer std.testing.allocator.free(msg);
    std.debug.print("{s}{s}{s}\n", .{ color_red, msg, color_reset });
}

pub fn xxxxxxxxxxxxxxxHEADER(comptime text: []const u8) void {
    setTestName(text);
    if (DISBLE_LOG) {
        return;
    }
    const msg = std.fmt.allocPrint(std.testing.allocator, " {s}{s}{s}", .{ color_blue, text, color_reset }) catch return;
    defer std.testing.allocator.free(msg);
    xxp("\n[{s}] {s:->55} ----", .{ TEST_NAME, msg });
}

pub fn xxl(comptime text: []const u8) void {
    if (DISBLE_LOG) {
        return;
    }
    xxp("{s}", .{text});
}

pub fn xxn() void {
    if (DISBLE_LOG) {
        return;
    }
    std.debug.print("\n", .{});
}

pub inline fn eql(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn setTestName(name: []const u8) void {
    TEST_ASSERT_ACC = 0;
    TEST_COUNT_ACC += 1;
    TEST_NAME = name;
}

pub fn reportTest() void {
    const assert_msg = std.fmt.allocPrint(std.testing.allocator, " {s}ASSERT PASS {d}{s}", .{ color_green, TEST_ASSERT_ACC, color_reset }) catch return;
    defer std.testing.allocator.free(assert_msg);
    xxp("\n[{s}] {s:->55} ----", .{ "report", assert_msg });

    const test_msg = std.fmt.allocPrint(std.testing.allocator, " {s}TEST PASS {d}{s}", .{ color_green, TEST_COUNT_ACC, color_reset }) catch return;
    defer std.testing.allocator.free(test_msg);
    xxp("[{s}] {s:->55} ----", .{ "report", test_msg });

    const total_msg = std.fmt.allocPrint(std.testing.allocator, " {s}TOTAL ASSSERT {d}{s}", .{ color_green, TOTAL_ASSERT_ACC, color_reset }) catch return;
    defer std.testing.allocator.free(total_msg);
    xxp("[{s}] {s:->55} ----", .{ "report", total_msg });
}

fn incAssertAcc() void {
    TOTAL_ASSERT_ACC += 1;
    TEST_ASSERT_ACC += 1;
}

pub fn expect(test_kind: []const u8, msg: []const u8, is_ok: bool) !void {
    incAssertAcc();
    if (is_ok) {
        xxp("[{s}] {s: >7} success: {s}", .{ TEST_NAME, test_kind, msg });
        return;
    }
    xxpRed("[{s}] {s: >7} failed: {s}", .{ TEST_NAME, test_kind, msg });

    if (!is_ok) {
        return error.HelloZigTestFailed;
    }
}

pub fn isEql(msg: []const u8, actual: anytype, expected: anytype) !void {
    incAssertAcc();
    const is_ok = expected == actual;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} is {any}\n", .{ TEST_NAME, "isEql", msg, expected });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} (expected {any} -> found {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, expected, actual, color_reset });
        return error.HelloZigTestFailed;
    }
}

pub fn isLT(msg: []const u8, actual: anytype, moreThan: anytype) !void {
    incAssertAcc();
    const is_ok = actual < moreThan;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} ({any} < {any})\n", .{ TEST_NAME, "isEql", msg, actual, moreThan });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} ({any} is not < {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, actual, moreThan, color_reset });
        return error.HelloZigTestFailed;
    }
}

pub fn isGT(msg: []const u8, actual: anytype, lessThan: anytype) !void {
    incAssertAcc();
    const is_ok = actual > lessThan;
    if (is_ok) {
        xxd("[{s}] {s: >7} success: {s} ({any} > {any})\n", .{ TEST_NAME, "isEql", msg, actual, lessThan });
        return;
    } else {
        xxd("{s}[{s}] {s: >7} failed: {s} ({any} is not > {any}){s}\n", .{ color_red, TEST_NAME, "isEql", msg, actual, lessThan, color_reset });
        return error.geetCodeTestFailed;
    }
}

pub fn isOk(msg: []const u8, is_ok: bool) !void {
    return expect("isOk", msg, is_ok);
}

pub fn isNotOk(msg: []const u8, is_ok: bool) !void {
    return expect("isNotOk", msg, !is_ok);
}

pub fn isOkFmt(comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(std.testing.allocator, fmt, args);
    defer std.testing.allocator.free(msg);
    return expect("isOkFmt", msg, is_ok);
}

pub fn isNotOkFmt(comptime fmt: []const u8, args: anytype, is_ok: bool) !void {
    const msg = try std.fmt.allocPrint(std.testing.allocator, fmt, args);
    defer std.testing.allocator.free(msg);
    return expect("isNotOkFmt", msg, !is_ok);
}

/// caller owns result
///
/// NOTE: this is a stupid idea, but is kina nice for test code
/// i dont thing it wodul be a good idea to do this kind thing in production
pub fn getPathRelativeToSrc(allocator: Allocator, src: SourceLocation, path: []const u8) ![]const u8 {
    var string_builder = ArrayList(u8).init(allocator);
    try string_builder.appendSlice(std.fs.path.dirname(src.file).?);
    try string_builder.appendSlice("/");
    try string_builder.appendSlice(path);
    return string_builder.toOwnedSlice();
}
