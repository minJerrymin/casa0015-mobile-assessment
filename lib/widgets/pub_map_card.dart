import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/pub_spot.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';

class PubMapCard extends StatefulWidget {
  const PubMapCard({
    super.key,
    required this.pub,
    this.initialUserLatitude,
    this.initialUserLongitude,
  });

  final PubSpot pub;
  final double? initialUserLatitude;
  final double? initialUserLongitude;

  @override
  State<PubMapCard> createState() => _PubMapCardState();
}

class _PubMapCardState extends State<PubMapCard> {
  final LocationService _locationService = LocationService();
  double? _userLatitude;
  double? _userLongitude;
  bool _loadingLocation = false;
  String? _locationMessage;

  @override
  void initState() {
    super.initState();
    _userLatitude = widget.initialUserLatitude;
    _userLongitude = widget.initialUserLongitude;
  }

  @override
  void didUpdateWidget(covariant PubMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_userLatitude == null && widget.initialUserLatitude != null) {
      _userLatitude = widget.initialUserLatitude;
      _userLongitude = widget.initialUserLongitude;
    }
  }

  Future<void> _useMyLocation() async {
    if (_loadingLocation) return;
    setState(() {
      _loadingLocation = true;
      _locationMessage = 'Finding your location...';
    });

    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
      _locationMessage = result.message;
      if (result.success) {
        _userLatitude = result.latitude;
        _userLongitude = result.longitude;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final hasUserLocation = _userLatitude != null && _userLongitude != null;
    final distanceLabel = hasUserLocation
        ? '${_locationService.distanceKm(fromLatitude: _userLatitude!, fromLongitude: _userLongitude!, toLatitude: widget.pub.latitude, toLongitude: widget.pub.longitude).toStringAsFixed(1)} km from you'
        : '${widget.pub.distanceKm.toStringAsFixed(1)} km from search area';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Map & navigation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 210,
                child: PubLocationMap(
                  pub: widget.pub,
                  userLatitude: _userLatitude,
                  userLongitude: _userLongitude,
                  interactive: false,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(hasUserLocation ? Icons.my_location : Icons.location_searching, size: 18, color: muted),
                const SizedBox(width: 6),
                Expanded(child: Text(distanceLabel, style: TextStyle(color: muted, fontWeight: FontWeight.w600))),
              ],
            ),
            if ((_locationMessage ?? '').isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_locationMessage!, style: TextStyle(color: muted, fontSize: 12)),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.open_in_full),
                  label: const Text('Open map'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PubMapScreen(
                          pub: widget.pub,
                          initialUserLatitude: _userLatitude,
                          initialUserLongitude: _userLongitude,
                        ),
                      ),
                    );
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.navigation_outlined),
                  label: const Text('Navigate'),
                  onPressed: () => openVenueNavigation(context, widget.pub),
                ),
                if (!hasUserLocation)
                  OutlinedButton.icon(
                    icon: _loadingLocation
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: const Text('Use my location'),
                    onPressed: _loadingLocation ? null : _useMyLocation,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PubMapScreen extends StatefulWidget {
  const PubMapScreen({
    super.key,
    required this.pub,
    this.initialUserLatitude,
    this.initialUserLongitude,
  });

  final PubSpot pub;
  final double? initialUserLatitude;
  final double? initialUserLongitude;

  @override
  State<PubMapScreen> createState() => _PubMapScreenState();
}

class _PubMapScreenState extends State<PubMapScreen> {
  final LocationService _locationService = LocationService();
  double? _userLatitude;
  double? _userLongitude;
  bool _loadingLocation = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _userLatitude = widget.initialUserLatitude;
    _userLongitude = widget.initialUserLongitude;
    if (_userLatitude == null || _userLongitude == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useMyLocation());
    }
  }

  Future<void> _useMyLocation() async {
    if (_loadingLocation) return;
    setState(() {
      _loadingLocation = true;
      _message = 'Finding your location...';
    });
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _loadingLocation = false;
      _message = result.message;
      if (result.success) {
        _userLatitude = result.latitude;
        _userLongitude = result.longitude;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    final hasUserLocation = _userLatitude != null && _userLongitude != null;
    return Scaffold(
      appBar: AppBar(title: Text(widget.pub.name)),
      body: Column(
        children: [
          Expanded(
            child: PubLocationMap(
              pub: widget.pub,
              userLatitude: _userLatitude,
              userLongitude: _userLongitude,
              interactive: true,
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.pub.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text('${widget.pub.latitude.toStringAsFixed(4)}, ${widget.pub.longitude.toStringAsFixed(4)}', style: TextStyle(color: muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasUserLocation
                        ? 'Your location and the pub are both shown. Use your map app for turn-by-turn directions.'
                        : (_message ?? 'Share location to show your position on the map.'),
                    style: TextStyle(color: muted, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.navigation_outlined),
                          label: const Text('Navigate'),
                          onPressed: () => openVenueNavigation(context, widget.pub),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        icon: _loadingLocation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                        label: Text(hasUserLocation ? 'Refresh' : 'Locate me'),
                        onPressed: _loadingLocation ? null : _useMyLocation,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PubLocationMap extends StatelessWidget {
  const PubLocationMap({
    super.key,
    required this.pub,
    this.userLatitude,
    this.userLongitude,
    this.interactive = true,
  });

  final PubSpot pub;
  final double? userLatitude;
  final double? userLongitude;
  final bool interactive;

  bool get _hasUserLocation => userLatitude != null && userLongitude != null;

  @override
  Widget build(BuildContext context) {
    final pubPoint = LatLng(pub.latitude, pub.longitude);
    final userPoint = _hasUserLocation ? LatLng(userLatitude!, userLongitude!) : null;
    final center = userPoint == null ? pubPoint : _midpoint(pubPoint, userPoint);
    final distanceMeters = userPoint == null ? 0.0 : const Distance().as(LengthUnit.Meter, pubPoint, userPoint);
    final zoom = userPoint == null ? 15.5 : _zoomForDistance(distanceMeters);

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: InteractionOptions(
              flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.matchpint',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: pubPoint,
                  width: 52,
                  height: 52,
                  child: _MapMarker(
                    icon: Icons.sports_bar,
                    label: 'Pub',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (userPoint != null)
                  Marker(
                    point: userPoint,
                    width: 52,
                    height: 52,
                    child: _MapMarker(
                      icon: Icons.person_pin_circle,
                      label: 'You',
                      color: AppTheme.pintGold,
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.90),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
            ),
          ),
        ),
      ],
    );
  }

  LatLng _midpoint(LatLng a, LatLng b) => LatLng((a.latitude + b.latitude) / 2, (a.longitude + b.longitude) / 2);

  double _zoomForDistance(double metres) {
    if (metres < 700) return 15.5;
    if (metres < 1600) return 14.6;
    if (metres < 3200) return 13.8;
    if (metres < 6400) return 12.8;
    return 11.8;
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.22), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ),
      ],
    );
  }
}

Future<void> openVenueNavigation(BuildContext context, PubSpot pub) async {
  final destination = '${pub.latitude},${pub.longitude}';
  final label = Uri.encodeComponent(pub.name);
  final googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=walking');
  final geoUrl = Uri.parse('geo:${pub.latitude},${pub.longitude}?q=${pub.latitude},${pub.longitude}($label)');

  try {
    final opened = await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
    }
  } catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open a map app for ${pub.name}.')),
    );
  }
}
