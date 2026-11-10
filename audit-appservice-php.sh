#!/usr/bin/env bash
#
# Audit PHP versions on Azure App Service web apps across every enabled
# subscription the signed-in account can see.
#
# Output CSV columns: Subscription, AppServiceName, ResourceGroup, PhpVersion
# PhpVersion is "DNE" when the app is not running PHP, and "ERROR" when its
# config could not be read (usually a permissions issue).
#
# Usage: ./audit-appservice-php.sh [output.csv]
# Requires: az CLI, logged in (az login). Compatible with bash 3.2+ (macOS default).

set -uo pipefail

OUTPUT="${1:-appservice-php-audit-$(date +%Y%m%d-%H%M%S).csv}"

command -v az >/dev/null 2>&1 || { echo "az CLI not found in PATH" >&2; exit 1; }
az account show >/dev/null 2>&1 || { echo "Not logged in. Run 'az login' first." >&2; exit 1; }

# Quote a value for CSV (wrap in quotes, double any embedded quotes).
csv() {
  local v="${1//\"/\"\"}"
  printf '"%s"' "$v"
}

echo '"Subscription","AppServiceName","ResourceGroup","PhpVersion"' > "$OUTPUT"

app_count=0

while IFS=$'\t' read -r sub_id sub_name <&3; do
  sub_name="${sub_name%$'\r'}"
  echo "Subscription: $sub_name ($sub_id)" >&2

  apps=$(az webapp list --subscription "$sub_id" \
           --query "[].[name, resourceGroup]" -o tsv 2>/dev/null | tr -d '\r')
  if [[ $? -ne 0 ]]; then
    echo "  Could not list web apps, skipping" >&2
    continue
  fi
  [[ -z "$apps" ]] && { echo "  No web apps" >&2; continue; }

  while IFS=$'\t' read -r app rg <&4; do
    echo "  $rg/$app" >&2

    # Return both fields as one "~"-delimited string so empty values don't
    # shift columns (linuxFxVersion itself contains "|").
    cfg=$(az webapp config show --subscription "$sub_id" --name "$app" --resource-group "$rg" \
            --query "join('~', [linuxFxVersion || '', phpVersion || ''])" -o tsv 2>/dev/null | tr -d '\r')

    if [[ -z "$cfg" ]]; then
      php_version="ERROR"
    else
      linux_fx="${cfg%%~*}"
      win_php="${cfg#*~}"
      php_version="DNE"

      if [[ -n "$linux_fx" ]]; then
        # Linux: runtime is "STACK|VERSION", e.g. "PHP|8.2"
        case "$linux_fx" in
          [Pp][Hh][Pp]\|*) php_version="${linux_fx#*|}" ;;
        esac
      elif [[ -n "$win_php" && "$win_php" != "Off" ]]; then
        # Windows: PHP is a separate per-language setting
        php_version="$win_php"
      fi
    fi

    printf '%s,%s,%s,%s\n' "$(csv "$sub_name")" "$(csv "$app")" "$(csv "$rg")" "$(csv "$php_version")" >> "$OUTPUT"
    app_count=$((app_count + 1))
  done 4<<< "$apps"

done 3< <(az account list --all --query "[?state=='Enabled'].[id, name]" -o tsv | tr -d '\r')

echo "Done. $app_count app(s) written to $OUTPUT" >&2