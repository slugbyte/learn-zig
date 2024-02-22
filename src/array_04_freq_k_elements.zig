const std = @import("std");
const util = @import("./util.zig");

const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const talloc = std.testing.allocator;
const print = std.debug.print;

pub fn FreqK(comptime T: type) type {
    return struct {
        const Self = @This();

        k: u32 = 0,
        allocator: Allocator,
        result_list: ArrayList(ArrayList(T)),

        pub fn append(self: *Self, item: ArrayList(T)) !void {
            self.k += 1;
            try self.result_list.append(item);
        }

        pub fn init(allocator: Allocator) Self {
            const result_list = ArrayList(ArrayList(T)).init(allocator);
            return .{
                .allocator = allocator,
                .result_list = result_list,
            };
        }

        // TODO: can this be *const Self?
        pub fn deinit(self: *const Self) void {
            for (self.result_list.items) |*item| {
                item.deinit();
            }
            self.result_list.deinit();
        }

        pub fn getFreq(self: *const Self, k: usize) ![]T {
            if (k < 1) {
                return error.FreqLessThanOne;
            }
            return self.result_list.items[k - 1].items;
        }

        pub fn getFreqAtIndex(self: *const Self, k: usize, index: usize) !T {
            if (k < 1) {
                return error.FreqLessThanOne;
            }
            return self.result_list.items[k - 1].items[index];
        }

        pub fn calculate(k: u32, list: []const T, allocator: Allocator) !FreqK(T) {
            const Histogram = std.AutoArrayHashMap(T, usize);
            var hist = Histogram.init(allocator);
            defer hist.deinit();

            // init bucket with size oft list
            // fill with null
            const BucketItem = ArrayList(T);
            const BucketList = ArrayList(?BucketItem);
            var bucket_list = BucketList.init(allocator);
            defer bucket_list.deinit();

            try bucket_list.resize(list.len);
            for (0..list.len) |index| {
                bucket_list.items[index] = null;
            }

            // calculate histogram of items int list
            for (list) |item| {
                if (hist.get(item)) |count| {
                    try hist.put(item, count + 1);
                } else {
                    try hist.put(item, 1);
                }
            }

            // iterate over histogram
            // and store items into bucket_list by count
            var iter = hist.iterator();
            while (iter.next()) |entry| {
                const item = entry.key_ptr.*;
                const count = entry.value_ptr.*;

                if (bucket_list.items[count]) |*bucket| {
                    try bucket.append(item);
                } else {
                    var bucket_item = BucketItem.init(allocator);
                    try bucket_item.append(item);
                    bucket_list.items[count] = bucket_item;
                }
            }

            // nice printer for debuging buckets
            // for (bucket_list.items, 0..) |maby_bucket, b_index| {
            //     print("bucket[{d}] ", .{b_index});
            //     if (maby_bucket) |bucket| {
            //         for (bucket.items) |thing| {
            //             print("{d}, ", .{thing});
            //         }
            //     }
            //     print("\n", .{});
            // }

            var freq_k = FreqK(T).init(allocator);
            var temp_k: u32 = 0;
            var index: usize = list.len - 1;
            while (index > 0) : (index -= 1) {
                if (bucket_list.items[index] != null and temp_k < k) {
                    const bucket_item = bucket_list.items[index].?;
                    try freq_k.append(bucket_item);
                    temp_k += 1;
                } else {
                    if (bucket_list.items[index]) |bucket_item| {
                        bucket_item.deinit();
                    }
                }
            }

            return freq_k;
        }
    };
}

test "freqKElements" {
    util.setTestName("freqKElements");
    const data: [19]u32 = .{ 8, 8, 8, 8, 5, 5, 5, 7, 7, 10, 2, 2, 3, 9, 9, 9, 14, 14, 14 };

    const freq_k = try FreqK(u32).calculate(2, &data, talloc);
    defer freq_k.deinit();

    try util.isOk("k is correct", freq_k.k == 2);
    try util.isOk("k of 1 is one item", (try freq_k.getFreq(1)).len == 1);
    try util.isOk("k of 2 is three item", (try freq_k.getFreq(2)).len == 3);
    try util.isOk("most freq item is 8", try freq_k.getFreqAtIndex(1, 0) == 8);
    try util.isOk("k of 2 tie is 5", try freq_k.getFreqAtIndex(2, 0) == 5);
    try util.isOk("k of 2 tie is 9", try freq_k.getFreqAtIndex(2, 1) == 9);
    try util.isOk("k of 2 tie is 14", try freq_k.getFreqAtIndex(2, 2) == 14);
}
