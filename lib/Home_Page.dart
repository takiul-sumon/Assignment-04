import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Location _location = Location();

  GoogleMapController? _mapController;
  LocationData? _currentLocation;

  List<LatLng> _polylineCoordinates = [];
  final Set<Polyline> _polylines = {};
  Marker? _marker;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final permissionGranted = await _checkAndRequestPermission();
    final serviceEnabled = await _location.serviceEnabled() || await _location.requestService();

    if (!permissionGranted || !serviceEnabled) return;

    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 10000,
      distanceFilter: 1,
    );

    _currentLocation = await _location.getLocation();
    _updatePolyline(_currentLocation!);

    _location.onLocationChanged.listen((LocationData locationData) {
      _currentLocation = locationData;
      _updatePolyline(locationData);
      _moveCamera();
      setState(() {});
    });
  }

  Future<bool> _checkAndRequestPermission() async {
    final permissionStatus = await _location.hasPermission();
    if (permissionStatus == PermissionStatus.granted ||
        permissionStatus == PermissionStatus.grantedLimited) {
      return true;
    } else {
      final requestResult = await _location.requestPermission();
      return requestResult == PermissionStatus.granted ||
          requestResult == PermissionStatus.grantedLimited;
    }
  }

  void _updatePolyline(LocationData locationData) {
    final latLng = LatLng(locationData.latitude!, locationData.longitude!);
    _polylineCoordinates.add(latLng);

    _marker = Marker(
      markerId: const MarkerId('user_marker'),
      position: latLng,
      infoWindow: InfoWindow(
        title: "My current location",
        snippet: "${latLng.latitude}, ${latLng.longitude}",
      ),
    );

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId("route"),
        color: Colors.blue,
        width: 5,
        points: _polylineCoordinates,
      ),
    );
  }

  void _moveCamera() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-Time Location Tracker')),
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              myLocationEnabled: true,
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
                zoom: 17,
              ),
              onMapCreated: (controller) => _mapController = controller,
              polylines: _polylines,
              markers: _marker != null ? {_marker!} : {},
            ),
    );
  }
}
