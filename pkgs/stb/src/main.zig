pub const stbtt_packedchar = extern struct {
    // coordinates of bbox in bitmap
    x0: u16,
    y0: u16,
    x1: u16,
    y1: u16,

    xoff: f32,
    yoff: f32,
    xadvance: f32,
    xoff2: f32,
    yoff2: f32,
};

pub const stbtt_pack_range = extern struct {
    font_size: f32,
    first_unicode_codepoint_in_range: i32, // if non-zero, then the chars are continuous, and this is the first codepoint
    array_of_unicode_codepoints: ?*i32 = null, // if non-zero, then this is an array of unicode codepoints
    num_chars: i32,
    chardata_for_range: *stbtt_packedchar, // output
    h_oversample: u8 = 0, // don't set these, they're used internally
    v_oversample: u8 = 0,
};

pub const stbtt_pack_context = extern struct {
    user_allocator_context: *anyopaque,
    pack_info: *anyopaque,
    width: i32,
    height: i32,
    stride_in_bytes: i32,
    padding: i32,
    skip_missing: i32,
    h_oversample: u32,
    v_oversample: u32,
    pixels: *u8,
    nodes: *anyopaque,
};

pub extern fn stbtt_PackBegin(spc: *stbtt_pack_context, pixels: *u8, width: c_int, height: c_int, stride_in_bytes: c_int, padding: c_int, alloc_context: ?*anyopaque) c_int;
pub extern fn stbtt_PackEnd(spc: *stbtt_pack_context) void;
pub extern fn stbtt_PackSetOversampling(spc: *stbtt_pack_context, h_oversample: c_uint, v_oversample: c_uint) void;
pub extern fn stbtt_PackFontRanges(spc: *stbtt_pack_context, fontdata: *const u8, font_index: c_int, ranges: *stbtt_pack_range, num_ranges: c_int) c_int;

const stbtt__buf = extern struct {
    data: *u8,
    cursor: c_int,
    size: c_int,
};

pub const stbtt_fontinfo = extern struct {
    userdata: *anyopaque,
    data: *u8, // pointer to .ttf file
    fontstart: c_int, // offset of start of font

    numGlyphs: c_int, // number of glyphs, needed for range checking

    loca: c_int,
    head: c_int,
    glyf: c_int,
    hhea: c_int,
    hmtx: c_int,
    kern: c_int,
    gpos: c_int,
    svg: c_int, // table locations as offset from start of .ttf
    index_map: c_int, // a cmap mapping for our chosen character encoding
    indexToLocFormat: c_int, // format needed to map from glyph index to glyph

    cff: stbtt__buf, // cff font data
    charstrings: stbtt__buf, // the charstring index
    gsubrs: stbtt__buf, // global charstring subroutines index
    subrs: stbtt__buf, // private charstring subroutines index
    fontdicts: stbtt__buf, // array of font dicts
    fdselect: stbtt__buf, // map from glyph to fontdict
};

pub extern fn stbtt_GetFontOffsetForIndex(data: *const u8, index: c_int) i32;
pub extern fn stbtt_InitFont(info: *stbtt_fontinfo, data: *const u8, offset: i32) i32;
pub extern fn stbtt_ScaleForPixelHeight(info: *const stbtt_fontinfo, pixels: f32) f32;
pub extern fn stbtt_GetFontVMetrics(info: *const stbtt_fontinfo, ascent: *c_int, descent: *c_int, lineGap: *c_int) void;
