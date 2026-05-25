# Tutorial: Fix `dart format` CI Error (CRLF vs LF)

## Problem

CI fails with:

```
Formatted test/core/config/app_config_test.dart
Formatted test/core/router/app_router_test.dart
```

The step `dart format --set-exit-if-changed` exits with non-zero because it
modified those files. On Linux runners, `dart format` is strict about both
formatting and line endings.

## Root Cause

Two things collided:

1. **Real formatting violations** — the files weren't formatted by
   `dart format` before being committed. The formatter changed
   actual code style (line wrapping, argument layout, etc.).

2. **CRLF line endings** — the files were authored on Windows and committed
   with `\r\n` line endings. On Linux, `dart format` normalizes them to `\n`,
   which also counts as a change.

The project's `.gitattributes` declares `* text=auto eol=lf`, but files
committed *before* the `.gitattributes` was in place (or before it was
re-applied) keep their original endings in Git's object store.

## Why `.gitattributes` Alone Isn't Enough

`.gitattributes` tells Git how to normalize line endings **on checkout and on
the next write to the index**. It does **not** retroactively fix files that
were already committed with wrong endings.

Running `git add --renormalize .` re-applies the current `.gitattributes`
rules to all *tracked files* in the index, but:

- It only affects the index, not the working tree.
- If a file has CRLF in the index, the index gets LF after renormalize.
- But the working tree still has CRLF, so `dart format` on Linux will still
  see CRLF (because git checkout on Linux converts to LF) — wait, actually
  on Linux, git checkout with `eol=lf` always produces LF. The issue on
  Windows is the opposite: the working tree has CRLF, and `dart format`
  on Linux sees the file as-is (LF) and *also* reformats it.

**Key insight**: in this particular case, the CI failure was caused primarily
by actual formatting differences. `dart format` on *any* platform changed
these files. The CRLF was a secondary concern.

## The Fix (3 Steps)

### 1. Renormalize gitattributes (optional but good hygiene)

```bash
git add --renormalize .
```

This applies `.gitattributes` rules to all tracked files. If you see
changes in `git status`, stage and commit them.

### 2. Run `dart format` on the full project

```bash
dart format lib/ test/
```

Look at the output. If it says `(0 changed)`, you're done. If it names
files, those need to be committed.

### 3. Commit the formatted files

```bash
git add <formatted-files>
git commit -m "fix: apply dart format to test files"
```

The commit will normalize line endings because `.gitattributes` is already
set to `eol=lf`. Verify with:

```bash
dart format --set-exit-if-changed lib/ test/
# Should print: "Formatted N files (0 changed)"
# Exit code 0 = success
```

## How to Avoid It

1. **Add a git pre-commit hook** that runs `dart format` on staged files.
   Create `.git/hooks/pre-commit`:

   ```bash
   #!/bin/sh
   files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.dart$')
   [ -z "$files" ] && exit 0
   dart format "$files" && git add $files
   ```

   (Make it executable: `chmod +x .git/hooks/pre-commit`)

2. **Run `dart format` manually** before every commit. Make it muscle memory,
   or add an IDE hook (VS Code: `editor.formatOnSave` with the Dart extension).

3. **Use CI linting as a safety net**, not a gate. The pre-commit hook should
   catch this before it reaches the runner.

4. **Apply `.gitattributes` early** in the project lifecycle so all files
   committed after that point have correct line endings. For existing files
   with wrong endings, use `git add --renormalize .` once.
