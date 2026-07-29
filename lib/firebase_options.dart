// File generated for Firebase Web App.
// ignore_for_file: type=lint
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for android.',
        );
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDlcfyyDOYRFuM6e4eVM_Iqm0dlg_g2dAA',
    appId: '1:898023703149:web:fd40b25501e34148817564',
    messagingSenderId: '898023703149',
    projectId: 'hmpi-calculator-69b9b',
    authDomain: 'hmpi-calculator-69b9b.firebaseapp.com',
    storageBucket: 'hmpi-calculator-69b9b.firebasestorage.app',
  );
}
