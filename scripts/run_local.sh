#!/bin/bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

"$ANDROID_HOME/platform-tools/adb" start-server >/dev/null 2>&1
if ! "$ANDROID_HOME/platform-tools/adb" devices | grep -q "emulator-5554"; then
  echo "📱 Starting Android emulator (Quick Boot)..."
  "$ANDROID_HOME/emulator/emulator" \
    -avd topik-go-api35 \
    -netdelay none \
    -netspeed full > /tmp/topik-emulator.log 2>&1 &

  echo "⏳ Waiting for emulator..."
  until [ "$("$ANDROID_HOME/platform-tools/adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 1
  done
fi

flutter run -d emulator-5554 \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000 "$@"
