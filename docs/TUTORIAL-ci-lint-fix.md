# CI Lint Fix: `no_leading_underscores_for_local_identifiers`

## Error

```
info • The local variable '_navigateAndCheckRedirect' starts with an underscore.
Try renaming the variable to not start with an underscore
• test/core/router/app_router_test.dart:278:18 • no_leading_underscores_for_local_identifiers
```

## What happened

A local function (defined inside a test body) was named `_navigateAndCheckRedirect`. In Dart, the leading underscore means "library-private" — it makes a **top-level** or **class-level** declaration visible only within its library. But for **local** variables and functions (those defined inside a method body), there is no concept of privacy: they already are invisible outside their scope.

The lint rule `no_leading_underscores_for_local_identifiers` flags this because a leading underscore on a local declaration is misleading — it pretends to enforce privacy where no privacy mechanism applies.

## How it was fixed

1. Renamed `_navigateAndCheckRedirect` → `navigateAndCheckRedirect` at the definition site (line 278).
2. Updated all 4 call sites using the same name.

File: `test/core/router/app_router_test.dart`

## How to avoid it

- Local variables/functions inside a test, method, or function body should **never** start with `_`.
- Only use `_` for **field-level** or **top-level** declarations that should be library-private.
- Run `flutter analyze` locally before pushing — it catches this immediately.

## Why this matters for CI

Flutter's `analyze` runs with `--fatal-infos` in CI (or should). Even `info`-level lints fail the pipeline. Keeping the codebase lint-clean avoids surprises in PR checks.
