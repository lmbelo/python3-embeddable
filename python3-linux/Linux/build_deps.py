#!/usr/bin/env python3
import shlex
import logging
import os
import re
import subprocess
from typing import List

from util import BASE, SYSROOT, env_vars

logger = logging.getLogger(__name__)

class Package:
    def __init__(self):
        pass

    def run(self, cmd: List[str]):
        cwd = BASE / 'deps' / re.sub(r'\.tar\..*', '', os.path.basename(self.source))
        logger.debug(f'Running in {cwd}: ' + ' '.join([shlex.quote(str(arg)) for arg in cmd]))
        subprocess.check_call(cmd, cwd=cwd)

    def build(self):
        self.configure()
        self.make()
        self.make_install()

    def configure(self):
        self.run([
            './configure',
            '--prefix=/usr',
            '--libdir=/usr/lib',            
            '--disable-shared',
        ] + getattr(self, 'configure_args', []))

    def make(self):
        self.run(['make'])

    def make_install(self):
        self.run(['make', 'install', f'DESTDIR={SYSROOT}'])

class BZip2(Package):
    source = 'https://sourceware.org/pub/bzip2/bzip2-1.0.8.tar.gz'

    def configure(self):
        pass

    def make(self):
        self.run([
            'make', 'libbz2.a',
            f'CFLAGS={os.environ["CFLAGS"]} {os.environ["CPPFLAGS"]}',
        ])

    def make_install(self):
        # The install target in bzip2's Makefile needs too many fixes -
        # Installing files manually is simpler.
        self.run(['install', '-Dm644', 'libbz2.a', '-t', str(SYSROOT / 'usr' / 'lib')])
        self.run(['install', '-Dm644', 'bzlib.h', '-t', str(SYSROOT / 'usr' / 'include')])

class GDBM(Package):
    source = 'https://ftp.gnu.org/gnu/gdbm/gdbm-1.19.tar.gz'
    configure_args = ['--enable-libgdbm-compat']

class LibFFI(Package):
    source = 'https://github.com/libffi/libffi/releases/download/v3.3/libffi-3.3.tar.gz'
    # libffi may fail to configure with Docker on WSL2 (#33)
    configure_args = ['--disable-builddir']

class LibUUID(Package):
    source = 'https://mirrors.edge.kernel.org/pub/linux/utils/util-linux/v2.36/util-linux-2.36.tar.xz'
    configure_args = ['--disable-all-programs', '--enable-libuuid']

class NCurses(Package):
    #source = 'https://invisible-mirror.net/archives/ncurses/ncurses-6.2.tar.gz'
    source = 'https://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.2.tar.gz'
    # Not stripping the binaries as there is no easy way to specify the strip program for Android
    configure_args = ['--without-ada', '--enable-widec', '--without-debug', '--without-cxx-binding']

class OpenSSL(Package):
    source = 'https://www.openssl.org/source/openssl-1.1.1n.tar.gz'

    def configure(self):       
        self.run(['./Configure', '--prefix=/usr', '--openssldir=/etc/ssl', 'linux-x86_64', 'no-shared', 'no-tests'])

    def make_install(self):
        self.run(['make', 'install_sw', 'install_ssldirs', f'DESTDIR={SYSROOT}'])

class Readline(Package):
    source = 'https://ftp.gnu.org/gnu/readline/readline-8.0.tar.gz'

    # See the wcwidth() test in aclocal.m4. Tested on Android 6.0 and it's broken
    # XXX: wcwidth() is implemented in [1], which may be in Android P
    # Need a conditional configuration then?
    # [1] https://android.googlesource.com/platform/bionic/+/c41b560f5f624cbf40febd0a3ec0b2a3f74b8e42
    configure_args = ['bash_cv_wcwidth_broken=yes']

class SQLite(Package):
    source = 'https://sqlite.org/2020/sqlite-autoconf-3330000.tar.gz'

class XZ(Package):
    source = 'https://tukaani.org/xz/xz-5.2.5.tar.xz'

class ZLib(Package):
    source = 'https://zlib.net/fossils/zlib-1.2.12.tar.gz'

    def configure(self):
        os.environ.update({            
            'CFLAGS': ' '.join([os.environ['CPPFLAGS'], os.environ['CFLAGS']]),
        })

        self.run([
            './configure',
            '--prefix=/usr',            
            '--libdir=/usr/lib',  
            '--static',
        ])

    def make(self):
        self.run(['make', 'libz.a'])

def build_package(pkg: Package):
    subprocess.check_call(['curl', '-fLO', pkg.source], cwd=BASE / 'deps')
    subprocess.check_call(['tar', '--no-same-owner', '-xf', os.path.basename(pkg.source)], cwd=BASE / 'deps')

    try:
        saved_env = os.environ.copy()
        pkg.build()
    finally:
        os.environ.clear()
        os.environ.update(saved_env)

def main():
    logging.basicConfig(level=logging.DEBUG)

    os.environ.update(env_vars())

    (BASE / 'deps').mkdir(exist_ok=True)
    SYSROOT.mkdir(exist_ok=True)

    package_classes = (
        # ncurses is a dependency of readline
        NCurses,
        BZip2, 
        GDBM, 
        LibFFI, LibUUID, 
        OpenSSL, 
        Readline, SQLite, XZ, ZLib,
    )

    for pkg_cls in package_classes:
        build_package(pkg_cls())

if __name__ == '__main__':
    main()
