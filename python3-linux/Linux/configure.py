#!/usr/bin/env python3
import os

from util import env_vars, parse_args

def main():
    args, remaining = parse_args()
    os.environ.update(env_vars())

    # CPython requires explicit --build, and its value does not matter
    # (e.g., x86_64-linux-gnu should also work on macOS)
    cmd = [
        'bash', './configure',        
        '--build=x86_64-linux-gnu',
        '--enable-shared',
        'ac_cv_file__dev_ptmx=yes',
        'ac_cv_file__dev_ptc=no',
        'ac_cv_buggy_getaddrinfo=no',  # for IPv6 functionality
    ]

    os.execvp('bash', cmd + remaining)

if __name__ == '__main__':
    main()