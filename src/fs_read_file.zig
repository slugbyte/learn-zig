const std = @import("std");
const t = std.testing;
const util = @import("./util.zig");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const U8Array = ArrayList(u8);
const U8ArrayLineList = ArrayList(U8Array);
const U8SliceLineList = ArrayList([]u8);

const JSON_FILE_PATH = "./src/res/json/note.json";

pub fn readFileToU8Slice(file_path: []const u8, allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_len = try file.getEndPos();
    const result = try allocator.alloc(u8, file_len);
    errdefer allocator.free(result);
    const reader = file.reader();
    const byte_count = try reader.readAll(result);
    if (byte_count != file_len) {
        return error.ReadAllFailed;
    }
    return result;
}

test "readFileToU8Slice" {
    util.setTestName("readFileToU8Slice");
    const text = try readFileToU8Slice(JSON_FILE_PATH, t.allocator);
    defer t.allocator.free(text);
    try util.isOk("slice should be correct", util.eql(util.JSON_NOTE_FILE_CONTENT, text));
}

pub fn readFileToU8Array(file_path: []const u8, allocator: Allocator) !U8Array {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const file_len = try file.getEndPos();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var buf = try allocator.alloc(u8, file_len);
    const result = U8Array.fromOwnedSlice(allocator, buf[0..]);

    const byte_count = try reader.readAll(buf);
    if (byte_count != file_len) {
        return error.ReadAllFailed;
    }
    return result;
}

test "readFileToU8Array" {
    util.setTestName("readFileToU8Array");
    const string = try readFileToU8Array(JSON_FILE_PATH, t.allocator);
    defer string.deinit();
    try util.isOk("string.items should be correct", util.eql(string.items, util.JSON_NOTE_FILE_CONTENT));
}

pub fn TextBuffer(comptime T: type) type {
    return struct {
        const Self = @This();
        data: []T,
        allocator: Allocator,
        pub fn init(size: usize, allocator: Allocator) !Self {
            const data = try allocator.alloc(T, size);
            return .{
                .data = data,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *const Self) void {
            self.allocator.free(self.data);
        }
    };
}

pub fn readFileToTextBuffer(file_path: []const u8, allocator: Allocator) !TextBuffer(u8) {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const file_len = try file.getEndPos();
    var result = try TextBuffer(u8).init(file_len, allocator);
    errdefer result.deinit();

    const reader = file.reader();
    const byte_count = try reader.readAll(result.data);

    if (byte_count != file_len) {
        return error.ReadAllFailed;
    }

    return result;
}

test "readFileToTextBuffer" {
    util.setTestName("readFileToTextBuffer");
    const buffer = try readFileToTextBuffer(JSON_FILE_PATH, t.allocator);
    defer buffer.deinit();

    try util.isOk("TextBuffer.data should be correct", util.eql(util.JSON_NOTE_FILE_CONTENT, buffer.data));
}
