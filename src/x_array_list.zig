const std = @import("std");
const util = @import("./util.zig");
const mem = std.mem;
const math = std.math;
const Allocator = std.mem.Allocator;
const AutoDestroy = util.AutoDestroy;

pub fn XArrayList(comptime T: type, comptime auto_destroy: AutoDestroy) type {
    return struct {
        capacity: usize,
        len: usize = 0,
        buffer: []T,
        allocator: Allocator,

        const Self = @This();

        pub fn initWithCapacity(allocator: Allocator, capacity: usize) !Self {
            const buffer: []T = try allocator.alloc(T, capacity);
            return .{
                .capacity = capacity,
                .buffer = buffer,
                .allocator = allocator,
            };
        }

        pub fn init(allocator: Allocator) !Self {
            return try initWithCapacity(allocator, 16);
        }

        /// create a clone of the current ArrayList using same allocator
        /// caller owns data
        pub fn clone(self: *const Self) !Self {
            const buffer = try self.allocator.dupe(T, self.buffer);
            return .{ .capacity = self.capacity, .len = self.len, .buffer = buffer, .allocator = self.allocator };
        }

        /// free or destory all items in list if necessary
        pub fn autoDestroy(self: *Self) void {
            if (auto_destroy != .Disabled) {
                for (0..self.len) |index| {
                    switch (auto_destroy) {
                        .Disabled => unreachable,
                        .Free => self.allocator.free(self.buffer[index]),
                        .Destroy => self.allocator.destroy(self.buffer[index]),
                    }
                }
            }
        }

        pub fn deinit(self: *Self) void {
            self.autoDestroy();
            self.allocator.free(self.buffer);
            self.capacity = 0;
            self.len = 0;
        }

        pub const Iterator = struct {
            buffer: []T,
            current: usize = 0,
            is_complete: bool = false,

            pub fn next(self: *Iterator) ?T {
                if (self.is_complete) {
                    return null;
                }
                if (self.current < self.buffer.len) {
                    const result = self.buffer[self.current];
                    self.current += 1;
                    return result;
                } else {
                    self.is_complete = true;
                    return null;
                }
            }
        };

        /// create a Iterator for items in arrayList
        pub fn iterator(self: *Self) Iterator {
            return .{
                .buffer = self.buffer[0..self.len],
            };
        }

        /// map values to the rusult of map_fn
        pub fn map(self: *Self, map_fn: *const fn (T, usize, []T) T) void {
            const data = self.buffer[0..self.len];
            for (data, 0..) |*value, index| {
                value.* = @call(.auto, map_fn, .{ value.*, index, data });
            }
        }

        // create a std.io.Writer that allows to write to an ArrayList
        fn writerHandler(self: *Self, data: []const u8) Allocator.Error!usize {
            try self.appendSlice(data);
            return data.len;
        }

        pub const Writer = if (T != u8)
            @compileError("you can only have a ArrayList.Writer for u8")
        else
            std.io.Writer(*Self, Allocator.Error, writerHandler);

        pub fn writer(self: *Self) Writer {
            return .{
                .context = self,
            };
        }

        fn bufferResize(self: *Self, new_capacity: usize) bool {
            if (self.allocator.resize(self.buffer, new_capacity)) {
                self.capacity = new_capacity;
                return true;
            } else {
                return false;
            }
        }

        fn bufferRealloc(self: *Self, new_capacity: usize) !void {
            self.allocator.free(self.buffer);
            const new_buffer = try self.allocator.alloc(T, new_capacity);
            self.buffer = new_buffer;
            self.capacity = new_capacity;
        }

        /// set the len to 0 and resize the capacity
        /// if autoDestroy is enabled it will run
        /// if new_capacity is null the capacity will not be changed
        /// contents from buffer are not guaranteed to remain afterwards
        pub fn reset(self: *Self, new_capacity: ?usize) !void {
            self.autoDestroy();
            self.len = 0;
            if (new_capacity) |capacity| {
                if (capacity < self.capacity) {
                    return try self.bufferRealloc(capacity);
                }

                if (!self.bufferResize(capacity)) {
                    return try self.bufferRealloc(capacity);
                }
            }
        }

        /// ensure that the capacity is available
        /// if the capacity is not grow the capacity to the correct size + a little
        /// (a little is @max(10, sqrt(new_capacity)))
        /// ensureCapacity will return the capacity of the ArrayList
        pub fn ensureCapacity(self: *Self, capacity: usize) !usize {
            if (capacity > self.capacity) {
                const new_capacity = capacity + @max(10, math.sqrt(capacity));
                // if (self.allocator.resize(self.buffer, new_capacity)) {
                //     util.xxp("wam {d} new: {d}", .{ self.capacity, new_capacity });
                //     self.capacity = new_capacity;
                // } else {
                const new_buffer = try self.allocator.alloc(T, new_capacity);
                mem.copyForwards(T, new_buffer, self.buffer);
                self.allocator.free(self.buffer);
                self.buffer = new_buffer;
                self.capacity = new_capacity;
                // }
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

        pub fn prependSlice(self: *Self, slice: []const T) !void {
            const capacity_needed = self.len + slice.len;
            _ = try self.ensureCapacity(capacity_needed);

            for (0..self.len) |i| {
                const toIndex = capacity_needed - i - 1;
                const fromIndex = self.len - i - 1;
                self.buffer[toIndex] = self.buffer[fromIndex];
            }

            for (slice, 0..) |value, i| {
                self.buffer[i] = value;
            }
            self.len = capacity_needed;
        }

        /// get a value at an index, null if out oub bounds
        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.len) {
                return null;
            }
            return self.buffer[index];
        }

        /// set a value at an index, or error.IndexOutOfBounds
        /// set cannot grow the length or capacity of the ArrayList
        pub fn set(self: *Self, index: usize, value: T) !void {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }
            self.buffer[index] = value;
        }

        /// set a value at each index from startIndex to endIndex, or error.IndexOutOfBounds
        /// start and end index inclusive
        /// setRange cannot grow the length or capacity of the ArrayList
        pub fn setRange(self: *Self, startIndex: usize, endIndex: usize, value: T) !void {
            if (startIndex >= endIndex) {
                return error.IndexRangeInvalid;
            }
            if (endIndex >= self.len) {
                return error.EndIndexOutOfBounds;
            }

            for (startIndex..(endIndex + 1)) |index| {
                self.buffer[index] = value;
            }
        }

        /// set values from a slice into the ArrayList or IndexOutOfBounds
        /// setSlice cannot grow the length or capacity of the ArrayList
        pub fn setSlice(self: *Self, index: usize, slice: []const T) !void {
            if (index + slice.len >= self.len) {
                return error.IndexOutOfBounds;
            }

            for (slice, 0..) |value, offset| {
                const location = index + offset;
                self.buffer[location] = value;
            }
        }

        /// set length and fill with value
        /// if length is null the length will not be changed
        pub fn fill(self: *Self, length: ?usize, value: T) !void {
            if (length) |len| {
                self.len = len;
            }

            if (self.len == 0) {
                return;
            }

            try self.setRange(0, self.len - 1, value);
        }

        // fill the entire buffer capacity with a value
        pub fn fillCapacity(self: *Self, value: T) !void {
            for (self.buffer) |*item| {
                item.* = value;
            }
        }

        // fill unused buffer capacity with value
        pub fn fillUnusedCapacity(self: *Self, value: T) !void {
            for (self.len..self.capacity) |index| {
                self.buffer[index] = value;
            }
        }
    };
}

