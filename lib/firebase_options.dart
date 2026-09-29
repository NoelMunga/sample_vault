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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAlA9H2aIaWg1my5ha5QI9z44mx0Jb1hU4',
    appId: '1:857450444526:web:da59745ed400ab2f8a25ff',
    messagingSenderId: '857450444526',
    projectId: 'sample-vault-6817c',
    authDomain: 'sample-vault-6817c.firebaseapp.com',
    storageBucket: 'sample-vault-6817c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAlA9H2aIaWg1my5ha5QI9z44mx0Jb1hU4',
    appId: 'com.example.sample_vault',
    messagingSenderId: '857450444526',
    projectId: 'sample-vault-6817c',
    storageBucket: 'sample-vault-6817c.firebasestorage.app',
  );
}