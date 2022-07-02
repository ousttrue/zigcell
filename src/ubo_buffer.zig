pub const Glyph = extern struct {
    xywh: [4]f32,
    offset: [4]f32,
};

pub const Glyphs = extern struct {
    glyphs: [128]Glyph,
};

pub const Global = extern struct {
    projection: [16]f32,
    screenSize: [2]f32,
    cellSize: [2]f32,
    atlasSize: [2]f32,
};
