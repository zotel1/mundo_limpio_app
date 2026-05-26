#!/bin/bash
# Script para crear un tag de release y pushearlo.
# Usar: ./scripts/tag-release.sh v1.0.0
# O sin argumentos para usar la version de pubspec.yaml

set -euo pipefail

if [ $# -eq 1 ]; then
  VERSION="$1"
else
  # Extraer version de pubspec.yaml
  VERSION=$(grep '^version: ' pubspec.yaml | awk '{print $2}')
fi

echo "Creando tag v${VERSION}..."
git tag "v${VERSION}"
echo "Pusheando tag v${VERSION}..."
git push origin "v${VERSION}"
echo "Tag v${VERSION} creado y pusheado correctamente."