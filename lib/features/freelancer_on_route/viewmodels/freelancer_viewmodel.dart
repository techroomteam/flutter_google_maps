import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animarker/core/ripple_marker.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:freelancer_tracking/config/firebase_paths.dart';
import 'package:freelancer_tracking/config/string.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/freelancer_route.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/mylatlng.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'dart:async';
import '../../../config/helper.dart';
import '../../../main.dart';
import '../../../widgets/base_model.dart';

class FreelancerViewModel extends BaseModel {
  late FreelancerOnRoute freelancerOnRoute =
      FreelancerOnRoute(currentLocation: MyLatLng(33.6342057, 73.0299553));
  late final Map<MarkerId, Marker> markers = <MarkerId, Marker>{};
  // MyLatLng endPosition = MyLatLng(33.643259, 73.031007);
  var time = 0;
  var speed = 0.0;
  String statusFreelancer = 'freelancer App';
  late var isLocationOnPath = false;
  var markerIndex = 0;
  var polylineCoordinate = <LatLng>[];
  var mpPolylineCoordinate = <mp.LatLng>[];
  PolylinePoints polylinePoints = PolylinePoints();
  bool centerPolylineCheck = true;
  late GoogleMapController mapController;
  late MyLatLng currentLocation;
  List<MyLatLng> myLatLng = [];
  late LatLng initialCameraLatLng = const LatLng(33.6813714, 73.0447538);
  Map<PolylineId, Polyline> polylines = {};
  final Completer<GoogleMapController> controller = Completer();
  bool show = false;
  int count = 0;

  Future<void> updateLocationInFirebase() async {
    await FirebasePaths.freelancerOnRouteD.set(freelancerOnRoute.toMap());
  }

