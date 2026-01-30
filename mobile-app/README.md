 IoT MVP - Mobile App

React Native mobile application for iOS and Android built with Expo.

 Quick Start

```bash
 Install dependencies
npm install

 Start Expo dev server
npm start

 Run on specific platform
npm run android    Android emulator
npm run ios        iOS simulator
npm run web        Web browser
```

 Viewing the App

 Option 1: Expo Go (Easiest)
1. Install Expo Go app on your phone:
   - iOS: https://apps.apple.com/app/expo-go/id982107779
   - Android: https://play.google.com/store/apps/details?id=host.exp.exponent

2. Run `npm start`
3. Scan the QR code with:
   - iOS: Camera app
   - Android: Expo Go app

 Option 2: Web Browser
```bash
npm run web
 Opens at http://localhost:8081
```

 Option 3: Emulator/Simulator
- Android: Requires Android Studio with emulator
- iOS: Requires Xcode (macOS only)

 Features

✅ Real-time sensor monitoring (CO₂, temperature, humidity)  
✅ Device occupancy status  
✅ Pull-to-refresh  
✅ Color-coded health indicators  
✅ Battery level monitoring  
✅ Native mobile design  
✅ Cross-platform (iOS, Android, Web)

 Current Status

Currently displaying mock data for demonstration. To connect to real sensors, configure AWS endpoints in the app.

 Technologies

- React Native 0.73
- Expo SDK 50
- TypeScript
- React Navigation
- Expo Notifications

 License

Proprietary - IoT MVP Team, January 2026
