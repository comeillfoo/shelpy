#!/usr/bin/env python3
import argparse, os, enum, subprocess as sp, sys
# from pprint import pprint


VISITED = {}
DEPTH = 8


class Function:
    def __init__(self, file: str, name: str, row):
        self.file = file
        self.name = name
        self.row = int(row)


    def __str__(self) -> str:
        return f'{self.file}:{self.name}:{self.row}'


    def label(self) -> str:
        return f'"{self.name}:{self.row}"'


    def id(self) -> str:
        return f'{self.name}_{self.row}'


class FunctionTypes(enum.IntEnum):
    Definition = 1 # find this global definition
    Called = 2 # called by this function
    Calling = 3  # calling this function


def parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog=os.path.basename(__file__).rstrip('.py'),
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
        '-d', '--depth',
        default=8,
        type=int,
        help='''
    The depth of searching in DFS, default 8
    '''
    )

    parser.add_argument(
        'function',
        help='the starting point of call graph building'
    )
    return parser


def cscope(kernel_mode: str, reffile: str, function: str, type: FunctionTypes) -> set[str]:
    option = f'-L{type.value}'
    cmd = f'cscope -d{kernel_mode} -f{reffile} {option} {function}'
    process = sp.Popen(cmd, stdout=sp.PIPE, shell=True)
    output = process.stdout.read().decode().strip()
    if output == '':
        return set()
    functions = output.split('\n')
    return set() if len(functions) == 0 else set(map(
        lambda found_f: Function(*found_f.split(maxsplit=3)[:3]), functions))


def confirm(prompt: str) -> bool:
    while True:
        answer = input(prompt)
        answer = answer.lower()
        if answer in 'yes' or answer in 'y':
            return True
        elif answer in 'no' or answer in 'n':
            return False


def self_search(kernel_mode: str, reffile: str, function: str) -> Function:
    definitions = cscope(kernel_mode, reffile, function, FunctionTypes.Definition)
    for definition in definitions:
        if confirm(f'Are you looking for {definition}? [Y/n]: '):
            return definition
    return None


def adjacents_search(kernel_mode: str, reffile: str, function: Function, direction: FunctionTypes, depth=0) -> tuple:
    global VISITED, DEPTH
    VISITED[function] = True
    functions = cscope(kernel_mode, reffile, function.name, direction)
    if not functions or depth >= DEPTH:
        return (function, None)
    children = frozenset(
            adjacents_search(
                kernel_mode,
                reffile,
                called,
                direction, depth=depth + 1) for called in functions if not VISITED.get(called, False))
    if not children:
        children = None
    return (function, children)


def _dir(a: str, b: str, dir: FunctionTypes) -> tuple:
    return (a, b) if dir == FunctionTypes.Called else (b, a)


def tree2dot(tree: tuple, dir: FunctionTypes, depth: int = 1) -> str:
    root, children = tree
    if children is None:
        return ''

    indent = '  ' * depth
    statements = ''
    if isinstance(children, frozenset):
        statements += indent + 'subgraph ' + root.id() + '_sg {\n'
        for child in children:
            child_root = child[0]
            (A, B) = _dir(root, child_root, dir)
            statements += f'{indent}  {A.id()} -> {B.id()};\n'
            if child[1] is None:
                continue
            statements += tree2dot(child, dir, depth + 1)
        statements += indent + '}\n'
    else:
        (A, B) = _dir(root, children, dir)
        statements += f'{indent}{A.id()} -> {B.id()};\n'
    return statements


def require_command(cmd: str) -> bool:
    location = sp.check_output(['which', cmd])
    return os.path.isfile(location)


def main() -> int:
    global VISITED, DEPTH
    if require_command('cscope'):
        print('cscope: command not found', file=sys.stderr)
        return 1

    args = parser().parse_args()
    if not os.path.exists(args.reffile):
        print(f'cannot find cross-reference file {args.reffile}')
        return -1
    kernel_mode = 'k' if args.kernel else ''
    DEPTH = args.depth

    tmp_out = sys.stdout
    sys.stdout = sys.stderr
    function = self_search(kernel_mode, args.reffile, args.function)
    sys.stdout = tmp_out

    if function is None:
        print('Function not found, check your input', file=sys.stderr)
        return 1

    # parents
    parents = adjacents_search(kernel_mode, args.reffile, function, FunctionTypes.Calling)
    # pprint(parents)

    # children
    children = adjacents_search(kernel_mode, args.reffile, function, FunctionTypes.Called)
    # pprint(children)

    print('digraph {')
    for function in VISITED:
        print(f'  {function.id()}[label={function.label()}];')
    print(tree2dot(parents, FunctionTypes.Calling))
    print(tree2dot(children, FunctionTypes.Called))
    print('}')
    return 0

if __name__ == '__main__':
    exit(main())