  void start() async {
    var speedInMps = 30.0;
    show = true;
    var positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        distanceFilter: 20,
        accuracy: LocationAccuracy.bestForNavigation,
      ),
    ).listen((Position p) async {
      currentLocation = MyLatLng(p.latitude, p.longitude);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      updateMarker(currentLocation);
      speedInMps = p.speed;

      var distance = mp.SphericalUtil.computeDistanceBetween(
          mp.LatLng(currentLocation.latitude, currentLocation.longitude),
          mp.LatLng(
              SameData.endPosition.latitude, SameData.endPosition.longitude));
      var kms = distance / 1000;
      var kms_per_min = 0.5;
      var mins_taken = kms / kms_per_min;
      var totalMinutes = (mins_taken).round();
      updateTimeDistance(totalMinutes);
      updateSpeed(speedInMps);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      if (isLocationPath) {
        updateLocationInFirebase();
        updateStatusFreelancer('App Freelancer $isLocationOnPath');
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        updateStatusFreelancer('App Freelancer $isLocationOnPath');
        updateMarker(currentLocation);
        centerPolylineCheck ? centerPolyline() : setPolylines();
      }
      notifyListeners();
    });
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
              LatLng(currentLocation.latitude, currentLocation.longitude),
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
    var cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 70.0);
    check(cameraUpdate, mapController);
  }

  void check(CameraUpdate u, GoogleMapController c) async {
    await c.animateCamera(u);
    // await mapController.animateCamera(u);
    var l1 = await c.getVisibleRegion();
    var l2 = await c.getVisibleRegion();
    // debugPrint(l1.toString());
    // debugPrint(l2.toString());
    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      check(u, c);
    } else {
      setPolylines();
    }
  }

  void setPolylines() async {
    polylineCoordinate.clear();
    mpPolylineCoordinate.clear();
    myLatLng.clear();
    final tmp = await FlutterCompass.events!.first;
    var result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyA-nVgsHiRVqNoHZV5GPKPEQLLtVkUZWP0',
        PointLatLng(currentLocation.latitude, currentLocation.longitude),
        PointLatLng(
            SameData.endPosition.latitude, SameData.endPosition.longitude),
        heading: tmp.heading!.round());
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinate.add(LatLng(point.latitude, point.longitude));
        mpPolylineCoordinate.add(mp.LatLng(point.latitude, point.longitude));
        myLatLng.add(MyLatLng(point.latitude, point.longitude));
      }
    }
    freelancerOnRoute.route = myLatLng;
    freelancerOnRoute.isroutechanged = true;
    updateLocationInFirebase();
    var id = const PolylineId('poly');
    var polyline = Polyline(
      polylineId: id,
      points: polylineCoordinate,
      width: 6,
    );
    polylines[id] = polyline;
    notifyListeners();
    return;
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

  void getMarker() async {
    SameData.imageData = await getBytesFromAsset('assets/profile1.png', 50);
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentLocation = MyLatLng(position.latitude, position.longitude);
    initialCameraLatLng = LatLng(position.latitude, position.longitude);
    final controller2 = await controller.future;
    await controller2.moveCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: initialCameraLatLng, zoom: 15.0)));
    var markerId = const MarkerId('MarkerId3');
    markers[markerId] = RippleMarker(
      markerId: markerId,
      icon: BitmapDescriptor.fromBytes(SameData.imageData!),
      position: LatLng(currentLocation.latitude, currentLocation.longitude),
      anchor: const Offset(0.5, 0.5), // Extra....
      ripple: false,
    );
    notifyListeners();
  }

  bool checkLocationIsOnPathOrNot(MyLatLng newLocation) {
    final pointFromSourceToolkit =
        mp.LatLng(newLocation.latitude, newLocation.longitude);
    isLocationOnPath = mp.PolygonUtil.isLocationOnPath(
        pointFromSourceToolkit, mpPolylineCoordinate, false,
        tolerance: 10);
    return isLocationOnPath;
  }

  updateTimeDistance(int value) {
    time = value;
    notifyListeners();
  }

  updateSpeed(double value) {
    speed = value;
    notifyListeners();
  }

  updateStatusFreelancer(String value) {
    statusFreelancer = value;
    notifyListeners();
  }

  int isOnSegment(MyLatLng newLocation) {
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

  updateRoute() async {
    polylineCoordinate.clear();
    mpPolylineCoordinate.clear();
    myLatLng.clear();
    final tmp = await FlutterCompass.events!.first;
    var result = await polylinePoints.getRouteBetweenCoordinates(
        'AIzaSyA-nVgsHiRVqNoHZV5GPKPEQLLtVkUZWP0',
        PointLatLng(currentLocation.latitude, currentLocation.longitude),
        PointLatLng(
            SameData.endPosition.latitude, SameData.endPosition.longitude),
        heading: tmp.heading!.round());
    if (result.points.isNotEmpty) {
      for (var point in result.points) {
        polylineCoordinate.add(LatLng(point.latitude, point.longitude));
        mpPolylineCoordinate.add(mp.LatLng(point.latitude, point.longitude));
        myLatLng.add(MyLatLng(point.latitude, point.longitude));
      }
    }
    freelancerOnRoute.route = myLatLng;
    updateLocationInFirebase();
  }

  Future<void> listenDeviceLocation() async {
    await Firebase.initializeApp();
    var position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    currentLocation = MyLatLng(position.latitude, position.longitude);
    freelancerOnRoute.currentLocation = currentLocation;

    var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
    if (isLocationPath) {
      updateLocationInFirebase();
    } else {
      updateRoute();
    }

    // SameData.currentPosition = LatLng(position.latitude, position.longitude);
    // await FirebaseFirestore.instance.collection('location').doc('user1').set({
    //   'latitude': SameData.currentPosition.latitude,
    //   'longitude': SameData.currentPosition.longitude,
    //   'name': 'john',
    // }, SetOptions(merge: true));
  }

  Future<void> initializeService() async {
    debugPrint('Initialize Service........');
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will executed when app is in foreground or background in separated isolate
        onStart: (serviceInstance) =>
            startBackGround(serviceInstance, listenDeviceLocation: () {}),
        // auto start service
        autoStart: true,
        isForegroundMode: true,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,
        // this will executed when app is in foreground in separated isolate
        onForeground: (serviceInstance) =>
            startBackGround(serviceInstance, listenDeviceLocation: () {}),
        // you have to enable background fetch capability on xcode project
        onBackground: onIosBackground,
      ),
    );
    await service.startService();
  }

  void changeLocation() {
    if (count == 0) {
      currentLocation = MyLatLng(33.649564, 73.041836);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 1) {
      currentLocation = MyLatLng(33.649105, 73.040997);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 2) {
      currentLocation = MyLatLng(33.648645, 73.041295);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 3) {
      currentLocation = MyLatLng(33.648350, 73.040802);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 4) {
      currentLocation = MyLatLng(33.648154, 73.040383);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 5) {
      currentLocation = MyLatLng(33.647877, 73.039815);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 6) {
      currentLocation = MyLatLng(33.648315, 73.039475);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 7) {
      currentLocation = MyLatLng(33.648650, 73.040065);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 8) {
      currentLocation = MyLatLng(33.648825, 73.040394);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 9) {
      currentLocation = MyLatLng(33.648948, 73.040632);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 10) {
      currentLocation = MyLatLng(33.649064, 73.040880);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 11) {
      currentLocation = MyLatLng(33.649351, 73.041405);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    } else if (count == 12) {
      currentLocation = MyLatLng(33.649711, 73.042111);
      var isLocationPath = checkLocationIsOnPathOrNot(currentLocation);
      freelancerOnRoute.currentLocation = currentLocation;
      freelancerOnRoute.isroutechanged = false;
      if (isLocationPath) {
        debugPrint('Location On Path');
        updateLocationInFirebase();
        markerIndex = isOnSegment(currentLocation);
        if (markerIndex > 0) {
          final polylineCoordinates = MyLatLng(
              polylineCoordinate[1].latitude, polylineCoordinate[1].longitude);
          updateMarker(polylineCoordinates);
        } else {
          updateMarker(currentLocation);
        }
      } else {
        debugPrint('************Location Not on Path*************');
        updateMarker(currentLocation);
        setPolylines();
      }
      count++;
    }
    notifyListeners();
  }
}
