const std = @import("std");
const util = @import("./util.zig");

// std.ArrayList

const AutoDestroy = enum {
    Disabled,
    Free,
    Destroy,
};

pub fn ArrayList(comptime T: type, comptime auto_destroy: AutoDestroy) type {
    return struct {
        capacity: usize,
        len: usize = 0,
        buffer: []T,
        allocator: std.mem.Allocator,

        const Self = @This();

        pub fn initWithCapacity(allocator: std.mem.Allocator, capacity: usize) !Self {
            const buffer: []T = try allocator.alloc(T, capacity);
            return .{
                .capacity = capacity,
                .buffer = buffer,
                .allocator = allocator,
            };
        }

        pub fn init(allocator: std.mem.Allocator) !Self {
            return try initWithCapacity(allocator, 16);
        }

        pub fn deinit(self: *Self) void {
            if (auto_destroy != .Disabled) {
                for (0..self.len) |index| {
                    switch (auto_destroy) {
                        .Disabled => unreachable,
                        .Free => self.allocator.free(self.buffer[index]),
                        .Destroy => self.allocator.destroy(self.buffer[index]),
                    }
                }
            }

            self.allocator.free(self.buffer);
            self.capacity = 0;
            self.len = 0;
        }

        /// ensure that the capacity is available
        /// if the capacity is not grow the capacity to the correct size + a little
        /// (a little is @max(10, sqrt(new_capacity)))
        /// ensureCapacity will return the capacity of the ArrayList
        pub fn ensureCapacity(self: *Self, capacity: usize) !usize {
            if (capacity >= self.capacity) {
                const new_capacity = capacity + @max(10, std.math.sqrt(capacity));
                if (self.allocator.resize(self.buffer, new_capacity + std.math.sqrt(new_capacity))) {
                    self.capacity = new_capacity;
                } else {
                    const new_buffer = try self.allocator.alloc(T, new_capacity);
                    std.mem.copyForwards(T, new_buffer, self.buffer);
                    self.allocator.free(self.buffer);
                    self.buffer = new_buffer;
                    self.capacity = new_capacity;
                }
            }
            return self.capacity;
        }

        pub fn append(self: *Self, value: T) !void {
            const capacity_needed = self.len + 1;
            _ = try self.ensureCapacity(capacity_needed);

            self.buffer[self.len] = value;
            self.len += 1;
        }

        pub fn appendSlice(self: *Self, slice: []const T) !void {
            const capacity_needed = self.len + 1 + slice.len;
            _ = try self.ensureCapacity(capacity_needed);

            for (slice) |value| {
                self.buffer[self.len] = value;
                self.len += 1;
            }
        }

        pub fn prepend(self: *Self, value: T) !void {
            const capacity_needed = self.len + 1;
            _ = try self.ensureCapacity(capacity_needed);

            for (0..self.len) |offset| {
                const index = self.len - offset;
                self.buffer[index] = self.buffer[index - 1];
            }
            self.buffer[0] = value;
            self.len += 1;
        }

        pub fn prependSlice(self: *Self, slice: []T) !void {
            const capacity_needed = self.len + slice.len;
            _ = try self.ensureCapacity(capacity_needed);

            for (0..self.len) |i| {
                const toIndex = capacity_needed - i;
                const fromIndex = self.len - i;
                self.buffer[toIndex] = self.buffer[fromIndex];
            }

            for (slice, 0..) |value, i| {
                self.buffer[i] = value;
            }
            self.len = capacity_needed;
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.len) {
                return null;
            }
            return self.buffer[index];
        }
    };
}

fn add(a: u8, b: u8) u8 {
    return a + b;
}

test "ArrayList No AutoDestroy" {
    util.setTestName("ArrayList No AutoDestroy");
    const allocator = std.testing.allocator;

    var list = try ArrayList(u8, AutoDestroy.Disabled).init(allocator);
    defer list.deinit();
    var old_capacity = list.capacity;

    util.xxl("\n------------ list is empty");
    try util.isEql("get(0)", list.get(0), null);
    util.xxl("\n------------ append 2");
    try list.append(2);
    try util.isEql("get(0)", list.get(0), 2);
    try util.isEql("len", list.len, 1);
    try util.isOk("capacity unchanged", list.capacity == old_capacity);

    util.xxl("\n----------- append slice [16]u8");
    const append_data: [16]u8 = .{123} ** 16;
    try list.appendSlice(&append_data);
    try util.isGT("capacity grew", list.capacity, old_capacity);
    try util.isEql("list.len", list.len, 17);

    old_capacity = list.capacity;
    const new_capacity = try list.ensureCapacity(125);
    try util.isGT("capacity grew", new_capacity, old_capacity);
    try util.isEql("capacity", list.capacity, new_capacity);
    try util.isEql("buffer.len", list.buffer.len, new_capacity);

    try list.prepend(17);
    try util.isEql("get(0)", list.get(0), 17);
    try util.isEql("get(1)", list.get(1), 2);
    try util.isEql("get(17)", list.get(17), 123);
    try util.isEql("get(18)", list.get(18), null);
    try util.isEql("len", list.len, 18);
}
