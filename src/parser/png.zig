const std = @import("std");
const t = std.testing;
const fs = std.fs;
const Allocator = std.mem.Allocator;

const ChunkType = enum {
    IHDR,
    IDAT,
    PLTE,
    IEND,
    iTXt,
    iCCp,

    pub fn fromString(text: []const u8) ?ChunkType {
        if (std.mem.eql(u8, text, "IHDR")) {
            return .IHDR;
        }

        if (std.mem.eql(u8, text, "IDAT")) {
            return .IDAT;
        }

        if (std.mem.eql(u8, text, "PLTE")) {
            return .PLTE;
        }

        if (std.mem.eql(u8, text, "IEND")) {
            return .IEND;
        }

        if (std.mem.eql(u8, text, "iTXt")) {
            return .iTXt;
        }

        if (std.mem.eql(u8, text, "iCCp")) {
            return .iCCp;
        }

        return null;
    }

    // tRNS,
    // cHRM,
    // sRGB,
    // iTXt,
    // zTXt,
    // tEXt,
    // bKGD,
    // pHYs,
    // sBIT,
    // sPLT,
    // hIST,
    // tIME,
    // iCCP,
};

const ColorType = enum(u8) {
    const ColorTypeSelf = @This();

    Grayscale = 0,
    RGB = 2,
    PalletIndex = 3,
    GrayscaleAlpha = 4,
    RGBAlpha = 6,

    pub fn assertValidBitDelpth(self: ColorTypeSelf, bit_depth: u8) !void {
        switch (self) {
            .Grayscale => {
                switch (bit_depth) {
                    1, 2, 4, 8, 16 => return,
                    else => return error.InvalidGrayscaleBitDepth,
                }
            },
            .RGB => {
                switch (bit_depth) {
                    8, 16 => return,
                    else => return error.InvalidRGBBitDepth,
                }
            },
            .PalletIndex => {
                switch (bit_depth) {
                    1, 2, 4, 8 => return,
                    else => return error.InvalidPalletIndexBitDepth,
                }
            },
            .GrayscaleAlpha => {
                switch (bit_depth) {
                    8, 16 => return,
                    else => return error.InvalidGrayscaleAlphaBitDepth,
                }
            },
            .RGBAlpha => {
                switch (bit_depth) {
                    8, 16 => return,
                    else => return error.InvalidRGBAlphaBitDepth,
                }
            },
        }
    }
};

const CompressionMethod = enum(u8) { Default = 0 };
const FilterMethod = enum(u8) { Default = 0 };
const InterlaceMethod = enum(u8) {
    Default = 0,
    Adam = 1,
};

const ChunkIDHR = struct {
    width: u32,
    height: u32,
    bit_depth: u8,
    color_type: ColorType,
    compression_method: CompressionMethod = .default,
    filter_method: FilterMethod = .default,
    interlace_method: InterlaceMethod = .default,
};

const Self = @This();
pub const PNG_FILE_HEADER: [8]u8 = .{ 137, 80, 78, 71, 13, 10, 26, 10 };

const crc_table_size = 256;
const crc_table: [crc_table_size]u32 = crc_table_fill: {
    const crc_polynomial = 0xEDB88320;
    @setEvalBranchQuota(5000);
    var result: [crc_table_size]u32 = undefined;

    for (&result, 0..) |*item, i| {
        var crc = i;
        for (0..8) |_| {
            if (crc & 1 == 1) {
                crc = (crc >> 1) ^ crc_polynomial;
            } else {
                crc = (crc >> 1);
            }
        }
        item.* = crc;
    }

    break :crc_table_fill result;
};

fn crcTableDebug() void {
    var i: usize = 0;

    std.debug.print("\nCRC Table:\n", .{});
    while (i < crc_table.len) : (i += 8) {
        const table = crc_table[i .. i + 8];
        for (0..8) |index| {
            std.debug.print("{X:0<8} ", .{table[index]});
        }
        std.debug.print("\n", .{});
    }
}

pub const PngLoadError = error{
    PngHeaderInvalid,
};

buffer: ?[]u8 = null,
allocator: Allocator,

