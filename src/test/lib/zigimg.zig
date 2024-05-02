const std = @import("std");
const t = std.testing;
const util = @import("util");

const zigimg = @import("zigimg");
const Image = zigimg.Image;
const Allocator = std.mem.Allocator;

fn isTopHalf(img: Image, pixelOffset: usize) bool {
    return pixelOffset < @divFloor(img.pixels.rgb24.len, 2);
}

fn isLeftHalf(img: Image, pixelOffset: usize) bool {
    return (pixelOffset % img.width) < @divFloor(img.width, 2);
}

test "zigimg" {
    const file_path = try util.getPathRelativeToSrc(t.allocator, @src(), "../asset/png/path.png");
    defer t.allocator.free(file_path);
    var img = try Image.fromFilePath(t.allocator, file_path);
    defer img.deinit();
    std.debug.print("width: {d}\n", .{img.width});
    std.debug.print("height: {d}\n", .{img.height});
    std.debug.print("pix: {any}\n", .{img.pixelFormat()});

    var should_horizontal_red = false;
    var should_verticle_blue = true;
    for (img.pixels.rgb24, 0..) |*pixel, index| {
        if (index % (img.width * 16) == 0) {
            should_horizontal_red = !should_horizontal_red;
        }
        if (index % 32 == 0) {
            should_verticle_blue = !should_verticle_blue;
        }
        // bottom right
        if (!isLeftHalf(img, index) and !isTopHalf(img, index)) {
            if (should_horizontal_red) {
                pixel.* = zigimg.color.Rgb24.initRgb(255, pixel.g, pixel.b);
            }
        }
        // top left
        if (isLeftHalf(img, index) and isTopHalf(img, index)) {
            if (should_verticle_blue) {
                pixel.* = zigimg.color.Rgb24.initRgb(pixel.r, pixel.g, 255);
            }
        }

        // top right
        if (!isLeftHalf(img, index) and isTopHalf(img, index)) {
            const r: u16 = pixel.r;
            const g: u16 = pixel.g;
            const b: u16 = pixel.b;
            const gray16: u16 = @divFloor(r + g + b, 3);
            const gray: u8 = @truncate(gray16);
            pixel.* = zigimg.color.Rgb24.initRgb(gray, gray, gray);
        }
    }
    const output_path = try util.getPathRelativeToSrc(t.allocator, @src(), "../temp/image.png");
    defer t.allocator.free(output_path);
    try img.writeToFilePath(output_path, .{
        .png = .{},
    });
    // zigimg.Image.EncoderOptions
}
