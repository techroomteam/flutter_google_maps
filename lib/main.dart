import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/model/freelancer_route.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/viewmodels/renter_viewmodel.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:wakelock/wakelock.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'config/string.dart';
import 'features/freelancer_on_route/model/mylatlng.dart';
import 'features/freelancer_on_route/screens/freelancer_map_screen.dart';
import 'features/freelancer_on_route/screens/renter_map_screen.dart';
import 'features/freelancer_on_route/services/firestorestreamservice.dart';
import 'features/freelancer_on_route/viewmodels/freelancer_viewmodel.dart';

Future<Uint8List> getBytesFromAsset(String path, int width) async {
  var data = await rootBundle.load(path);
  var codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
      targetWidth: width);
  var fi = await codec.getNextFrame();
  return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
      .buffer
      .asUint8List();
}

Future<void> getMarker() async {
  SameData.imageData = await getBytesFromAsset('assets/profile1.png', 65);
  debugPrint('end getMarker');
  return;
}

MyLatLng myLatLng = MyLatLng(33.643259, 73.031007);
const fetchBackground = 'fetchBackground';
bool enable = true;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Wakelock.toggle(enable: enable);
  await getMarker();
  ////// Freelancer ////////////
  // runApp(MultiProvider(
  //   providers: [
  //     ChangeNotifierProvider(create: (_) => FreelancerViewModel()),
  //   ],
  //   child: MaterialApp(
  //       title: 'Freelancer App.',
  //       theme: ThemeData(
  //         primarySwatch: Colors.blue,
  //         visualDensity: VisualDensity.adaptivePlatformDensity,
  //       ),
  //       home: const FreelancerAppWithFirebase()),
  // ));
  /////// Renter ///////////////
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => RenterViewModel()),
      StreamProvider<FreelancerOnRoute>.value(
        value: FireStoreStreamService().freelancerOnRouteStream(),
        initialData: FreelancerOnRoute(
            currentLocation: MyLatLng(33.6342057, 73.0299553)),
        catchError: (context, error) {
          debugPrint(error.toString());
          return FreelancerOnRoute(
              currentLocation: MyLatLng(33.6342057, 73.0299553));
        },
      ),
    ],
    child: const MaterialApp(
      home: RenterAppWithFirebase(),
    ),
  ));
}

////////
bool onIosBackground(ServiceInstance service) {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('FLUTTER BACKGROUND FETCH');
  return true;
}
