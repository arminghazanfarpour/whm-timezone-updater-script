#!/usr/bin/env bash
# Created By Armin Ghazanfarpour - (OnlineMizban.Net)
# set-php-timezone.sh
# Show and set date.timezone across every EasyApache 4 PHP version on cPanel.
#
# Usage:
#   ./set-php-timezone.sh                 # defaults to UTC
#   ./set-php-timezone.sh America/New_York
#   DRY_RUN=1 ./set-php-timezone.sh Asia/Tehran   # preview only, no writes
#   RESTART=1 ./set-php-timezone.sh Asia/Tehran  # also restart PHP-FPM + Apache
#
set -euo pipefail

# ---- Config ----
TIMEZONE="${1:-UTC}"                        # first arg = timezone (default UTC)
GLOB="/opt/cpanel/ea-php*/root/etc/php.ini" # EA4 per-version php.ini files
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
DRY_RUN="${DRY_RUN:-0}"                      # DRY_RUN=1 -> preview only
RESTART="${RESTART:-0}"                      # RESTART=1 -> restart services after

# ---- Guards ----
if [[ $EUID -ne 0 ]]; then
    echo "Error: run this as root." >&2
    exit 1
fi

# Validate the timezone against the system tz database
if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
    echo "Error: '$TIMEZONE' is not a valid timezone." >&2
    echo "Examples: UTC, America/New_York, Europe/London, Asia/Tehran" >&2
    exit 1
fi

# ---- Find files ----
shopt -s nullglob
files=($GLOB)
if [[ ${#files[@]} -eq 0 ]]; then
    echo "No php.ini files found matching: $GLOB" >&2
    echo "Is this an EasyApache 4 / cPanel server?" >&2
    exit 1
fi

# ---- Apply ----
changed=0
for ini in "${files[@]}"; do
    php_ver=$(grep -oE 'ea-php[0-9]+' <<<"$ini")
    current=$(grep -iE '^[[:space:]]*;?[[:space:]]*date\.timezone' "$ini" | head -n1 || true)

    echo "== $php_ver  ($ini)"
    echo "   current: ${current:-<not set>}"

    if [[ "$DRY_RUN" == "1" ]]; then
        echo "   [dry-run] would set: date.timezone = $TIMEZONE"
        continue
    fi

    cp -a "$ini" "${ini}${BACKUP_SUFFIX}"

    # Remove any existing date.timezone lines (commented or active), then add one clean line.
    # PHP core directives are read regardless of ini section, so appending at the end is safe.
    sed -i -E '/^[[:space:]]*;?[[:space:]]*date\.timezone[[:space:]]*=/Id' "$ini"
    printf 'date.timezone = %s\n' "$TIMEZONE" >> "$ini"

    echo "   new:     date.timezone = $TIMEZONE   (backup: ${ini}${BACKUP_SUFFIX})"
    changed=$((changed + 1))
done

echo
echo "Done. Updated $changed file(s)."

# ---- Optional restart so PHP-FPM picks up the change ----
if [[ "$DRY_RUN" != "1" && "$RESTART" == "1" ]]; then
    echo "Restarting services..."
    [[ -x /usr/local/cpanel/scripts/restartsrv_apache_php_fpm ]] && \
        /usr/local/cpanel/scripts/restartsrv_apache_php_fpm restart || true
    [[ -x /usr/local/cpanel/scripts/restartsrv_httpd ]] && \
        /usr/local/cpanel/scripts/restartsrv_httpd restart || true
fi
