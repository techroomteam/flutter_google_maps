import 'package:flutter/material.dart';
import 'package:flutter_animarker/flutter_map_marker_animation.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:freelancer_tracking/features/freelancer_on_route/viewmodels/renter_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../model/freelancer_route.dart';

class RenterAppWithFirebase extends StatefulWidget {
  const RenterAppWithFirebase({Key? key}) : super(key: key);

  @override
  State<RenterAppWithFirebase> createState() => _RenterAppWithFirebaseState();
}

class _RenterAppWithFirebaseState extends State<RenterAppWithFirebase> {
  double zoom = 15;
  PolylinePoints polylinePoints = PolylinePoints();
  late var isLocationOnPath = false;
  late int heading = 90;
  late RenterViewModel renterViewModel;
  @override
  Widget build(BuildContext context) {
    renterViewModel = Provider.of<RenterViewModel>(context, listen: false);
    renterViewModel.freelancerOnRoute =
        Provider.of<FreelancerOnRoute>(context, listen: true);
    debugPrint('Renter Page Rebuild');
    if (renterViewModel.previousLoc.currentLocation.latitude !=
            renterViewModel.freelancerOnRoute.currentLocation.latitude &&
        renterViewModel.previousLoc.currentLocation.longitude !=
            renterViewModel.freelancerOnRoute.currentLocation.longitude) {
      renterViewModel.previousLoc = renterViewModel.freelancerOnRoute;
      WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
        renterViewModel.start();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Consumer<RenterViewModel>(builder: (_, model, __) {
          return Text(model.statusRenter);
        }),
      ),
      body: Consumer<RenterViewModel>(builder: (_, model, __) {
        return SafeArea(
            child: Stack(
          children: [
            Animarker(
              mapId: model.controller.future.then<int>((value) => value.mapId),
              shouldAnimateCamera: false,
              isActiveTrip: true,
              rippleRadius: 0.25,
              useRotation: false,
              zoom: 15.0,
              duration: const Duration(milliseconds: 2000),
              onStopover: model.onStopover,
              onMarkerAnimationListener: (marker) {
                if (isLocationOnPath) {
                  debugPrint('onMarkerAnimation.....');
                  model.polylineCoordinate[0] = marker.position;
                  model.updatePage();
                }
              },
              markers: <Marker>{
                ...model.markers.values.toSet(),
              },
              child: GoogleMap(
                mapType: MapType.normal,
                initialCameraPosition: CameraPosition(
                  target: const LatLng(33.6502287, 73.0415577),
                  zoom: zoom,
                ),
                onMapCreated: (gController) async {
                  model.mapController = gController;
                  model.controller.complete(gController);
                },
                polylines: Set<Polyline>.of(model.polylines.values),
                //  onCameraMove: (ca) => setState(() => zoom = ca.zoom),
              ),
            )
          ],
        ));
      }),
    );
  }
}
