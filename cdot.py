#!/usr/bin/env python3
import argparse, os, enum, subprocess


# TODO: add tracking of visited functions (by file, row and function name)


class FunctionTypes(enum.IntEnum):
    Called = 2 # called by this function
    Calling = 3  # calling this function


def parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog='cdot',
        description='drawing call graph')

    parser.add_argument(
        '-f',
        default='cscope.out',
        dest='reffile',
        help='''
    Use reffile as the cross-reference file name instead of the default
    \"cscope.out\".
    ''')

    parser.add_argument(
        '-k', '--kernel',
        default=False,
        action='store_true',
        help='''
    ``Kernel Mode'', turns off the use of the default include dir (usually
    /usr/include) when building the database, since kernel source trees generally do
    not use it.
    ''')

    parser.add_argument(
        'function',
        help='the starting point of call graph building'
    )
    return parser


def cscope(kernel_mode: str, reffile: str, function: str, type: FunctionTypes) -> set[str]:
    option = f'-L{type.value}'
    cmd = f'cscope -d{kernel_mode} -f{reffile} {option} {function}'
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
    output = process.stdout.read().decode().strip()
    if output == '':
        return set()
    functions = output.split('\n')
    return set() if len(functions) == 0 else set(map(
        lambda found_f: found_f.split(maxsplit=3)[1], functions))


def adjacents_search(kernel_mode: str, reffile: str, function: str, direction: FunctionTypes) -> tuple:
    functions = cscope(kernel_mode, reffile, function, direction)
    if not functions:
        return (function, None)
    return (
        function, set(
            adjacents_search(
                kernel_mode,
                reffile,
                called,
                direction) for called in functions)
    )


def _dir(a: str, b: str, dir: FunctionTypes) -> tuple:
    return (a, b) if dir == FunctionTypes.Called else (b, a)


def tree2dot(tree: tuple, dir: FunctionTypes, depth: int = 1) -> str:
    root, children = tree
    if children is None:
        return ''

    indent = ' ' * depth
    statements = ''
    if children is set:
        for child in children:
            child_root = child if child is str else child[0]
            (A, B) = _dir(root, child_root, dir)
            statements += f'{indent}{A} -> {B};\n'
            if child is str:
                continue
            statements += tree2dot(child, dir, depth + 1)
    else:
        (A, B) = _dir(root, children, dir)
        statements += f'{indent}{A} -> {B};\n'
    return statements


def main() -> int:
    args = parser().parse_args()
    if not os.path.exists(args.reffile):
        print(f'cannot find cross-reference file {args.reffile}')
        return -1
    kernel_mode = 'k' if args.kernel else ''

    # parents
    parents = adjacents_search(kernel_mode, args.reffile, args.function, FunctionTypes.Calling)

    # children
    children = adjacents_search(kernel_mode, args.reffile, args.function, FunctionTypes.Called)

    print('graph {')
    print(tree2dot(parents))
    print(tree2dot(children))
    print('}')
    return 0

if __name__ == '__main__':
    exit(main())