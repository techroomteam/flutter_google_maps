import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/mylatlng.dart';

class FreelancerOnRoute {
  late MyLatLng currentLocation;
  String? name;
  int? heading;
  bool? isroutechanged;
  List<MyLatLng>? route;

  // FreelancerOnRoute();

  FreelancerOnRoute({
    required this.currentLocation,
    this.name,
    this.heading,
    this.isroutechanged,
    this.route,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentlocation': currentLocation.toMap(),
      'name': name,
      'heading': heading,
      'reroute': isroutechanged,
      'route': route != null ? route!.map((org) => org.toMap()).toList() : null,
    };
  }

  FreelancerOnRoute.fromMap(map)
      : currentLocation = MyLatLng.fromMap(map['currentlocation']),
        name = map['name'],
        heading = map['heading'],
        isroutechanged = map['reroute'],
        route = List<MyLatLng>.from(
          map['route']?.map((item) => MyLatLng.fromMap(item)) ?? [],
        );

  FreelancerOnRoute.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data());
}
