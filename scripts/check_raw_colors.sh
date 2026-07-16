#!/usr/bin/env bash
# CI check: no raw Color() or TextStyle() allowed in new design-system code.
#
# Scope: lib/design_system/, lib/features/, lib/services/, lib/core/
# Exclusion: lib/screens/ (legacy pre-Phase-06 code; tracked in issue #ds-screens-migration)
#
# Feature code must use FkTheme.of(context).* or FkColors.* / FkTextStyles.*

set -euo pipefail

LIB_DIR="$(dirname "$0")/../lib"
VIOLATIONS=0

check_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0

  while IFS= read -r -d '' file; do
    # Skip generated files
    if [[ "$file" == *".g.dart" ]] || [[ "$file" == *".freezed.dart" ]]; then
      continue
    fi
    # Skip design_system itself — it IS the source of truth for colors
    if [[ "$file" == *"/design_system/"* ]]; then
      continue
    fi

    local file_violated=0

    # Raw Color() hex constructors (allow Fk* references via import)
    if grep -En "Color\(0x[0-9a-fA-F]+\)|Colors\.[a-zA-Z]" "$file" \
        | grep -v "//.*Color" \
        | grep -q .; then
      echo "RAW COLOR in $file:"
      grep -En "Color\(0x[0-9a-fA-F]+\)|Colors\.[a-zA-Z]" "$file" \
        | grep -v "//.*Color" | head -5
      file_violated=1
    fi

    # Raw TextStyle() construction (not from FkTextStyles)
    if grep -En "TextStyle\(" "$file" \
        | grep -v "FkTextStyles\." \
        | grep -v "//.*TextStyle" \
        | grep -q .; then
      echo "RAW TEXTSTYLE in $file:"
      grep -En "TextStyle\(" "$file" \
        | grep -v "FkTextStyles\." \
        | grep -v "//.*TextStyle" | head -5
      file_violated=1
    fi

    VIOLATIONS=$((VIOLATIONS + file_violated))
  done < <(find "$dir" -name "*.dart" -print0)
}

check_dir "$LIB_DIR/features"
check_dir "$LIB_DIR/services"
check_dir "$LIB_DIR/core"

if [[ $VIOLATIONS -gt 0 ]]; then
  echo ""
  echo "❌ $VIOLATIONS file(s) with raw Color/TextStyle in new code."
  echo "   Use FkTheme.of(context).* or FkColors.* / FkTextStyles.* instead."
  exit 1
else
  echo "✅ No raw Color/TextStyle in design-system-governed code."
fi