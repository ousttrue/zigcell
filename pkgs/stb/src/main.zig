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
