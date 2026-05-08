import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/mock_data.dart';
import '../models/match_fixture.dart';
import '../models/pub_spot.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/pub_card.dart';

class PubListScreen extends StatefulWidget {
  const PubListScreen({
    super.key,
    required this.preferences,
    required this.onOpenPub,
    required this.pubs,
    required this.fixtures,
    required this.liveDataMessage,
    required this.locationMessage,
    required this.gettingLocation,
    required this.onUseCurrentLocation,
    required this.onChooseLocation,
    this.fixture,
  });

  final UserPreferences preferences;
  final ValueChanged<PubSpot> onOpenPub;
  final List<PubSpot> pubs;
  final List<MatchFixture> fixtures;
  final String liveDataMessage;
  final String locationMessage;
  final bool gettingLocation;
  final Future<void> Function() onUseCurrentLocation;
  final Future<void> Function(double latitude, double longitude, String label) onChooseLocation;
  final MatchFixture? fixture;

  @override
  State<PubListScreen> createState() => _PubListScreenState();
}

class _LocationPickResult {
  const _LocationPickResult({required this.latitude, required this.longitude, required this.label, this.useCurrentLocation = false});

  final double latitude;
  final double longitude;
  final String label;
  final bool useCurrentLocation;
}

class _PubListScreenState extends State<PubListScreen> {
  bool _calmOnly = false;
  bool _soloOnly = false;
  bool _foodFirst = false;
  bool _verifiedOnly = false;
  String _query = '';


  bool _matchesFixture(PubSpot pub, MatchFixture fixture) => pubIsShowingFixture(pub, fixture);

  int _fixtureBoost(PubSpot pub, MatchFixture? fixture) {
    final selectedFixture = fixture ?? bestFixtureForPub(pub, preferences: widget.preferences, fixtures: _fixtures);
    return (fixtureBroadcastScore(pub, selectedFixture) / 4).round();
  }

  List<MatchFixture> get _fixtures => widget.fixtures.isEmpty ? mockFixtures : widget.fixtures;
  List<PubSpot> get _pubs => widget.pubs.isEmpty ? mockPubs : widget.pubs;

  double _distanceFor(PubSpot pub) => pub.distanceKm;

  Future<void> _openLocationChooser() async {
    final initial = LatLng(
      _pubs.isNotEmpty ? _pubs.first.latitude : 51.5074,
      _pubs.isNotEmpty ? _pubs.first.longitude : -0.1278,
    );
    final selected = await showModalBottomSheet<_LocationPickResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _LocationPickerSheet(initialPoint: initial),
    );
    if (!mounted || selected == null) return;
    if (selected.useCurrentLocation) {
      await widget.onUseCurrentLocation();
    } else {
      await widget.onChooseLocation(selected.latitude, selected.longitude, selected.label);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.fixture == null ? 'Find pubs' : 'Pubs for ${widget.fixture!.title}';
    final q = _query.trim().toLowerCase();
    final fixture = widget.fixture;
    final allPubs = _pubs;
    final fixtureMatched = fixture == null ? allPubs : allPubs.where((p) => _matchesFixture(p, fixture)).toList();
    final basePubs = fixture == null || fixtureMatched.isNotEmpty ? fixtureMatched : allPubs;
    final pubs = basePubs.where((p) {
      if (_calmOnly && p.noiseDb > 65) return false;
      if (_soloOnly && !p.soloFriendly) return false;
      if (_verifiedOnly && !p.verifiedFootballFriendly) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.area.toLowerCase().contains(q) ||
          p.features.any((f) => f.toLowerCase().contains(q)) ||
          p.sportsEvidenceReasons.any((reason) => reason.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) {
        if (_foodFirst) return b.foodScore.compareTo(a.foodScore);
        final aDistance = _distanceFor(a);
        final bDistance = _distanceFor(b);
        final aScore = a.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst) +
            _fixtureBoost(a, fixture) +
            (a.sportsEvidenceScore / 5).round() -
            (aDistance * 4).round();
        final bScore = b.comfortScore(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly, wantsFood: widget.preferences.wantsFood || _foodFirst) +
            _fixtureBoost(b, fixture) +
            (b.sportsEvidenceScore / 5).round() -
            (bDistance * 4).round();
        return bScore.compareTo(aScore);
      });

    final prefs = widget.preferences.copyWith(prefersCalm: widget.preferences.prefersCalm || _calmOnly, soloMode: widget.preferences.soloMode || _soloOnly);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 110),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Recommended pubs ranked by match fit, location, atmosphere, and screen confidence.', style: TextStyle(color: AppTheme.subtleText(context))),
        const SizedBox(height: 16),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search pub, area, or feature'),
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.place, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(widget.locationMessage, style: TextStyle(color: AppTheme.subtleText(context)))),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: widget.gettingLocation ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.travel_explore),
                    label: Text(widget.gettingLocation ? 'Updating pubs...' : 'Choose location'),
                    onPressed: widget.gettingLocation ? null : _openLocationChooser,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: [
          FilterChip(label: const Text('Calm only'), selected: _calmOnly, onSelected: (v) => setState(() => _calmOnly = v)),
          FilterChip(label: const Text('Solo-friendly'), selected: _soloOnly, onSelected: (v) => setState(() => _soloOnly = v)),
          FilterChip(label: const Text('Food first'), selected: _foodFirst, onSelected: (v) => setState(() => _foodFirst = v)),
          FilterChip(label: const Text('Verified only'), selected: _verifiedOnly, onSelected: (v) => setState(() => _verifiedOnly = v)),
        ]),
        const SizedBox(height: 18),
        if (pubs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text('No venues match your current filters. Try another area or turn off Verified only.', style: TextStyle(color: AppTheme.subtleText(context))),
            ),
          )
        else
          ...pubs.map((p) {
            final selectedFixture = fixture ?? bestFixtureForPub(p, preferences: widget.preferences, fixtures: _fixtures);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PubCard(
                pub: p,
                preferences: prefs,
                distanceKmOverride: _distanceFor(p),
                matchLabel: selectedFixture.title,
                broadcastConfidence: fixtureBroadcastScore(p, selectedFixture),
                onTap: () => widget.onOpenPub(p),
              ),
            );
          }),
      ],
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.initialPoint});

  final LatLng initialPoint;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late LatLng _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    final muted = AppTheme.subtleText(context);
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose location',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text('Tap the map to choose where MatchPint should search.', style: TextStyle(color: muted)),
              const SizedBox(height: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: _selectedPoint,
                          initialZoom: 13.4,
                          onTap: (_, point) => setState(() => _selectedPoint = point),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.matchpint',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _selectedPoint,
                                width: 52,
                                height: 52,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.22),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.place, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        top: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(
                              'Selected: ${_selectedPoint.latitude.toStringAsFixed(4)}, ${_selectedPoint.longitude.toStringAsFixed(4)}',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use my location'),
                      onPressed: () => Navigator.of(context).pop(
                        const _LocationPickResult(latitude: 0, longitude: 0, label: 'Current location', useCurrentLocation: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Search here'),
                      onPressed: () => Navigator.of(context).pop(
                        _LocationPickResult(
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          label: 'selected map area',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

