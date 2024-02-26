const std = @import("std");
const t = std.testing;
const util = @import("util");

const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;
const ArrayList = std.ArrayList;
const print = std.debug.print;
const U8Array = ArrayList(u8);
const U8ArrayLineList = ArrayList(U8Array);
const U8SliceLineList = ArrayList([]u8);

const JSON_FILE = "./src/res/json/note.json";

pub fn readFileToU8Slice(file_path: []const u8, allocator: Allocator) ![]u8 {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const file_len = try file.getEndPos();
    const result = try allocator.alloc(u8, file_len);
    errdefer allocator.free(result);
    const reader = file.reader();
    const byte_count = try reader.readAll(result);
    if (byte_count != result.len) {
        return error.ReadAllFailed;
    }
    return result;
}

test "readFileToU8Slice" {
    util.setTestName("readFileToU8Slice");
    const text = try readFileToU8Slice(JSON_FILE, t.allocator);
    defer t.allocator.free(text);
    try util.isOk("Buffer.data should be correct", util.eql(util.JSON_NOTE_FILE_CONTENT, text));
}

pub fn readFileToU8Array(file_path: []const u8, allocator: Allocator) !U8Array {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    const file_len = try file.getEndPos();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var buf = try allocator.alloc(u8, file_len);
    const result = U8Array.fromOwnedSlice(allocator, buf[0..]);

    const bytes = try reader.readAll(buf);
    print("file name: {s}\n", .{file_path});
    print("byte count: {d}\n", .{bytes});
    print("content: \n", .{});
    print("{s}\n", .{buf});
    return result;
}

test "readFileToU8Array" {
    util.setTestName("readFileToU8Array");
    const string = try readFileToU8Array(JSON_FILE, t.allocator);
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

    if (byte_count != result.data.len) {
        return error.ReadAllFailed;
    }

    return result;
}

test "readFileToTextBuffer" {
    util.setTestName("readFileToTextBuffer");
    const buffer = try readFileToTextBuffer(JSON_FILE, t.allocator);
    defer buffer.deinit();

    try util.isOk("Buffer.data should be correct", util.eql(util.JSON_NOTE_FILE_CONTENT, buffer.data));
}

pub fn readFileLinesToU8BufferList(file_path: []const u8, allocator: Allocator) !U8SliceLineList {
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();
    var result = U8SliceLineList.init(allocator);
    const reader = file.reader();

    var line = ArrayList(u8).init(allocator);
    defer line.deinit();
    const line_writer = line.writer();

    while (reader.streamUntilDelimiter(line_writer, '\n', null)) {
        const buf = try allocator.dupe(u8, line.items);
        line.clearAndFree();
        try result.append(buf);
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }
    return result;
}

test "readFileLinesToU8SliceLineList" {
    util.setTestName("readFileLinesToU8SliceLineList");
    const lineU8bufList = try readFileLinesToU8BufferList(JSON_FILE, t.allocator);
    var line_iter = std.mem.splitScalar(u8, util.JSON_NOTE_FILE_CONTENT, '\n');

    for (lineU8bufList.items, 1..) |item, line_number| {
        const expected_line = line_iter.next();
        try util.isOkFmt(t.allocator, "line {d} should be {s}", .{ line_number, expected_line.? }, util.eql(item, expected_line.?));
        t.allocator.free(item);
    }

    try util.isOk("line_iter next should empty string", 0 == line_iter.next().?.len);
    try util.isOk("line iter next should be null", null == line_iter.next());
    lineU8bufList.deinit();
}

pub fn readFileLinesToU8ArrayLineList(file_path: []const u8, allocator: Allocator) !U8ArrayLineList {
    var result = U8ArrayLineList.init(allocator);
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    const reader = buf_reader.reader();

    var current_line = U8Array.init(allocator);
    const writer = current_line.writer();

    while (reader.streamUntilDelimiter(writer, '\n', null)) {
        try result.append(try current_line.clone());
        current_line.clearAndFree();
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => return err,
    }

    return result;
}

test "readFileLinesToU8ArrayLineList" {
    util.setTestName("readFileLinesToU8ArrayLineList");
    const line_list = try readFileLinesToU8ArrayLineList(JSON_FILE, t.allocator);
    var line_iter = std.mem.splitScalar(u8, util.JSON_NOTE_FILE_CONTENT, '\n');
    for (line_list.items, 1..) |item, line_number| {
        const expected_line = line_iter.next();
        try util.isOkFmt(t.allocator, "line {d} should be {s}", .{ line_number, expected_line.? }, util.eql(item.items, expected_line.?));
        item.deinit();
    }
    try util.isOk("line_iter next should empty string", 0 == line_iter.next().?.len);
    try util.isOk("line iter next should be null", null == line_iter.next());
    line_list.deinit();
}
