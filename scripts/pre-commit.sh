#!/usr/bin/env bash
# Pre-commit hook: corre dart format en archivos .dart staged
# Instalación: copiar a .git/hooks/pre-commit (sin extensión)
#
# Previene errores de CI por formato al asegurar que todo
# el código Dart commitiado está correctamente formateado.

set -e

staged_files=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.dart$' || true)

if [ -z "$staged_files" ]; then
    exit 0
fi

echo "🎨 Formateando archivos Dart staged..."

# Guardar el estado de staging original
old_stash=$(git rev-parse HEAD)

# Formatear los archivos staged
dart format $staged_files

# Re-staged Los archivos que formateamos
echo "$staged_files" | xargs git add

echo "✅ dart format completado"
