import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animarker/core/ripple_marker.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/mylatlng.dart';
import 'package:freelancer_tracking/widgets/base_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../config/string.dart';
import '../model/freelancer_route.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

class RenterViewModel extends BaseModel {
  late FreelancerOnRoute previousLoc =
      FreelancerOnRoute(currentLocation: MyLatLng(33.6342057, 73.0299553));
  String statusRenter = 'renter App';
  late FreelancerOnRoute freelancerOnRoute;
  late LatLng currentPosition;
  late MyLatLng currentLocation;
  bool centerPolylineCheck = true;
  final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  var polylineCoordinate = <LatLng>[];
  var mpPolylineCoordinate = <mp.LatLng>[];
  Map<PolylineId, Polyline> polylines = {};
  late GoogleMapController mapController;
  final Completer<GoogleMapController> controller = Completer();
  var markerIndex = 0;
  void start() {
    currentPosition = LatLng(freelancerOnRoute.currentLocation.latitude,
        freelancerOnRoute.currentLocation.longitude);
    currentLocation =
        MyLatLng(currentPosition.latitude, currentPosition.longitude);
    if (freelancerOnRoute.isroutechanged!) {
      debugPrint('Condition True....');
      updateMarker(currentLocation);
      centerPolylineCheck ? centerPolyline() : showPolyLine();
    } else {
      markerIndex = isOnSegment(currentLocation);
      if (markerIndex > 0) {
        final polylineCoordinates = MyLatLng(
            polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
        updateMarker(polylineCoordinates);
      } else {
        updateMarker(currentLocation);
      }
    }
  }

  void centerPolyline() async {
    centerPolylineCheck = false;
    LatLngBounds bounds;
    if (currentLocation.latitude > SameData.endPosition.latitude &&
        currentLocation.longitude > SameData.endPosition.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(
              SameData.endPosition.latitude, SameData.endPosition.longitude),
          northeast:
              LatLng(currentLocation.latitude, currentLocation.longitude));
    } else if (currentLocation.longitude > SameData.endPosition.longitude) {
      bounds = LatLngBounds(
          southwest:
              LatLng(currentLocation.latitude, SameData.endPosition.longitude),
          northeast:
              LatLng(SameData.endPosition.latitude, currentLocation.longitude));
    } else if (currentLocation.latitude > SameData.endPosition.latitude) {
      bounds = LatLngBounds(
          southwest:
              LatLng(SameData.endPosition.latitude, currentLocation.longitude),
          northeast:
              LatLng(currentLocation.latitude, SameData.endPosition.longitude));
    } else {
      bounds = LatLngBounds(
          southwest:
              LatLng(currentLocation.latitude, currentLocation.longitude),
          northeast: LatLng(
              SameData.endPosition.latitude, SameData.endPosition.longitude));
    }
    var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 70);
    check(cameraUpdate, mapController);
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    debugPrint('Check..');
    await c.animateCamera(u);
    var l1 = await c.getVisibleRegion();
    var l2 = await c.getVisibleRegion();
    debugPrint(l1.toString());
    debugPrint(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    } else {
      showPolyLine();
    }
  }

  void showPolyLine() {
    polylineCoordinate.clear();
    mpPolylineCoordinate.clear();
    polylineCoordinate = [];
    mpPolylineCoordinate = [];
    var myLatLng = freelancerOnRoute.route;
    for (var point in myLatLng!) {
      polylineCoordinate.add(LatLng(point.latitude, point.longitude));
      mpPolylineCoordinate.add(mp.LatLng(point.latitude, point.longitude));
    }
    debugPrint('Lenght:   ' + polylineCoordinate.length.toString());
    var id = const PolylineId('poly');
    var polyline = Polyline(
      polylineId: id,
      points: polylineCoordinate,
      width: 6,
    );
    polylines[id] = polyline;
    notifyListeners();
  }

  void updateMarker(MyLatLng newLoc) {
    var markerId = const MarkerId('MarkerId3');
    markers[markerId] = RippleMarker(
      markerId: markerId,
      icon: BitmapDescriptor.fromBytes(SameData.imageData!),
      position: LatLng(newLoc.latitude, newLoc.longitude),
      anchor: const Offset(0.5, 0.5), // Extra....
      ripple: false,
    );
    notifyListeners();
  }

  Future<void> onStopover(LatLng latLng) async {
    if (!controller.isCompleted) return;
    if (markerIndex == 1) {
      polylineCoordinate.removeAt(0);
      updateMarker(currentLocation);
      markerIndex -= 1;
    } else if (markerIndex > 1) {
      polylineCoordinate.removeAt(0);
      final polylineCoordinates = MyLatLng(
          polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
      updateMarker(polylineCoordinates);
      markerIndex -= 1;
    }
    notifyListeners();
  }

  updatePage() {
    notifyListeners();
  }

  int isOnSegment(MyLatLng newLocation) {
    debugPrint('Is On Segment...');
    var markerInd = 0;
    for (var i = 0; i < polylineCoordinate.length; i++) {
      int index;
      if (i == polylineCoordinate.length - 1) {
        index = 1;
      } else {
        index = i + 1;
      }
      var polylineCoordinateList = <mp.LatLng>[
        mp.LatLng(
            polylineCoordinate[i].latitude, polylineCoordinate[i].longitude),
        mp.LatLng(polylineCoordinate[index].latitude,
            polylineCoordinate[index].longitude)
      ];
      final pointFromSourceToolkit =
          mp.LatLng(newLocation.latitude, newLocation.longitude);
      var onPath = mp.PolygonUtil.isLocationOnPath(
          pointFromSourceToolkit, polylineCoordinateList, false,
          tolerance: 4);
      if (onPath) {
        markerInd = polylineCoordinate.indexOf(polylineCoordinate[i]);
        break;
      }
    }
    return markerInd;
  }
}
