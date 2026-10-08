// File generated for MPS School Management System.
// Configuration for Firebase Project: tutorfee-83839

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBS5taMXzp5UA2WixCba0tQZCvjKJYTqPw',
    appId: '1:406689542862:web:d8b0f482ad7cb72660569f',
    messagingSenderId: '406689542862',
    projectId: 'tutorfee-83839',
    authDomain: 'tutorfee-83839.firebaseapp.com',
    storageBucket: 'tutorfee-83839.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoIUn_WyWXWyZtTVa3uIt8_jvPbXYW2bE',
    appId: '1:406689542862:android:56c8d620f4e9ba6a60569f',
    messagingSenderId: '406689542862',
    projectId: 'tutorfee-83839',
    storageBucket: 'tutorfee-83839.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAZdqq0pbZqglicno89fdBs6DFc4AZzfRI',
    appId: '1:406689542862:ios:3f6a3b1db3c9d8f360569f',
    messagingSenderId: '406689542862',
    projectId: 'tutorfee-83839',
    storageBucket: 'tutorfee-83839.firebasestorage.app',
    iosBundleId: 'com.mps.myapplication',
  );
}
