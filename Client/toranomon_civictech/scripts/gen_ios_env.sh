#!/bin/sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$ROOT/.env"
XCCONFIG="$ROOT/ios/Config/Env.xcconfig"

# 右辺全体を取り出す（BOM/CRLF/コメントも考慮）
RAW="$(awk 'BEGIN{FS="="}
  NR==1{sub(/^\xEF\xBB\xBF/,"",$0)}            # BOM除去
  {gsub(/\r$/,"")}                             # CRLF→LF
  /^[[:space:]]*#/ || /^[[:space:]]*$/ {next}  # コメント/空行スキップ
  $1 ~ /^[[:space:]]*GOOGLE_MAPS_KEY_IOS[[:space:]]*$/ {
    sub(/^[^=]*=/,"",$0); print $0; exit
  }' "$ENV_FILE")"

# 前後空白除去 + 中の全ての空白を除去（タブ/改行/全角空白も）
CLEAN="$(printf "%s" "$RAW" \
  | tr -d '\n\r' \
  | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//' \
  | tr -d '[:space:]' \
  | sed -E 's/^["'\'']?(.*[^"'\'' ])[\"'\'']?$/\1/' \
)"

[ -n "$CLEAN" ] || { echo "[gen][ERR] GOOGLE_MAPS_KEY_IOS empty"; exit 1; }

mkdir -p "$(dirname "$XCCONFIG")"
printf "GMS_API_KEY=%s\n" "$CLEAN" > "$XCCONFIG"
echo "[gen] wrote $XCCONFIG (len=$(printf %s "$CLEAN" | wc -c | tr -d ' '))"
