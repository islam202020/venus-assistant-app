import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // **NEW**: Import for web check

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // **FIX**: If running on the web, do nothing and exit.
    if (kIsWeb) {
      print("FCM is not initialized on the web.");
      return;
    }

    await _firebaseMessaging.requestPermission();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
      }
    });
  }

  Future<void> saveTokenToDatabase(String userId) async {
    // This part is already protected by a web check in main.dart,
    // but another check here is good practice.
    if (kIsWeb) return;

    String? token = await _firebaseMessaging.getToken();

    if (token != null) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      print("FCM Token saved for user $userId");
    }
  }
}
