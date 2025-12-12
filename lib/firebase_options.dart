// ignore_for_file: constant_identifier_names

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Dummy Firebase options placeholder. Replace with real values via FlutterFire CLI.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyALAwhfIGOb5i7ls65-4t7t_Qqrl_VpA7Q',
    appId: '1:733581949032:web:dfe3bf0a8cbdab236123dd',
    measurementId: 'G-NPPVK772DQ',
    messagingSenderId: '733581949032',
    projectId: 'recap-bq',
    authDomain: 'recap-bq.firebaseapp.com',
    storageBucket: 'recap-bq.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBxr8VKk9m2_CZehvr7Y0yyrwd6uQCbz-s',
    appId: '1:733581949032:android:6cb0417e68d591536123dd',
    messagingSenderId: '733581949032',
    projectId: 'recap-bq',
    storageBucket: 'recap-bq.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:ios:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'piket-asrama-pro',
    iosBundleId: 'com.example.piketAsramaPro',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:macos:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'piket-asrama-pro',
    iosBundleId: 'com.example.piketAsramaPro',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:windows:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'piket-asrama-pro',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:000000000000:linux:placeholder',
    messagingSenderId: '000000000000',
    projectId: 'piket-asrama-pro',
  );
}
