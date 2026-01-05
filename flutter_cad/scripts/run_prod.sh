#!/bin/bash

echo "Starting Flutter app in PROD environment..."

flutter run \
  --dart-define=FLUTTER_FLAVOR=prod \
  --release