pub fn init(allocator: Allocator) Self {
    crcTableDebug();
    return .{
        .allocator = allocator,
    };
}

pub fn deinit(self: *Self) void {
    if (self.buffer) |buffer| {
        self.allocator.free(buffer);
        self.buffer = null;
    }
}

// pass in a slice of the first 4 bytes of chunk
fn getChunkSize(chunk_buf: []const u8) u32 {
    var size_mem: [4]u8 = undefined;
    std.mem.copyForwards(u8, &size_mem, chunk_buf[0..4]);
    return std.mem.readInt(u32, &size_mem, .big);
}

pub fn loadFromFile(self: *Self, path: []const u8) !void {
    const file = try fs.cwd().openFile(path, .{});
    defer file.close();
    const reader = file.reader();
    const buffer = try reader.readAllAlloc(self.allocator, std.math.maxInt(usize));

    std.debug.print("buffer len: {d}\n", .{buffer.len});

    if (!std.mem.startsWith(u8, buffer, &PNG_FILE_HEADER)) {
        return PngLoadError.PngHeaderInvalid;
    }

    self.buffer = buffer;

    // iter over chunks in buff
    var i: usize = 8;
    while (i < buffer.len) {
        const chunk_type_buf = buffer[i + 4 .. i + 8];
        const chunk_size = getChunkSize(buffer[i..]);

        if (ChunkType.fromString(chunk_type_buf)) |chunk_type| {
            switch (chunk_type) {
                .IHDR => {
                    const chunk_data_buf = buffer[i + 8 .. i + 8 + chunk_size];
                    std.debug.print("chunk_data_buf: {d} {d}\n", .{ chunk_size, chunk_data_buf.len });
                    const width = getChunkSize(chunk_data_buf);
                    const height = getChunkSize(chunk_data_buf[4..]);
                    const bit_depth = chunk_data_buf[8];
                    const color_type: ColorType = @enumFromInt(chunk_data_buf[9]);
                    const compression_method: CompressionMethod = @enumFromInt(chunk_data_buf[10]);
                    const filter_method: FilterMethod = @enumFromInt(chunk_data_buf[11]);
                    const interlace_method: InterlaceMethod = @enumFromInt(chunk_data_buf[12]);
                    try color_type.assertValidBitDelpth(bit_depth);
                    std.debug.print("IDHR:\n", .{});
                    std.debug.print("--width: {d}\n", .{width});
                    std.debug.print("--height: {d}\n", .{height});
                    std.debug.print("--bit_depth: {d}\n", .{bit_depth});
                    std.debug.print("--color_type: {any}\n", .{color_type});
                    std.debug.print("--filter_method: {any}\n", .{filter_method});
                    std.debug.print("--interlace_method: {any}\n", .{interlace_method});
                    std.debug.print("--compression_method: {any}\n", .{compression_method});
                },
                .iTXt => {
                    const chunk_data_buf = buffer[i + 8 .. i + 8 + chunk_size];
                    std.debug.print("iTXt\n\n{s}\n\n", .{chunk_data_buf});
                },
                else => {
                    std.debug.print("type: {s} size: {d}\n", .{ @tagName(chunk_type), chunk_size });
                },
            }
        } else {
            std.debug.print("Unparsable {s} chunk of size: {d}\n", .{ chunk_type_buf, chunk_size });
        }
        i += chunk_size + 12;
    }
}

pub fn relaiveFile(buffer: []u8, source_location: std.builtin.SourceLocation, path: []const u8) []u8 {
    const file_dir = std.fs.path.dirname(source_location.file).?;
    std.mem.copyForwards(u8, buffer, file_dir);
    buffer[file_dir.len] = '/';
    std.mem.copyForwards(u8, buffer[file_dir.len + 1 ..], path);
    return buffer[0 .. file_dir.len + path.len + 1];
}

test "loadFromFile" {
    var file_path_buffer: [1000]u8 = .{0} ** 1000;
    const file_path = relaiveFile(&file_path_buffer, @src(), "./res/img/example.png");
    // std.debug.print("\nfile_path: {s}\n", .{file_path});

    var png = Self.init(t.allocator);
    try png.loadFromFile(file_path);
    defer png.deinit();
}
