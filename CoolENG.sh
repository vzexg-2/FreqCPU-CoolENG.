#!/system/bin/sh

loading_animation() {
  local percentage=$1
  local dots=$((percentage / 2))
  local spaces=$((50 - dots))
  local middle_spaces=$((50 - (dots / 2)))
  printf "\r%${middle_spaces}s["
  printf "%${dots}s" | tr ' ' '='
  printf ">%${spaces}s]\t$percentage%%"
}

packages=$(pm list packages -3)

system_apps="com.android.system com.android.settings com.android.whatever"

echo "Cooling down CPU temperature, please wait..."
progress=0
while [ $progress -le 100 ]; do
  loading_animation $progress
  sleep 0.5
  progress=$((progress + 2))
done
echo "\nChecking your device temperature, please wait!"

while read -r package; do
  package_name=$(echo "$package" | cut -d":" -f2)
  match=false
  for app in $system_apps; do
    case "$package_name" in
      *"$app"*) match=true ;;
    esac
  done
  if [ "$match" = false ]; then
    am set-inactive "$package_name" true
  fi
done <<< "$packages"

temperature=$(dumpsys battery | grep temperature)
temperature_value=$(echo "$temperature" | cut -d ":" -f 2 | tr -d '[:space:]')

temperature_int="${temperature_value%C}"
if [ "$temperature_int" -lt 41 ]; then
  echo "Temperature is under 41 Celsius. Exiting."
  exit 0
else
  echo "\n[\033[1;31m!\033[0m] CoolENG: Your device seems to be overheating! Please wait while we try to get information about your device temperature and thermal services."
  sleep 8.5

  dumpsys battery
  dumpsys thermalservice

  sleep 2.5

  echo "Reducing temperature down, please wait! Do not exit while we're running commands to reduce your temperature."
  sleep 2.5

  setprop sys.performance.mode power-save
  settings put system screen_brightness 0
  settings put global background_process_limit 1

  echo "Reduced temperature. Please turn off your phone, do not use it for 10 minutes, and then you can restart your phone! Thanks for using CoolENG services."
  sleep 2.5

  sleep 600
  svc power shutdown
fi

