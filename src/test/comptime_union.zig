const std = @import("std");
const util = @import("./util.zig");
const ContainerLayout = std.builtin.Type.ContainerLayout;
const UnionField = std.builtin.Type.UnionField;

const UnionSpec = struct {
    name: [:0]const u8,
    type: type,
};

pub fn UnionFromUnionSpecList(comptime union_spec_list: []const UnionSpec) type {
    comptime var field_list: [union_spec_list.len]UnionField = undefined;
    comptime var index = 0;
    inline while (index < field_list.len) : (index += 1) {
        const union_spec = union_spec_list[index];
        field_list[index] = .{
            .name = union_spec.name,
            .type = union_spec.type,
            .alignment = @alignOf(union_spec.type),
        };
    }

    return @Type(.{
        .Union = .{
            .layout = ContainerLayout.Auto,
            .fields = field_list[0..],
            .tag_type = null,
            .decls = &.{},
        },
    });
}

test "comptime union" {
    util.setTestName("comptime union");

    const RGB = struct {
        r: u8,
        g: u8,
        b: u8,
    };

    const union_spec_list = [_]UnionSpec{
        .{
            .name = "pallet",
            .type = u8,
        },
        .{
            .name = "rgb",
            .type = RGB,
        },
    };

    const Color = UnionFromUnionSpecList(union_spec_list[0..]);
    const pallet_color = Color{ .pallet = 4 };

    try util.isEql("color.pallet", pallet_color.pallet, 4);

    const rgb_color = Color{ .rgb = .{
        .r = 55,
        .g = 127,
        .b = 105,
    } };

    try util.isEql("color.rgb.r", rgb_color.rgb.r, 55);
    try util.isEql("color.rgb.g", rgb_color.rgb.g, 127);
    try util.isEql("color.rgb.b", rgb_color.rgb.b, 105);
}
