#!/bin/bash

echo "Starting Flutter app in TEST environment..."

flutter run \
  --dart-define=FLUTTER_FLAVOR=test \
  --debug
