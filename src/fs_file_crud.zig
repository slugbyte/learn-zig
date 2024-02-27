const std = @import("std");
const fs = std.fs;
const t = std.testing;
const util = @import("./util.zig");
const Allocator = std.mem.Allocator;

// create
// stat
// move
// delete

// create and write a file
// fail if file allready exists
pub fn fileCreateWrite(path: []const u8, data: []const u8) !void {
    const file = try fs.cwd().createFile(path, .{
        .truncate = false,
        .exclusive = true,
    });
    defer file.close();

    const writer = file.writer();
    try writer.writeAll(data);
}

pub fn fileExists(path: []const u8) bool {
    const file = fs.cwd().openFile(path, .{}) catch {
        return false;
    };
    file.close();
    return true;
}

pub fn fileDelete(path: []const u8) !void {
    try fs.cwd().deleteFile(path);
}

// rename file in place
pub fn fileRename(path: []const u8, new_name: []const u8, allocator: Allocator) !void {
    if (!fileExists(path)) {
        return std.fs.File.OpenError.FileNotFound;
    }
    if (fs.path.dirname(path)) |dirname| {
        const new_path = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ dirname, new_name });
        defer allocator.free(new_path);
        errdefer allocator.free(new_path);
        try fs.cwd().rename(path, new_path);
    } else {
        return error.RenameFailed;
    }
}

pub fn fileAppend(path: []const u8, content: []const u8) !void {
    const file = try fs.cwd().openFile(path, .{
        .mode = fs.File.OpenMode.write_only,
    });

    defer file.close();
    errdefer file.close();

    const end_pos = try file.getEndPos();
    const pos = try file.getPos();
    std.debug.print("pos: {d}, end: {d}\n", .{ pos, end_pos });
    try file.seekFromEnd(0);
    _ = try file.write(content);
}

pub fn fileRead(path: []const u8, allocator: Allocator) ![]u8 {
    const file = try fs.cwd().openFile(path, .{});
    defer file.close();
    const file_len = try file.getEndPos();
    const reader = file.reader();
    return reader.readAllAlloc(allocator, file_len);
}

test "createFileAndWrite" {
    util.setTestName("fileExists");

    const temp_file_content = "hello world\n";
    const append_content = "its slugbyte\n";
    const temp_file_path = "./temp_file.txt";
    const rename_file_path = "./temp_file_renamed.txt";
    fileDelete(temp_file_path) catch {};
    fileDelete(rename_file_path) catch {};

    util.setTestName("fileCreateWrite");
    try fileCreateWrite(temp_file_path, temp_file_content);
    try util.isOk("temp file exists", fileExists(temp_file_path));

    util.setTestName("fileRead");
    const read_content_original = try fileRead(temp_file_path, t.allocator);
    defer t.allocator.free(read_content_original);
    try util.isOk("content is correct", util.eql(temp_file_content, read_content_original));

    util.setTestName("fileAppend");
    try fileAppend(temp_file_path, append_content);
    const read_content_append = try fileRead(temp_file_path, t.allocator);
    defer t.allocator.free(read_content_append);
    try util.isOk("appen content is correct", util.eql(temp_file_content ++ append_content, read_content_append));

    util.setTestName("fileRename");
    try fileRename(temp_file_path, rename_file_path, t.allocator);
    try util.isOk("renaem file exists", fileExists(rename_file_path));
    try util.isOk("temp file not exists", !fileExists(temp_file_path));

    util.setTestName("fileDelete");
    try fileDelete(rename_file_path);
    try util.isOk("rename file not exists", !fileExists(rename_file_path));
}
