class ExternalSportsVenueEvidence {
  const ExternalSportsVenueEvidence({
    required this.name,
    required this.aliases,
    required this.area,
    required this.sourceName,
    required this.sourceUrl,
    required this.evidenceLabel,
    required this.features,
    required this.score,
  });

  final String name;
  final List<String> aliases;
  final String area;
  final String sourceName;
  final String sourceUrl;
  final String evidenceLabel;
  final List<String> features;
  final int score;
}

/// Small externally sourced seed list for venues with published live-sport / screen evidence.
///
/// This is intentionally not a hidden keyword dictionary. Each entry is tied to a public
/// source page that states the venue is a live-sport / football-friendly pub or lists
/// concrete sport-screening facilities such as Sky Sports, TNT Sports, big screens or
/// multiple screens. MatchPint still predicts the most suitable fixture; this list only
/// helps prevent ordinary pubs with no evidence of screens from being ranked as sports pubs.
const externalSportsVenueEvidence = <ExternalSportsVenueEvidence>[
  ExternalSportsVenueEvidence(
    name: 'The Pavilion End',
    aliases: ['pavilion end'],
    area: 'City of London',
    sourceName: 'Fuller\'s venue page',
    sourceUrl: 'https://www.pavilionendpub.co.uk/',
    evidenceLabel: 'External source: Big Screen Sports Viewing, Sky TV and TNT Sports listed.',
    features: ['Big Screen Sports Viewing', 'Sky TV', 'TNT Sports', 'Darts Board'],
    score: 96,
  ),
  ExternalSportsVenueEvidence(
    name: 'The Euston Flyer',
    aliases: ['euston flyer'],
    area: 'Euston',
    sourceName: 'Fuller\'s venue page',
    sourceUrl: 'https://www.eustonflyer.co.uk/',
    evidenceLabel: 'External source: Sky and TNT Sports packages listed for Premier League and Champions League.',
    features: ['Sky TV', 'TNT Sports', 'Big Screen Sports Viewing', 'Live Sport'],
    score: 94,
  ),
  ExternalSportsVenueEvidence(
    name: 'The Maple Leaf',
    aliases: ['maple leaf', 'the maple leaf'],
    area: 'Covent Garden',
    sourceName: 'Greene King football page',
    sourceUrl: 'https://www.greeneking.co.uk/pubs-near-me/london/football',
    evidenceLabel: 'External source: listed by Greene King as a London football pub with strong sports selection.',
    features: ['Football pub listing', 'Live football', 'Sports atmosphere'],
    score: 88,
  ),
  ExternalSportsVenueEvidence(
    name: 'The King\'s Head',
    aliases: ['king\'s head', 'the kings head', 'kings head'],
    area: 'Tooting',
    sourceName: 'Greene King football page',
    sourceUrl: 'https://www.greeneking.co.uk/pubs-near-me/london/football',
    evidenceLabel: 'External source: listed by Greene King as one of London\'s sports pubs.',
    features: ['Football pub listing', 'Sports pub', 'Pub classics'],
    score: 82,
  ),
  ExternalSportsVenueEvidence(
    name: 'Belushi\'s London Bridge',
    aliases: ['belushi\'s london bridge', 'belushis london bridge', 'belushi london bridge', 'belushi\'s'],
    area: 'London Bridge',
    sourceName: 'Belushi\'s venue page',
    sourceUrl: 'https://belushis.com/london-bridge',
    evidenceLabel: 'External source: venue describes multi-screen viewing and huge projectors for Premier League football.',
    features: ['Multi-screen viewing', 'Huge projectors', 'Premier League football'],
    score: 97,
  ),
  ExternalSportsVenueEvidence(
    name: 'Belushi\'s Hammersmith',
    aliases: ['belushi\'s hammersmith', 'belushis hammersmith', 'belushi hammersmith'],
    area: 'Hammersmith',
    sourceName: 'FANZO venue page',
    sourceUrl: 'https://www.fanzo.com/en/bar/1387/belushi-s-hammersmith',
    evidenceLabel: 'External source: FANZO lists stadium-style seating, projector and 20 HD TVs.',
    features: ['20 HD TVs', 'Projector', 'Stadium-style seating'],
    score: 96,
  ),
  ExternalSportsVenueEvidence(
    name: 'The Famous Three Kings',
    aliases: ['famous three kings', 'the famous three kings', 'f3k'],
    area: 'West Kensington',
    sourceName: 'Famous Three Kings venue page',
    sourceUrl: 'https://famousthreekings.co.uk/',
    evidenceLabel: 'External source: venue lists 30+ screens and Sky/TNT Sports for football and other live sport.',
    features: ['30+ screens', 'Sky Sports', 'TNT Sports', 'Projectors'],
    score: 98,
  ),
  ExternalSportsVenueEvidence(
    name: 'Philomena\'s Irish Sports Bar & Kitchen',
    aliases: ['philomena\'s', 'philomenas', 'philomena\'s irish sports bar', 'philomenas irish sports bar'],
    area: 'Covent Garden',
    sourceName: 'FANZO venue page',
    sourceUrl: 'https://www.fanzo.com/en/bar/1406/philomena-s-irish-sports-bar-kitchen',
    evidenceLabel: 'External source: FANZO lists multiple screens and sport-focused viewing.',
    features: ['Sports bar', 'Multiple screens', 'Sky boxes'],
    score: 95,
  ),
  ExternalSportsVenueEvidence(
    name: 'Greenwood',
    aliases: ['greenwood', 'greenwood sports pub', 'greenwood sports pub and kitchen'],
    area: 'Victoria',
    sourceName: 'Greenwood / Sport London venue page',
    sourceUrl: 'https://www.sportlondon.com/greenwood',
    evidenceLabel: 'External source: venue describes giant UHD screens and live sports coverage near Victoria.',
    features: ['Giant UHD screens', 'Live sports pub', 'State-of-the-art sound'],
    score: 96,
  ),
  ExternalSportsVenueEvidence(
    name: 'The Three Crowns',
    aliases: ['three crowns', 'the three crowns'],
    area: 'London',
    sourceName: 'Greene King venue page',
    sourceUrl: 'https://www.greeneking.co.uk/pubs/greater-london/three-crowns/sports/live-football',
    evidenceLabel: 'External source: venue lists big screens, Sky Sports football, TNT Sports, BBC and ITV.',
    features: ['Big screens', 'Sky Sports football', 'TNT Sports', 'BBC / ITV'],
    score: 92,
  ),
  ExternalSportsVenueEvidence(
    name: 'Sports Bar & Grill Victoria',
    aliases: ['sports bar and grill victoria', 'sports bar & grill victoria', 'sports bar grill victoria'],
    area: 'Victoria',
    sourceName: 'Hotels.com London sports bars guide',
    sourceUrl: 'https://www.hoteis.com/go/england/best-sports-bars-london',
    evidenceLabel: 'External source: listed as a sports bar with screens and Sky/TNT Sports coverage.',
    features: ['Sports bar guide listing', 'Sky Sports', 'TNT Sports', 'Screens'],
    score: 87,
  ),
];

ExternalSportsVenueEvidence? externalSportsVenueEvidenceForName(String venueName) {
  final normalisedVenue = _normaliseVenueName(venueName);
  for (final evidence in externalSportsVenueEvidence) {
    final allNames = [evidence.name, ...evidence.aliases];
    for (final candidate in allNames) {
      final normalisedCandidate = _normaliseVenueName(candidate);
      if (normalisedVenue == normalisedCandidate) return evidence;
      if (normalisedCandidate.length >= 8 && normalisedVenue.contains(normalisedCandidate)) return evidence;
      if (normalisedVenue.length >= 8 && normalisedCandidate.contains(normalisedVenue)) return evidence;
    }
  }
  return null;
}

String _normaliseVenueName(String value) {
  return value
      .toLowerCase()
      .replaceAll('&', 'and')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .replaceAll(RegExp(r'\bthe\b'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
