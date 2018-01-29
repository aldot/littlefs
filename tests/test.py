#!/usr/bin/env python

import re
import sys
import subprocess
import os

source_file = os.environ.get('CFILE')
testname = None

if source_file is not None:
    source_file = os.path.splitext(source_file)[0]
    testname = os.path.basename(source_file)
    source_file += '.c'
else:
    source_file = 'test.c'
    testname = 'lfs'

def generate(test):
    with open("tests/template.fmt") as file:
        template = file.read()

    lines = []
    for line in re.split('(?<=[;{}])\n', test.read()):
        match = re.match('(?: *\n)*( *)(.*)=>(.*);', line, re.DOTALL | re.MULTILINE)
        if match:
            tab, test, expect = match.groups()
            lines.append(tab+'test = {test};'.format(test=test.strip()))
            lines.append(tab+'test_assert("{name}", test, {expect});'.format(
                    name = re.match('\w*', test.strip()).group(),
                    expect = expect.strip()))
        else:
            lines.append(line)

    with open(source_file, 'w') as file:
        file.write(template.format(tests='\n'.join(lines), testname=testname))

def compile():
    subprocess.check_call(['make', '--no-print-directory', '-s', testname])

def execute():
    subprocess.check_call([os.path.join('.', testname)])

def main(test=None):
    if test and not test.startswith('-'):
        with open(test) as file:
            generate(file)
    else:
        generate(sys.stdin)

    compile()

    if test == '-s':
        sys.exit(1)

    execute()

if __name__ == "__main__":
    main(*sys.argv[1:])
