import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
//import 'package:location/location.dart';

class MapsScreen extends StatefulWidget {
  //const MapsScreen({ Key? key }) : super(key: key);

  @override
  _MapsScreenState createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  Completer<GoogleMapController> _controller = Completer();
  Map<MarkerId, Marker> markers = {};
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );
  Position userLocation;
  String userName;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getLocation().then((position) {
      setState(() {
        userLocation = position;
      });
    });
    getCurrentUser().then((name) {
      setState(() {
        userName = name;
      });
    });
  }

  Future<String> getCurrentUser() async {
    final user = await FirebaseAuth.instance.currentUser();
    final username = user.displayName;
    return username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text(
                'Hello, friend!',
                style: TextStyle(fontSize: 20),
              ),
              leading: Icon(Icons.map),
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () => FirebaseAuth.instance.signOut(),
            )
          ],
        ),
      ),
      body: userLocation == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: CameraPosition(
                target: LatLng(userLocation.latitude, userLocation.longitude),
                zoom: 17.76,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onLongPress: (latlong) {
                _addMarker(latlong);
                print(latlong);
              },
              markers: Set<Marker>.of(markers.values),
            ),
    );
  }

  Future<void> _addMarker(LatLng latLng) async {
    List<Placemark> placemarks =
        await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    setState(() {
      Placemark placemark = placemarks[0];
      final MarkerId markerId =
          MarkerId(latLng.latitude.toString() + latLng.longitude.toString());
      Marker marker = Marker(
        markerId: markerId,
        draggable: true,
        position: latLng,
        infoWindow: InfoWindow(
            title:
                latLng.latitude.toString() + "," + latLng.longitude.toString(),
            snippet: placemark.locality + ", " + placemark.country),
        icon: BitmapDescriptor.defaultMarker,
      );
      markers[markerId] = marker;
    });
    GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 17.0));
  }

  Future<Position> _getLocation() async {
    var currentLocation;
    currentLocation = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    return currentLocation;
  }
}
