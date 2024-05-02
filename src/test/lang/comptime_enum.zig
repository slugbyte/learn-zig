const std = @import("std");
const util = @import("util");
const EnumField = std.builtin.Type.EnumField;

pub fn EnumFromStringList(comptime tag_type: type, comptime string_list: []const [:0]const u8) type {
    comptime var enum_field_list: [string_list.len]EnumField = undefined;

    comptime var index = 0;
    inline while (index < string_list.len) : (index += 1) {
        enum_field_list[index] = .{
            .name = string_list[index],
            .value = index,
        };
    }

    return @Type(.{
        .Enum = .{
            .tag_type = tag_type,
            .fields = &enum_field_list,
            .decls = &.{},
            .is_exhaustive = true,
        },
    });
}

test "comtime enum" {
    util.setTestName("comptime enum");

    const direction_list = [4][:0]const u8{
        "north",
        "south",
        "east",
        "west",
    };

    const Direction = EnumFromStringList(u32, &direction_list);

    try util.isEql("Direction.north", @intFromEnum(Direction.north), 0);
    try util.isEql("Directio.south", @intFromEnum(Direction.south), 1);
    try util.isEql("Directio.east", @intFromEnum(Direction.east), 2);
    try util.isEql("Directio.west", @intFromEnum(Direction.west), 3);
}