test "ArrayList No AutoDestroy" {
    util.setTestName("ArrayList No AutoDestroy");
    const allocator = std.testing.allocator;
    var list = try XArrayList(u8, AutoDestroy.Disabled).init(allocator);
    defer list.deinit();
    var old_capacity = list.capacity;

    util.xxxxxxxxxxxxxxxHEADER("list is empty");
    try util.isEql("get(0)", list.get(0), null);

    util.xxxxxxxxxxxxxxxHEADER("append 2");
    try list.append(2);
    try util.isEql("get(0)", list.get(0), 2);
    try util.isEql("len", list.len, 1);
    try util.isOk("capacity unchanged", list.capacity == old_capacity);
    try util.isOk("expected data correct", mem.eql(u8, list.buffer[0..list.len], &(.{2})));

    util.xxxxxxxxxxxxxxxHEADER("append slice [16]u8");
    const append_data: [16]u8 = .{123} ** 16;
    try list.appendSlice(&append_data);
    try util.isGT("capacity grew", list.capacity, old_capacity);
    try util.isEql("list.len", list.len, 17);
    try util.isOk("expected data correct", mem.eql(u8, list.buffer[0..list.len], &(.{2} ++ append_data)));

    util.xxxxxxxxxxxxxxxHEADER("expand capacity 125");
    old_capacity = list.capacity;
    const new_capacity = try list.ensureCapacity(125);
    try util.isGT("capacity grew", new_capacity, old_capacity);
    try util.isEql("capacity", list.capacity, new_capacity);
    try util.isEql("buffer.len", list.buffer.len, new_capacity);
    try util.isOk("expected", mem.eql(u8, list.buffer[0..list.len], &(.{2} ++ append_data)));

    util.xxxxxxxxxxxxxxxHEADER("prepend 17");
    try list.prepend(17);
    try util.isEql("len", list.len, 18);
    try util.isOk("expected", mem.eql(u8, list.buffer[0..list.len], &(.{17} ++ .{2} ++ append_data)));

    util.xxxxxxxxxxxxxxxHEADER("prepend slice [6]u8");
    const prepend_data: [6]u8 = .{ 6, 5, 4, 3, 2, 1 };
    try list.prependSlice(&prepend_data);
    try util.isEql("len", list.len, 24);
    try util.isOk("expected data correct", mem.eql(u8, list.buffer[0..list.len], &(prepend_data ++ .{17} ++ .{2} ++ append_data)));

    util.xxxxxxxxxxxxxxxHEADER("get data");
    try util.isEql("get(0)", list.get(0), 6);
    try util.isEql("get(6)", list.get(6), 17);
    try util.isEql("get(7)", list.get(7), 2);
    try util.isEql("get(8)", list.get(8), 123);
    try util.isEql("get(23)", list.get(23), 123);
    try util.isEql("get(list.len)", list.get(list.len), null);

    util.xxxxxxxxxxxxxxxHEADER("set data");
    try list.set(3, 99);
    try util.isEql("get(3)", list.get(3), 99);

    util.xxxxxxxxxxxxxxxHEADER("set slice");
    try list.setSlice(2, &.{ 1, 2, 3 });
    try util.isEql("get(2)", list.get(2), 1);
    try util.isEql("get(3)", list.get(3), 2);
    try util.isEql("get(4)", list.get(4), 3);

    util.xxxxxxxxxxxxxxxHEADER("fillCapacity");
    try list.fillCapacity(255);
    try util.isOk("capacity filed with 255", mem.eql(u8, list.buffer[0..], &(.{255} ** 136)));

    util.xxxxxxxxxxxxxxxHEADER("fill no set length");
    try list.fill(null, 0);
    try util.isEql("len", list.len, 24);
    try util.isOk("buffer filled with 0", mem.eql(u8, list.buffer[0..list.len], &(.{0} ** 24)));

    util.xxxxxxxxxxxxxxxHEADER("fill and set length");
    try list.fill(5, 1);
    try util.isEql("len", list.len, 5);
    try util.isOk("buffer filled with 1", mem.eql(u8, list.buffer[0..list.len], &(.{1} ** 5)));

    util.xxxxxxxxxxxxxxxHEADER("fill set length");
    try list.fillUnusedCapacity(127);
    try util.isEql("len", list.len, 5);
    try util.isOk("buffer still filled with 1", mem.eql(u8, list.buffer[0..list.len], &(.{1} ** 5)));
    try util.isOk("buffer unused capacity filled with 127", mem.eql(u8, list.buffer[list.len..], &(.{127} ** 131)));

    util.xxxxxxxxxxxxxxxHEADER("clone");
    var clone = try list.clone();
    defer clone.deinit();
    try clone.fill(2, 3);
    try util.isEql("list.len", list.len, 5);
    try util.isOk("list still filled with 1", mem.eql(u8, list.buffer[0..list.len], &(.{1} ** 5)));
    try util.isEql("clone.len", clone.len, 2);
    try util.isOk("clone filled with 3", mem.eql(u8, clone.buffer[0..clone.len], &(.{3} ** 2)));

    util.xxxxxxxxxxxxxxxHEADER("map mult index");
    const multIndex = struct {
        pub fn handler(value: u8, index: usize, buffer: []u8) u8 {
            _ = buffer;
            const u8Index: u8 = @truncate(index);
            return value * u8Index;
        }
    };
    try list.fill(4, 5);
    // sooo cool this works
    list.map(&multIndex.handler);
    try util.isEql("get(0)", list.get(0), 0);
    try util.isEql("get(1)", list.get(1), 5);
    try util.isEql("get(2)", list.get(2), 10);
    try util.isEql("get(3)", list.get(3), 15);

    util.xxxxxxxxxxxxxxxHEADER("iterator");
    var acc: u8 = 0;
    var iter = list.iterator();
    while (iter.next()) |value| {
        acc += value;
        acc += 1;
    }
    try util.isEql("acc", acc, 34);

    util.xxxxxxxxxxxxxxxHEADER("reset");
    try list.reset(null);
    try util.isEql("len", list.len, 0);
    try util.isEql("capacity can be same", list.capacity, 136);
    try list.reset(500);
    try util.isEql("len", list.len, 0);
    try util.isEql("capacity can grow", list.capacity, 500);
    try list.reset(10);
    try util.isEql("len", list.len, 0);
    try util.isEql("capacity can shrink", list.capacity, 10);

    util.xxxxxxxxxxxxxxxHEADER("writer");
    const writer = list.writer();
    var expected_acc: usize = 0;
    for (0..10) |_| {
        const random_size = std.crypto.random.int(u8);
        const random_slice: []u8 = try std.testing.allocator.alloc(u8, random_size);
        defer std.testing.allocator.free(random_slice);

        for (0..random_size) |index| {
            random_slice[index] = 1;
        }

        expected_acc += try writer.write(random_slice);
    }

    try writer.writeByte(100);

    var actual_acc: usize = 0;
    var write_iter = list.iterator();
    while (write_iter.next()) |value| {
        actual_acc += value;
    }

    try util.isEql("actual_acc and expected_acc", actual_acc - 100, expected_acc);
    try util.isEql("actual_acc is buf len", actual_acc - 99, list.len);
    try util.isGT("actual_acc is buf len", list.capacity, list.len);

    // const wat = std.ArrayList(u8).init(std.testing.allocator);
    util.reportTest();
}
