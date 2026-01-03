import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  static const FirebaseOptions webOptions = FirebaseOptions(
    apiKey: 'AIzaSyD5sI07jpSnLzoDD1bsD95JhEcmZWF_HpU',
    authDomain: 'billetera-2026.firebaseapp.com',
    projectId: 'billetera-2026',
    storageBucket: 'billetera-2026.firebasestorage.app',
    messagingSenderId: '20050080916',
    appId: '1:20050080916:web:2dc46b885d0566d67ab081',
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: webOptions);
  }
}
