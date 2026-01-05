#!/bin/bash

echo "Starting Flutter app in DEV environment..."

flutter run \
  --dart-define=FLUTTER_FLAVOR=dev \
  --debug
