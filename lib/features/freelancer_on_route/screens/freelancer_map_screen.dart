import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:freelancer_tracking/config/string.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../main.dart';
import '../viewmodels/freelancer_viewmodel.dart';

class FreelancerAppWithFirebase extends StatefulWidget {
  const FreelancerAppWithFirebase({Key? key}) : super(key: key);
  @override
  State<FreelancerAppWithFirebase> createState() =>
      _FreelancerAppWithFirebaseState();
}

class _FreelancerAppWithFirebaseState extends State<FreelancerAppWithFirebase>
    with WidgetsBindingObserver {
  double zoom = 15;
  late final StreamSubscription<Position> positionStream;
  AppLifecycleState _appLifeCycleState = AppLifecycleState.resumed;
  late PermissionStatus status = PermissionStatus.denied;
  int count = 0;
  LatLng changeLatLng = const LatLng(33.649996, 73.041335);
  late FreelancerViewModel freelancerVM;
  @override
  void initState() {
    super.initState();
    _requestPermission();
    WidgetsBinding.instance!.addObserver(this);
  }

  _requestPermission() async {
    debugPrint('Request Permission....');
    status = await Permission.location.request();
    if (status.isGranted) {
      debugPrint('************* Done ****************');
      getMarker();
    } else if (status.isDenied) {
      _requestPermission();
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    _appLifeCycleState = state;
    setState(() {});
    if (_appLifeCycleState == AppLifecycleState.paused) {
      if (freelancerVM.show) {
        await freelancerVM.initializeService();
      }
    }
    if (_appLifeCycleState == AppLifecycleState.resumed) {
      final service = FlutterBackgroundService();
      var isRunning = await service.isRunning();
      if (isRunning) {
        service.invoke('stopService');
      }
    }
    debugPrint('Notification: ' + _appLifeCycleState.toString());
  }

  @override
  Widget build(BuildContext context) {
    // #TODO: We should update this part
    WidgetsBinding.instance?.addPostFrameCallback((timeStamp) {
      freelancerVM.getMarker();
    });
    return Scaffold(
      appBar: AppBar(
        title: Consumer<FreelancerViewModel>(builder: (_, model, __) {
          return Text(model.statusFreelancer);
        }),
      ),
      body: Consumer<FreelancerViewModel>(builder: (_, model, __) {
        freelancerVM = model;
        return SafeArea(
          child: Stack(
            children: [
              Animarker(
                mapId:
                    model.controller.future.then<int>((value) => value.mapId),
                shouldAnimateCamera: false,
                isActiveTrip: true,
                rippleRadius: 0.25,
                useRotation: false,
                zoom: 15.0,
                duration: const Duration(milliseconds: 2000),
                onStopover: model.onStopover,
                onMarkerAnimationListener: (marker) {
                  if (model.isLocationOnPath) {
                    debugPrint('onMarkerAnimation.....');
                    model.polylineCoordinate[0] = LatLng(
                        marker.position.latitude, marker.position.longitude);
                    model.updatePage();
                  }
                },
                markers: <Marker>{
                  ...model.markers.values.toSet(),
                },
                child: GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: model.initialCameraLatLng,
                    zoom: zoom,
                  ),
                  onMapCreated: (gController) async {
                    model.mapController = gController;
                    model.controller.complete(gController);
                  },
                  polylines: Set<Polyline>.of(model.polylines.values),
                ),
              ),
              ElevatedButton(
                onPressed: () => model.start(),
                child: const Text('Start'),
              ),
              Visibility(
                visible: model.show,
                child: Padding(
                  padding: const EdgeInsets.only(left: 70.0),
                  child: ElevatedButton(
                      onPressed: () {
                        // changeLocation();
                      },
                      child: const Text('Move')),
                ),
              ),
              Visibility(
                visible: model.show,
                child: Padding(
                  padding: const EdgeInsets.only(left: 140.0),
                  child: ElevatedButton(
                      onPressed: () {
                        MapUtils.openMap(SameData.endPosition.latitude,
                            SameData.endPosition.longitude);
                      },
                      child: const Text('Open Google Map')),
                ),
              ),
              Visibility(
                visible: model.show,
                child: Padding(
                    padding: const EdgeInsets.only(left: 300),
                    child: Text(
                      model.time.toString(),
                      style: const TextStyle(fontSize: 24.0),
                    )),
              ),
              Visibility(
                  visible: model.show,
                  child: Padding(
                      padding: const EdgeInsets.only(top: 50, left: 20),
                      child: Text('Speed:' + model.speed.toString())))
            ],
          ),
        );
      }),
    );
  }

  void updateLocation(ServiceInstance service) {
    debugPrint('Update Location.....');
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        await service.setForegroundNotificationInfo(
          title: 'My App Service',
          content: 'Updated at ${DateTime.now()}',
        );
      }
    });
  }

  bool onIosBackground(ServiceInstance service) {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('FLUTTER BACKGROUND FETCH');
    return true;
  }
}

class MapUtils {
  MapUtils._();
  static Future<void> openMap(double latitude, double longitude) async {
    var googleUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    // ignore: deprecated_member_use
    if (await canLaunch(googleUrl)) {
      // ignore: deprecated_member_use
      await launch(googleUrl);
    } else {
      throw 'Could not open the map.';
    }
  }
}
