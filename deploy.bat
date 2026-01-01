@echo off
echo Building Flutter web app...
flutter build web --release --no-tree-shake-icons

echo Copying build files to public directory...
if exist public rmdir /s /q public
xcopy "build\web" "public" /E /I /Y

echo Deployment files ready!
echo You can now commit and push to trigger Vercel deployment.