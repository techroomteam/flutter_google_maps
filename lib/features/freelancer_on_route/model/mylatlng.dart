import 'package:cloud_firestore/cloud_firestore.dart';

class MyLatLng {
  late double latitude;
  late double longitude;

  MyLatLng(this.latitude, this.longitude);

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  MyLatLng.fromMap(map)
      : latitude = map['latitude'],
        longitude = map['longitude'];

  MyLatLng.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data());
}
