"""swap one @icon block (its decorator and its function, nothing after) in a module: repl(path, name, new_source)"""
def repl(path, name, new):
    L = open(path).read().split('\n')
    a = next(i for i, l in enumerate(L) if l.startswith(f'@icon("{name}"'))
    d = next(i for i in range(a, len(L)) if L[i].startswith('def '))
    b = d + 1
    while b < len(L) and (L[b] == '' or L[b][0] in ' \t'): b += 1
    while b > d + 1 and L[b - 1] == '': b -= 1                      # leave the blank lines that follow
    out = L[:a] + new.strip('\n').split('\n') + L[b:]
    open(path, 'w').write('\n'.join(out).rstrip('\n') + '\n')
