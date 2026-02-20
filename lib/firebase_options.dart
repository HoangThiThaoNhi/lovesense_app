// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: public_member_api_docs, constant_identifier_names

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB9giSUQ_hM6-CCDRmHvx8LtsX388Zu25o',
    authDomain: 'lovesense.firebaseapp.com',
    projectId: 'lovesense',
    storageBucket: 'lovesense.firebasestorage.app',
    messagingSenderId: '696272841848',
    appId: '1:696272841848:web:ce173e1efc632f4719118d',
    measurementId: 'G-TSG96T525Y',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA9da7HNj4WhlgDA27y-iaxejHrbneWulQ',
    appId: '1:696272841848:android:1c2a41b8c50f325319118d',
    messagingSenderId: '696272841848',
    projectId: 'lovesense',
    storageBucket: 'lovesense.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB9giSUQ_hM6-CCDRmHvx8LtsX388Zu25o',
    appId: '1:696272841848:ios:REPLACE_WITH_IOS_APP_ID',
    messagingSenderId: '696272841848',
    projectId: 'lovesense',
    storageBucket: 'lovesense.firebasestorage.app',
    iosClientId: '',
    iosBundleId: 'com.example.lovesense_app',
  );
}
