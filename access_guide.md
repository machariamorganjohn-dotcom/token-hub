# How to Access Token Hub

This guide explains how you can access and run the Token Hub application at any time.

## 1. Fast Access (Windows Desktop)
We have created a one-click launcher for you in the project folder:
- **File**: `run_token_hub.bat`
- **How to use**: Simply double-click this file to launch the app directly. You can copy this file to your actual Desktop for even faster access.

## 2. Web Access (Browser)
If you want to access the app from any device (phone, laptop, tablet), we recommend hosting it as a Web App (PWA).

### Deployment Options:
- **GitHub Pages (Free)**: Best for hosting the web version for free.
- **Firebase Hosting**: High performance and easy to scale.

### To build the web version:
Run the following command in your terminal:
```bash
flutter build web
```
The output will be in `build/web/`. You can upload these files to any web host.

## 3. Mobile Access (Android/iOS)
To run the app on your phone:
1. Connect your device via USB.
2. Run:
   ```bash
   flutter run
   ```
3. To build a permanent app:
   - **Android**: `flutter build apk`
   - **iOS**: `flutter build ios` (Requires macOS)

---
*Note: Make sure Flutter is installed and added to your system PATH for the scripts to work.*
