import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nomad_mobile/data/models/activity.dart';
import 'package:nomad_mobile/data/models/trip.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_bloc.dart';
import 'package:nomad_mobile/logic/blocs/activity_bloc/activity_state.dart';
import 'package:nomad_mobile/core/services/google_api_service.dart';

class MapSection extends StatefulWidget {
  final Trip trip;
  final Color outlineColor;
  final bool showMarkers;

  const MapSection({
    super.key,
    required this.trip,
    required this.outlineColor,
    this.showMarkers = true,
  });

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> _markers = {};
  List<LatLng> _allPoints = [];
  LatLng? _destinationLatLng;
  LatLng? _ongoingPosition;
  bool _isLoadingDestination = true;

  @override
  void initState() {
    super.initState();
    _fetchDestination();
  }

  @override
  void didUpdateWidget(MapSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trip.destination != oldWidget.trip.destination) {
      setState(() => _isLoadingDestination = true);
      _fetchDestination();
    }
  }

  Future<void> _fetchDestination() async {
    try {
      final service = GoogleApiService();
      final coords = await service.getCoordinates(widget.trip.destination);
      if (coords != null && mounted) {
        setState(() {
          _destinationLatLng = LatLng(coords['lat']!, coords['lng']!);
        });

        if (_markers.isEmpty && _controller.isCompleted) {
          final controller = await _controller.future;
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(_destinationLatLng!, 12),
          );
        }
      }
    } catch (e) {
      debugPrint('Error fetching destination: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDestination = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ActivityBloc, ActivityState>(
      listener: (context, state) {
        if (widget.showMarkers) {
          _updateMarkers(state.activities);
        }
      },
      builder: (context, state) {
        // Default to Kuala Lumpur if no markers
        LatLng target = const LatLng(3.1390, 101.6869);
        double zoom = 10;

        if (_markers.isNotEmpty) {
          target = _markers.first.position;
          zoom = 12;
        } else if (_destinationLatLng != null) {
          target = _destinationLatLng!;
          zoom = 12;
        }

        CameraPosition initialPosition = CameraPosition(
          target: target,
          zoom: zoom,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Trip Map',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.outlineColor, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    GoogleMap(
                      mapType: MapType.normal,
                      initialCameraPosition: initialPosition,
                      markers: _markers,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: true,
                      // Allows dragging the map without scrolling the page
                      gestureRecognizers:
                          <Factory<OneSequenceGestureRecognizer>>{
                            Factory<OneSequenceGestureRecognizer>(
                              () => EagerGestureRecognizer(),
                            ),
                          },
                      onMapCreated: (GoogleMapController controller) {
                        if (!_controller.isCompleted) {
                          _controller.complete(controller);
                        }
                        if (state.activities.isNotEmpty && widget.showMarkers) {
                          _updateMarkers(state.activities);
                        } else if (_markers.isEmpty &&
                            _destinationLatLng != null) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(_destinationLatLng!, 12),
                          );
                        }
                      },
                    ),
                    if (_isLoadingDestination && _markers.isEmpty)
                      Container(
                        color: Colors.white,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: widget.outlineColor,
                          ),
                        ),
                      ),
                    if (state.isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.7),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: widget.outlineColor,
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: FloatingActionButton.small(
                        heroTag: "reset_map_view",
                        backgroundColor: Colors.white,
                        onPressed: _resetMapView,
                        child: Icon(
                          Icons.center_focus_strong,
                          color: widget.outlineColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateMarkers(List<Activity> activities) async {
    final Set<Marker> newMarkers = {};
    final List<LatLng> points = [];
    LatLng? ongoingPosition;

    for (var activity in activities) {
      if (activity.latitude != null &&
          activity.longitude != null &&
          activity.latitude != 0 &&
          activity.longitude != 0) {
        final pos = LatLng(activity.latitude!, activity.longitude!);
        points.add(pos);

        if (activity.status == 'Ongoing') {
          ongoingPosition = pos;
        }

        newMarkers.add(
          Marker(
            markerId: MarkerId('activity_${activity.activityId}'),
            position: pos,
            zIndex: activity.status == 'Ongoing' ? 10.0 : 1.0,
            infoWindow: InfoWindow(
              title: activity.name,
              snippet: 'Day ${activity.dayNumber} - ${activity.time}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getActivityHue(activity.status),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
        _allPoints = points;
        _ongoingPosition = ongoingPosition;
      });

      _resetMapView();
    }
  }

  Future<void> _fitBounds() async {
    if (_allPoints.isEmpty) return;
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(_boundsFromLatLngList(_allPoints), 50),
      );
    } catch (e) {
      // Controller might not be ready
    }
  }

  Future<void> _resetMapView() async {
    if (_ongoingPosition != null) {
      await _animateToLocation(_ongoingPosition);
    } else if (_allPoints.isNotEmpty) {
      await _fitBounds();
    } else if (_destinationLatLng != null) {
      await _animateToLocation(_destinationLatLng, zoom: 12);
    }
  }

  Future<void> _animateToLocation(LatLng? position, {double zoom = 15}) async {
    if (position == null) return;
    try {
      final GoogleMapController controller = await _controller.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(position, zoom),
      );
    } catch (e) {
      // Controller might not be ready
    }
  }

  double _getActivityHue(String? status) {
    switch (status) {
      case 'Ongoing':
        return BitmapDescriptor.hueBlue;
      case 'Completed':
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueOrange;
    }
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
      northeast: LatLng(x1!, y1!),
      southwest: LatLng(x0!, y0!),
    );
  }
}
