#!/usr/bin/env python3
import os

from util import env_vars

def main():
    os.environ.update(env_vars())

    cmd = [
        'bash', 
        './configure',
        '--build=x86_64-linux-gnu',
        '--enable-shared',
        'ac_cv_file__dev_ptmx=yes',
        'ac_cv_file__dev_ptc=no',
        'ac_cv_buggy_getaddrinfo=no',  # for IPv6 functionality
    ]

    os.execvp('bash', cmd)

if __name__ == '__main__':
    main()