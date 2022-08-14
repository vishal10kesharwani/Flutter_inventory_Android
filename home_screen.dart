import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:fyp2022/httpRequest.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FirebaseDatabase database = FirebaseDatabase.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<DataSnapshot> _loadData () async{
    String uid = auth.currentUser?.uid??"";
    return database.ref("products/" + uid).get();
  }

  //Delete the selected image
  //This function is called when a trash icon is pressed
  Future<void> _delete(String ref) async {
    setState(() {
      _isLoading = true;
    });
    String uid = auth.currentUser?.uid??"";
    DataSnapshot productSnapshot = await database.ref("products/" + uid + "/" + ref).get();
    Map<String, dynamic> data = json.decode(json.encode(productSnapshot.value));
    String imageURL = data['url'];
    try {
      await database.ref("products/" + uid + "/" + ref).set({});
      final storageRef = storage.refFromURL(imageURL);
      await storageRef.delete();
    }
    catch(e) {

    }
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey,
      appBar: AppBar(
        title: const Text('HOME SCREEN'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _isLoading
                ? const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
                : Expanded(
              child: FutureBuilder(
                future: _loadData(),
                builder: (context,
                    AsyncSnapshot<DataSnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    Map<String, dynamic> data = json.decode(json.encode(snapshot.data?.value));
                    return ListView.builder(
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final String key = data.keys.elementAt(index);
                        final Map<String, dynamic> product = json.decode(json.encode(data[key]));
                        final Map<String, dynamic> metadata = json.decode(json.encode(product['metaData']));
                        // final DateFormat format = DateFormat('EEE, dd MMM yyyy HH:mm:ss GMT');
                        final DateTime expiryDate = HttpDate.parse(metadata['exp_date']);
                        return Card(
                          margin:
                          const EdgeInsets.symmetric(vertical: 10),
                          child: ListTile(
                            dense: false,
                            leading: Image.network(product['url']),
                            // leading: Image.network('https://firebasestorage.googleapis.com/v0/b/fyp2022-829a9.appspot.com/o/scaled_image_picker3656337762070061444.jpg?alt=media&token=6cf3e296-2fc1-4fd9-bfc7-e6a3d8a62ee6'),
                            //leading: Image(image: CachedNetworkImageProvider('https://firebasestorage.googleapis.com/v0/b/fyp2022-829a9.appspot.com/o/scaled_image_picker3656337762070061444.jpg?alt=media&token=6cf3e296-2fc1-4fd9-bfc7-e6a3d8a62ee6')),

                            title: Text(product['name']),
                            subtitle: Text(expiryDate.day.toString() + "/" + expiryDate.month.toString() + "/" + expiryDate.year.toString()),
                            trailing: IconButton(
                              onPressed: () => {
                                _delete(key),
                              },
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(child: Icon(Icons.add), onPressed: () async{
        final result = await Navigator.of(context).pushNamed('auto_add_screen');
        if(result != null) {
          setState(() {});
        }
      },),
    );
  }
}