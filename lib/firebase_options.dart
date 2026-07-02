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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC6uHdSwCRKqzu5a0709asIODgWynnqEe8',
    appId: '1:526759954364:web:poster86de2web',
    messagingSenderId: '526759954364',
    projectId: 'poster-86de2',
    storageBucket: 'poster-86de2.firebasestorage.app',
    authDomain: 'poster-86de2.firebaseapp.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC6uHdSwCRKqzu5a0709asIODgWynnqEe8',
    appId: '1:526759954364:android:60db26290b653c356ccdb9',
    messagingSenderId: '526759954364',
    projectId: 'poster-86de2',
    storageBucket: 'poster-86de2.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6uHdSwCRKqzu5a0709asIODgWynnqEe8',
    appId: '1:526759954364:ios:poster86de2ios',
    messagingSenderId: '526759954364',
    projectId: 'poster-86de2',
    storageBucket: 'poster-86de2.firebasestorage.app',
    iosBundleId: 'com.example.posterApplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6uHdSwCRKqzu5a0709asIODgWynnqEe8',
    appId: '1:526759954364:ios:poster86de2macos',
    messagingSenderId: '526759954364',
    projectId: 'poster-86de2',
    storageBucket: 'poster-86de2.firebasestorage.app',
    iosBundleId: 'com.example.posterApplication',
  );
}
