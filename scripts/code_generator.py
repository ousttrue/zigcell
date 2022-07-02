from typing import Optional
import logging
import pathlib
import coloredlogs
from rawtypes.parser.header import Header, StructConfiguration
from rawtypes.parser.type_context import ParamContext
from rawtypes.interpreted_types.basetype import BaseType
from rawtypes.interpreted_types import ReferenceType
from rawtypes.generator.zig_generator import ZigGenerator

LOGGER = logging.getLogger(__name__)
HERE = pathlib.Path(__file__).absolute().parent
WORKSPACE = HERE.parent


def generate_glfw():
    base = WORKSPACE / 'pkgs/glfw'
    header = base / '_external/glfw/include/GLFW/glfw3.h'
    zig = base / 'src/main.zig'
    LOGGER.debug(f'{header.name} => {zig}')
    generator = ZigGenerator(Header(header))
    generator.generate(zig)


def generate_imgui():
    IMGUI_HEADER = WORKSPACE / 'pkgs/imgui/_external/imgui/imgui.h'
    IMGUI_HEADER_INTERNAL = WORKSPACE / 'pkgs/imgui/_external/imgui/imgui_internal.h'
    IMGUI_IMPL_GLFW = WORKSPACE / 'pkgs/imgui/_external/imgui/backends/imgui_impl_glfw.h'
    IMGUI_IMPL_OPENGL3 = WORKSPACE / \
        'pkgs/imgui/_external/imgui/backends/imgui_impl_opengl3.h'
    IMGUI_ZIG = WORKSPACE / 'pkgs/imgui/src/main.zig'
    LOGGER.debug(f'{IMGUI_HEADER.name} => {IMGUI_ZIG}')

    headers = [
        Header(IMGUI_HEADER, include_dirs=[IMGUI_HEADER.parent],
               structs=[
                   StructConfiguration('ImFontAtlas', methods=True),
                   StructConfiguration('ImDrawList', methods=True),
        ],
            begin='''
pub const ImVector = extern struct {
    Size: c_int,
    Capacity: c_int,
    Data: *anyopaque,
};

const STB_TEXTEDIT_UNDOSTATECOUNT = 99;
const STB_TEXTEDIT_UNDOCHARCOUNT = 999;
const STB_TEXTEDIT_POSITIONTYPE = c_int;
const STB_TEXTEDIT_CHARTYPE = u16;
const ImWchar = u16;
const ImGuiTableColumnIdx = i8;
const ImGuiTableDrawChannelIdx = u8;
const ImTextureID = *anyopaque;
const ImFileHandle = *anyopaque;
const ImGuiKey_NamedKey_BEGIN         = 512;
const ImGuiKey_NamedKey_END           = 0x285; //ImGuiKey_COUNT;
const ImGuiKey_NamedKey_COUNT         = ImGuiKey_NamedKey_END - ImGuiKey_NamedKey_BEGIN;

pub const ImSpan = extern struct {
    Data: *anyopaque,
    DataEnd: *anyopaque,
};

pub const ImChunkStream = extern struct {
    Buf: ImVector,
};

pub const ImPool = extern struct {
    Buf: ImVector,
    Map: ImGuiStorage,
    FreeIdx: i32,
    AliveCount: i32,
};

pub const ImBitArray = extern struct {
    Storage: [(ImGuiKey_NamedKey_COUNT + 31) >> 5]u32,
};
pub const ImBitArrayForNamedKeys = ImBitArray;

pub const StbUndoRecord = extern struct {
    where: STB_TEXTEDIT_POSITIONTYPE,
    insert_length: STB_TEXTEDIT_POSITIONTYPE,
    delete_length: STB_TEXTEDIT_POSITIONTYPE,
    char_storage: c_int,
};

pub const StbUndoState = extern struct {
    undo_rec: [STB_TEXTEDIT_UNDOSTATECOUNT]StbUndoRecord,
    undo_char: [STB_TEXTEDIT_UNDOCHARCOUNT]STB_TEXTEDIT_CHARTYPE,
    undo_point: c_short,
    redo_point: c_short,
    undo_char_point: c_int,
    redo_char_point: c_int,
};

pub const STB_TexteditState = extern struct {
   cursor: c_int,
   select_start: c_int,
   select_end: c_int,
   insert_mode: u8,
   row_count_per_page: c_int,
   cursor_at_end_of_line: u8,
   initialized: u8,
   has_preferred_x: u8,
   single_line: u8,
   padding1: u8,
   padding2: u8,
   padding3: u8,
   preferred_x: f32,
   undostate: StbUndoState,
};

pub extern fn Custom_ButtonBehaviorMiddleRight() void;
'''),
        Header(IMGUI_HEADER_INTERNAL,
               if_include=lambda f_name: f_name == 'ButtonBehavior'),
        Header(IMGUI_IMPL_GLFW),
        Header(IMGUI_IMPL_OPENGL3),
    ]

    generator = ZigGenerator(*headers)

    def custom(t: BaseType) -> Optional[str]:
        for template in ('ImVector', 'ImSpan', 'ImChunkStream', 'ImPool', 'ImBitArray'):
            if t.name.startswith(f'{template}<'):
                return template

        if t.name == 'ImStb::STB_TexteditState':
            return 'STB_TexteditState'

    workarounds = generator.generate(
        IMGUI_ZIG, custom=custom, return_byvalue_workaround=True)

    #
    # return byvalue to pointer
    #
    IMGUI_CPP_WORKAROUND = IMGUI_ZIG.parent / 'imvec2_byvalue.cpp'
    with IMGUI_CPP_WORKAROUND.open('w') as w:
        w.write(f'''// https://github.com/ziglang/zig/issues/1481 workaround
#include <imgui.h>

#ifdef __cplusplus
extern "C" {{
#endif
{"".join([w.code for w in workarounds if w.f.path == IMGUI_HEADER])}
#ifdef __cplusplus
}}
#endif        
''')


if __name__ == '__main__':
    coloredlogs.install(level='DEBUG')
    logging.basicConfig(level=logging.DEBUG)
    generate_glfw()
    generate_imgui()
