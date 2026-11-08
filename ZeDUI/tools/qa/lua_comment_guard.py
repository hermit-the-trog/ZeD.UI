#!/usr/bin/env python3
"""Prove a Lua edit touched comments only.

Strips comments (line, inline, and --[=*[ long form), collapses whitespace in
code (never inside strings), drops blank lines, and compares the result for
the committed version (git show HEAD:<file>) against the working tree.
Any difference means code or strings changed -> FAIL.

Usage:
  python3 lua_comment_guard.py <repo_root> <file...>      # explicit files
  python3 lua_comment_guard.py <repo_root> --changed      # all *.lua changed vs HEAD
Exit 0 = all files comment-only. Exit 1 = any FAIL (details printed).
"""
import os
import subprocess
import sys

REF = os.environ.get("GUARD_REF", "HEAD")


def strip_lua(src, name):
    """Return normalized code-only lines. Raises ValueError on unterminated tokens."""
    out_chars = []
    i, n = 0, len(src)
    CODE, SSTR, LSTR, LCOM, LINECOM = range(5)
    state = CODE
    quote = ""
    level = 0
    last_was_space = False

    def emit(ch, in_string):
        nonlocal last_was_space
        if in_string:
            out_chars.append(ch)
            last_was_space = False
            return
        if ch == "\n":
            out_chars.append(ch)
            last_was_space = False
        elif ch in " \t":
            if not last_was_space and out_chars and out_chars[-1] != "\n":
                out_chars.append(" ")
            last_was_space = True
        else:
            out_chars.append(ch)
            last_was_space = False

    def long_open(pos):
        """If src[pos:] opens a long bracket, return (level, len); else None."""
        if pos < n and src[pos] == "[":
            m = pos + 1
            eq = 0
            while m < n and src[m] == "=":
                eq += 1
                m += 1
            if m < n and src[m] == "[":
                return eq, (m + 1 - pos)
        return None

    while i < n:
        c = src[i]
        if state == CODE:
            if c == "-" and src[i : i + 2] == "--":
                lo = long_open(i + 2)
                if lo:
                    level = lo[0]
                    i += 2 + lo[1]
                    state = LCOM
                else:
                    i += 2
                    state = LINECOM
                continue
            if c in "\"'":
                quote = c
                emit(c, True)
                i += 1
                state = SSTR
                continue
            lo = long_open(i)
            if lo:
                level = lo[0]
                for ch in src[i : i + lo[1]]:
                    emit(ch, True)
                i += lo[1]
                state = LSTR
                continue
            emit(c, False)
            i += 1
        elif state == LINECOM:
            if c == "\n":
                emit("\n", False)
                state = CODE
            i += 1
        elif state == SSTR:
            if c == "\\" and i + 1 < n:
                emit(c, True)
                emit(src[i + 1], True)
                i += 2
                continue
            if c == "\n":
                raise ValueError("%s: unterminated string" % name)
            emit(c, True)
            if c == quote:
                state = CODE
            i += 1
        elif state == LSTR:
            close = "]" + "=" * level + "]"
            if src.startswith(close, i):
                for ch in close:
                    emit(ch, True)
                i += len(close)
                state = CODE
            else:
                emit(c, True)
                i += 1
        elif state == LCOM:
            close = "]" + "=" * level + "]"
            if src.startswith(close, i):
                i += len(close)
                state = CODE
            else:
                if c == "\n":
                    emit("\n", False)  # keep line structure stable around long comments
                i += 1

    if state in (LSTR,):
        raise ValueError("%s: unterminated long string" % name)
    if state in (LCOM,):
        raise ValueError("%s: unterminated long comment" % name)
    if state == SSTR:
        raise ValueError("%s: unterminated string at EOF" % name)

    lines = "".join(out_chars).split("\n")
    return [ln.rstrip() for ln in lines if ln.strip()]


def head_version(root, path):
    r = subprocess.run(
        ["git", "-C", root, "show", REF + ":" + path],
        capture_output=True,
    )
    if r.returncode != 0:
        return None  # new file (no HEAD version)
    return r.stdout.decode("utf-8", "replace")


def main():
    root = sys.argv[1]
    if sys.argv[2] == "--changed":
        r = subprocess.run(
            ["git", "-C", root, "diff", "--name-only", REF],
            capture_output=True,
            text=True,
            check=True,
        )
        files = [f for f in r.stdout.splitlines() if f.endswith(".lua")]
    else:
        files = sys.argv[2:]

    failed = []
    for f in files:
        try:
            new_src = open(root + "/" + f, encoding="utf-8", errors="replace").read()
        except FileNotFoundError:
            failed.append((f, "deleted from working tree"))
            continue
        old_src = head_version(root, f)
        try:
            new_code = strip_lua(new_src, f + " (new)")
        except ValueError as e:
            failed.append((f, str(e)))
            continue
        if old_src is None:
            failed.append((f, "file is new (not in HEAD) - not allowed in this pass"))
            continue
        try:
            old_code = strip_lua(old_src, f + " (HEAD)")
        except ValueError as e:
            failed.append((f, "HEAD unparsable: " + str(e)))
            continue
        if old_code != new_code:
            detail = "code line count %d -> %d" % (len(old_code), len(new_code))
            for idx in range(min(len(old_code), len(new_code))):
                if old_code[idx] != new_code[idx]:
                    detail += "\n  first divergence (code line %d):\n  HEAD: %r\n  now : %r" % (
                        idx + 1,
                        old_code[idx][:160],
                        new_code[idx][:160],
                    )
                    break
            else:
                longer = old_code if len(old_code) > len(new_code) else new_code
                which = "HEAD" if len(old_code) > len(new_code) else "now"
                detail += "\n  extra code line (%s): %r" % (which, longer[min(len(old_code), len(new_code))][:160])
            failed.append((f, detail))

    if failed:
        print("FAIL: %d of %d file(s) changed more than comments" % (len(failed), len(files)))
        for f, why in failed:
            print("\n== %s\n%s" % (f, why))
        sys.exit(1)
    print("OK: %d file(s), comments-only confirmed" % len(files))


if __name__ == "__main__":
    main()
