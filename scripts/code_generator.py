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


if __name__ == '__main__':
    coloredlogs.install(level='DEBUG')
    logging.basicConfig(level=logging.DEBUG)
    generate_glfw()
