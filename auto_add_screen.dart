import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart' as path;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../httpRequest.dart';

class AutoAddScreen extends StatefulWidget {
  const AutoAddScreen({Key? key}) : super(key: key);

  @override
  State<AutoAddScreen> createState() => _AutoAddScreenState();
}

class _AutoAddScreenState extends State<AutoAddScreen> {
  String expiry = '';
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  FirebaseDatabase database = FirebaseDatabase.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isLoading = false;
  bool _isImageSelected = false;
  String imageUrl = "";
  final product = TextEditingController();


  Future<void> _upload(String inputSource) async {
    setState(() {
      _isLoading = true;
    });
    final picker = ImagePicker();
    XFile? pickedImage;
    try {
      pickedImage = await picker.pickImage(
          source: inputSource == 'camera'
              ? ImageSource.camera
              : ImageSource.gallery,
          maxWidth: 1920);

      final String fileName = path.basename(pickedImage!.path);
      File imageFile = File(pickedImage.path);

      try {
        // Uploading the selected image with some custom meta data
        TaskSnapshot snapshot = await storage.ref(fileName).putFile(
            imageFile,
            SettableMetadata(customMetadata: {
              'uploaded_by': 'admin',
              'description': 'Expiry Detail'
            }));
        if (snapshot.state == TaskState.success) {
          // final String downloadUrl = await snapshot.ref.getDownloadURL();
          imageUrl = await snapshot.ref.getDownloadURL();
          print("###############");
          print(imageUrl);
          Future.delayed(const Duration(milliseconds: 10000));
        }

        // Refresh the UI
        setState(() {
          _isLoading = false;
          _isImageSelected = true;
        });
      } on FirebaseException catch (error) {
        if (kDebugMode) {
          print(error);
        }
      }
    } catch (err) {
      if (kDebugMode) {
        print(err);
      }
    }
  }

  void _addProduct() async{
    setState(() {
      _isLoading = true;
    });
    Map expiryData = json.decode(await getData(imageUrl));
    String uid = auth.currentUser?.uid??"";
    DatabaseReference ref = database.ref("products/" + uid).push();
    expiry = expiryData["exp_date"];
    await ref.set({
      "name": product.text,
      "url": imageUrl,
      "metaData": {
        "exp_date": expiryData['exp_date'],
        "mfg_date": expiryData['mfg_date']
      },
    });
    scheduleNotificationOneWeek(product.text);
    scheduleNotificationTwoWeek(product.text);
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pop(true);
  }

  Future<void> scheduleNotificationOneWeek(String productName) async {
    final DateTime expiryDate = HttpDate.parse(expiry).subtract(Duration(days: 7));
    // final DateTime expiryDate = DateTime.now().add(Duration(seconds: 30));
    final scheduledDate = tz.TZDateTime.from(expiryDate, tz.local);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        12345,
        "Alert!!! Product is Expiring",
        productName + " is about to expire in a week!!",
        scheduledDate,
        const NotificationDetails(
            android: AndroidNotificationDetails(
                '123',
                'Expiry Reminder',
            )
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime
    );
  }

  Future<void> scheduleNotificationTwoWeek(String productName) async {
    final DateTime expiryDate = HttpDate.parse(expiry).subtract(Duration(days: 14));
    // final DateTime expiryDate = DateTime.now().add(Duration(seconds: 30));
    final scheduledDate = tz.TZDateTime.from(expiryDate, tz.local);
    await flutterLocalNotificationsPlugin.zonedSchedule(
        1234567,
        "Alert!!! Product is Expiring",
        productName + " is about to expire in 2 Weeks!!",
        scheduledDate,
        const NotificationDetails(
            android: AndroidNotificationDetails(
              '123',
              'Expiry Reminder',
            )
        ),
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime
    );
  }

  @override
  void initState() {
    super.initState();
    var initializationSettingsAndroid = AndroidInitializationSettings('launch_background');
    var initializationSettingsIOs = IOSInitializationSettings();
    var initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOs,
    );
    flutterLocalNotificationsPlugin.initialize(
        initSettings,
    );
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
  }

  // void onSelectNotification() {
  //   Navigator.of(context).pushNamed('home_screen');
  //   }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('ADD PRODUCT'),
      ),
      body: _isLoading? const Center(child: CircularProgressIndicator(),) : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                    onPressed: () => _upload('camera'),
                    icon: const Icon(Icons.camera),
                    label: const Text('camera')),
                ElevatedButton.icon(
                    onPressed: () => _upload('gallery'),
                    icon: const Icon(Icons.library_add),
                    label: const Text('Gallery')),
              ],
            ),
            if(_isImageSelected) Text('Image Selected'),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: TextField(
                controller: product,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 15.0, vertical: 15.0),
                  fillColor: Colors.white,
                  filled: true,
                  hintText: 'Product Name',
                ),
              ),
            ),
            ElevatedButton(
                onPressed: () => {
                  _addProduct()
                },
                child: Text("Add product"),
            ),
          ],
        ),
      ),
    );
  }
}