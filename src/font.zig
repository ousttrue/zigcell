const std = @import("std");
const stb = @import("stb");
const glo = @import("glo");
const io = @import("./io.zig");

const GLYPH_COUNT = 95;

pub const Atlas = struct {
    const Self = @This();

    allocator: std.mem.Allocator,
    glyphs: [GLYPH_COUNT]stb.stbtt_packedchar = undefined,
    ascents: [GLYPH_COUNT]f32 = undefined,
    descents: [GLYPH_COUNT]f32 = undefined,
    linegaps: [GLYPH_COUNT]f32 = undefined,

    pub fn new(allocator: std.mem.Allocator) *Self {
        var self = allocator.create(Self) catch unreachable;
        self.* = Self{
            .allocator = allocator,
        };
        return self;
    }

    pub fn delete(self: *Self) void {
        self.allocator.destroy(self);
    }

    pub fn glyphIndexFromCodePoint(self: Self, c: u16) usize {
        _ = self;
        if (c < 32) {
            return 0;
        }
        return c - 32;
    }

    // https://gist.github.com/vassvik/f442a4cc6127bc7967c583a12b148ac9
    pub fn loadFont(self: *Self, path: []const u8, font_size: f32, atlas_size: u32) !glo.Texture {
        const ttf_buffer = try io.readAllBytesAllocate(self.allocator, path);
        defer self.allocator.free(ttf_buffer);

        var ranges = [_]stb.stbtt_pack_range{
            .{ .font_size = font_size, .first_unicode_codepoint_in_range = 32, .num_chars = self.glyphs.len, .chardata_for_range = &self.glyphs[0] },
        };

        // make a most likely large enough bitmap, adjust to font type, number of sizes and glyphs and oversampling
        const width = atlas_size;
        const max_height = atlas_size;
        var bitmap = try self.allocator.alloc(u8, max_height * width);
        defer self.allocator.free(bitmap);

        // do the packing, based on the ranges specified
        var pc: stb.stbtt_pack_context = undefined;
        _ = stb.stbtt_PackBegin(&pc, &bitmap[0], @intCast(c_int, width), @intCast(c_int, max_height), 0, 1, null);
        stb.stbtt_PackSetOversampling(&pc, 1, 1); // say, choose 3x1 oversampling for subpixel positioning
        _ = stb.stbtt_PackFontRanges(&pc, &ttf_buffer[0], 0, &ranges[0], ranges.len);
        stb.stbtt_PackEnd(&pc);

        // get the global metrics for each size/range
        var info: stb.stbtt_fontinfo = undefined;
        _ = stb.stbtt_InitFont(&info, &ttf_buffer[0], stb.stbtt_GetFontOffsetForIndex(&ttf_buffer[0], 0));

        for (ranges) |*r, i| {
            const scale = stb.stbtt_ScaleForPixelHeight(&info, r.font_size);
            _ = scale;
            var a: c_int = undefined;
            var d: c_int = undefined;
            var l: c_int = undefined;
            stb.stbtt_GetFontVMetrics(&info, &a, &d, &l);
            self.ascents[i] = @intToFloat(f32, a) * scale;
            self.descents[i] = @intToFloat(f32, d) * scale;
            self.linegaps[i] = @intToFloat(f32, l) * scale;
        }

        // for (ranges) |*r, j| {
        //     std.log.debug("size    {}:", .{r.font_size});
        //     std.log.debug("ascent  {}:", .{self.ascents[j]});
        //     std.log.debug("descent {}:", .{self.descents[j]});
        //     std.log.debug("linegap {}:", .{self.linegaps[j]});
        //     for (self.glyphs) |g, i| {
        //         std.log.debug("    '{}':  (x0,y0) = ({},{}),  (x1,y1) = ({},{}),  (xoff,yoff) = ({},{}),  (xoff2,yoff2) = ({},{}),  xadvance = {}", .{
        //             32 + i,
        //             g.x0,
        //             g.y0,
        //             g.x1,
        //             g.y1,
        //             g.xoff,
        //             g.yoff,
        //             g.xoff2,
        //             g.yoff2,
        //             g.xadvance,
        //         });
        //     }
        // }

        return glo.Texture.init(width, max_height, 1, bitmap);
    }
};
