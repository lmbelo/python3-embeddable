import argparse
import os
import pathlib
from typing import Dict, Optional

BASE = pathlib.Path(__file__).resolve().parent
SYSROOT = BASE / 'sysroot'

def env_vars() -> Dict[str, str]:
    env = {
        # Compiler flags
        'CPPFLAGS': f'-I{SYSROOT}/usr/include',
        'LDFLAGS': f'-L{SYSROOT}/usr/lib',

        # pkg-config settings
        'PKG_CONFIG_SYSROOT_DIR': str(SYSROOT),
        'PKG_CONFIG_LIBDIR': str(SYSROOT / 'usr' / 'lib' / 'pkgconfig'),

        'PYTHONPATH': str(BASE),
    }

    return env

def parse_args():
    parser = argparse.ArgumentParser()
    return parser.parse_known_args()