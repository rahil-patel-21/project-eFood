import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_restaurant/main.dart';
import 'package:flutter_restaurant/utill/app_constants.dart';
import 'package:flutter_restaurant/view/screens/order/order_details_screen.dart';
import 'package:path_provider/path_provider.dart';

class MyNotification {

  static Future<void> initialize(FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    final FirebaseMessaging _fcm = FirebaseMessaging();
    var androidInitialize = new AndroidInitializationSettings('notification_icon');
    var iOSInitialize = new IOSInitializationSettings();
    var initializationsSettings = new InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
    flutterLocalNotificationsPlugin.initialize(initializationsSettings, onSelectNotification: (String payload) async {
      try{
        if(payload != null && payload.isNotEmpty) {
          MyApp.navigatorKey.currentState.push(
              MaterialPageRoute(builder: (context) => OrderDetailsScreen(orderModel: null, orderId: int.parse(payload))));
        }
      }catch (e) {
        
      }
      
      return;
    });

    _fcm.configure(
      onBackgroundMessage: myBackgroundMessageHandler,
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        MyNotification.showNotification(message, flutterLocalNotificationsPlugin);
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        MyNotification.showNotification(message, flutterLocalNotificationsPlugin);
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        MyNotification.showNotification(message, flutterLocalNotificationsPlugin);
      },
    );
  }

  static Future<void> showNotification(Map<String, dynamic> message, FlutterLocalNotificationsPlugin fln) async {
    if(message['data']['image'] != null && message['data']['image'].isNotEmpty) {
      try{
        await showBigPictureNotificationHiddenLargeIcon(message, fln);
      }catch(e) {
        await showBigTextNotification(message, fln);
      }
    }else {
      await showBigTextNotification(message, fln);
    }
  }

  static Future<void> showTextNotification(Map<String, dynamic> message, FlutterLocalNotificationsPlugin fln) async {
    String _title = message['data']['title'];
    String _body = message['data']['body'];
    String _orderID = message['data']['order_id'];
    const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your channel id', 'your channel name', 'your channel description', sound: RawResourceAndroidNotificationSound('notification'),
      importance: Importance.max, priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, _title, _body, platformChannelSpecifics, payload: _orderID);
  }

  static Future<void> showBigTextNotification(Map<String, dynamic> message, FlutterLocalNotificationsPlugin fln) async {
    String _title = message['data']['title'];
    String _body = message['data']['body'];
    String _orderID = message['data']['order_id'];
    BigTextStyleInformation bigTextStyleInformation = BigTextStyleInformation(
      _body, htmlFormatBigText: true,
      contentTitle: _title, htmlFormatContentTitle: true,
    );
    AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id', 'big text channel name', 'big text channel description', importance: Importance.max,
      styleInformation: bigTextStyleInformation, priority: Priority.high, sound: RawResourceAndroidNotificationSound('notification'),
    );
    NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, _title, _body, platformChannelSpecifics, payload: _orderID);
  }

  static Future<void> showBigPictureNotificationHiddenLargeIcon(Map<String, dynamic> message, FlutterLocalNotificationsPlugin fln) async {
    String _title = message['data']['title'];
    String _body = message['data']['body'];
    String _orderID = message['data']['order_id'];
    String _image = message['data']['image'].startsWith('http') ? message['data']['image']
        : '${AppConstants.BASE_URL}/storage/app/public/notification/${message['data']['image']}';
    final String largeIconPath = await _downloadAndSaveFile(_image, 'largeIcon');
    final String bigPicturePath = await _downloadAndSaveFile(_image, 'bigPicture');
    final BigPictureStyleInformation bigPictureStyleInformation = BigPictureStyleInformation(
      FilePathAndroidBitmap(bigPicturePath), hideExpandedLargeIcon: true,
      contentTitle: _title, htmlFormatContentTitle: true,
      summaryText: _body, htmlFormatSummaryText: true,
    );
    final AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'big text channel id', 'big text channel name', 'big text channel description',
      largeIcon: FilePathAndroidBitmap(largeIconPath), priority: Priority.high, sound: RawResourceAndroidNotificationSound('notification'),
      styleInformation: bigPictureStyleInformation, importance: Importance.max,
    );
    final NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
    await fln.show(0, _title, _body, platformChannelSpecifics, payload: _orderID);
  }

  static Future<String> _downloadAndSaveFile(String url, String fileName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String filePath = '${directory.path}/$fileName';
    final Response response = await Dio().get(url, options: Options(responseType: ResponseType.bytes));
    final File file = File(filePath);
    await file.writeAsBytes(response.data);
    return filePath;
  }

}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  print('background: $message}');
  var androidInitialize = new AndroidInitializationSettings('notification_icon');
  var iOSInitialize = new IOSInitializationSettings();
  var initializationsSettings = new InitializationSettings(android: androidInitialize, iOS: iOSInitialize);
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  flutterLocalNotificationsPlugin.initialize(initializationsSettings);
  MyNotification.showNotification(message, flutterLocalNotificationsPlugin);
}