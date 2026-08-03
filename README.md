# whm-timezone-updater-script
WHM/CPanel timezone Updator

chmod +x set-php-timezone.sh

# فقط ببین چی هست، بدون تغییر:
DRY_RUN=1 ./set-php-timezone.sh Asia/Tehran

# اعمال تغییر:
./set-php-timezone.sh Asia/Tehran

# اعمال + ری‌استارت PHP-FPM و Apache:
RESTART=1 ./set-php-timezone.sh America/New_York
