#!/bin/bash
echo "Building Flutter web app..."
flutter build web --release
echo "Copying files to root..."
cp -r build/web/* .
echo "Build complete!"