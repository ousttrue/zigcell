const std = @import("std");
const stb = @import("stb");
const glo = @import("glo");
const util = @import("./util.zig");

pub const Atlas = struct {
    const Self = @This();

    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        if (self.texture) |texture| {
            texture.deinit();
        }
    }

    // https://gist.github.com/vassvik/f442a4cc6127bc7967c583a12b148ac9
    pub fn loadFont(self: *Self, path: []const u8, font_size: f32) !glo.Texture {
        const ttf_buffer = try util.readSource(self.allocator, path);
        defer self.allocator.free(ttf_buffer);

        // setup glyph info stuff, check stb_truetype.h for definition of structs
        // const Chars95 = [95]stb.stbtt_packedchar;
        // var glyph_metrics: [16]Chars95 = undefined;
        // var ranges = [_]stb.stbtt_pack_range{
        //     .{ .font_size = 72, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[0][0] },
        //     .{ .font_size = 68, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[1][0] },
        //     .{ .font_size = 64, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[2][0] },
        //     .{ .font_size = 60, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[3][0] },
        //     .{ .font_size = 56, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[4][0] },
        //     .{ .font_size = 52, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[5][0] },
        //     .{ .font_size = 48, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[6][0] },
        //     .{ .font_size = 44, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[7][0] },
        //     .{ .font_size = 40, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[8][0] },
        //     .{ .font_size = 36, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[9][0] },
        //     .{ .font_size = 32, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[10][0] },
        //     .{ .font_size = 28, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[11][0] },
        //     .{ .font_size = 24, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[12][0] },
        //     .{ .font_size = 20, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[13][0] },
        //     .{ .font_size = 16, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[14][0] },
        //     .{ .font_size = 12, .first_unicode_codepoint_in_range = 32, .num_chars = 95, .chardata_for_range = &glyph_metrics[15][0] },
        // };
        var glyphs: [95]stb.stbtt_packedchar = undefined;
        var ranges = [_]stb.stbtt_pack_range{
            .{ .font_size = font_size, .first_unicode_codepoint_in_range = 32, .num_chars = glyphs.len, .chardata_for_range = &glyphs[0] },
        };

        // make a most likely large enough bitmap, adjust to font type, number of sizes and glyphs and oversampling
        const width = 1024;
        const max_height = 1024;
        var bitmap = try self.allocator.alloc(u8, max_height * width);
        defer self.allocator.free(bitmap);

        // do the packing, based on the ranges specified
        var pc: stb.stbtt_pack_context = undefined;
        _ = stb.stbtt_PackBegin(&pc, &bitmap[0], width, max_height, 0, 1, null);
        stb.stbtt_PackSetOversampling(&pc, 1, 1); // say, choose 3x1 oversampling for subpixel positioning
        _ = stb.stbtt_PackFontRanges(&pc, &ttf_buffer[0], 0, &ranges[0], ranges.len);
        stb.stbtt_PackEnd(&pc);

        // get the global metrics for each size/range
        var info: stb.stbtt_fontinfo = undefined;
        _ = stb.stbtt_InitFont(&info, &ttf_buffer[0], stb.stbtt_GetFontOffsetForIndex(&ttf_buffer[0], 0));

        var ascents: [ranges.len]f32 = undefined;
        var descents: [ranges.len]f32 = undefined;
        var linegaps: [ranges.len]f32 = undefined;

        for (ranges) |*r, i| {
            const scale = stb.stbtt_ScaleForPixelHeight(&info, r.font_size);
            _ = scale;
            var a: c_int = undefined;
            var d: c_int = undefined;
            var l: c_int = undefined;
            stb.stbtt_GetFontVMetrics(&info, &a, &d, &l);
            ascents[i] = @intToFloat(f32, a) * scale;
            descents[i] = @intToFloat(f32, d) * scale;
            linegaps[i] = @intToFloat(f32, l) * scale;
        }

        for (ranges) |*r, j| {
            std.log.debug("size    {}:", .{r.font_size});
            std.log.debug("ascent  {}:", .{ascents[j]});
            std.log.debug("descent {}:", .{descents[j]});
            std.log.debug("linegap {}:", .{linegaps[j]});
            for (glyphs) |g, i| {
                std.log.debug("    '{}':  (x0,y0) = ({},{}),  (x1,y1) = ({},{}),  (xoff,yoff) = ({},{}),  (xoff2,yoff2) = ({},{}),  xadvance = {}", .{
                    32 + i,
                    g.x0,
                    g.y0,
                    g.x1,
                    g.y1,
                    g.xoff,
                    g.yoff,
                    g.xoff2,
                    g.yoff2,
                    g.xadvance,
                });
            }
        }

        return glo.Texture.init(width, max_height, 1, bitmap);
    }
};
