class VenueReport {
  const VenueReport({
    this.id,
    required this.userId,
    required this.userDisplayName,
    required this.pubId,
    required this.pubName,
    required this.fixtureId,
    required this.fixtureTitle,
    required this.isShowingMatch,
    required this.screenQuality,
    required this.crowdLevel,
    required this.noiseDb,
    required this.foodScore,
    required this.tags,
    required this.note,
    required this.createdAt,
  });

  final String? id;
  final String userId;
  final String userDisplayName;
  final String pubId;
  final String pubName;
  final String fixtureId;
  final String fixtureTitle;
  final bool isShowingMatch;
  final int screenQuality;
  final int crowdLevel;
  final int noiseDb;
  final int foodScore;
  final List<String> tags;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userDisplayName': userDisplayName,
        'pubId': pubId,
        'pubName': pubName,
        'fixtureId': fixtureId,
        'fixtureTitle': fixtureTitle,
        'isShowingMatch': isShowingMatch,
        'screenQuality': screenQuality,
        'crowdLevel': crowdLevel,
        'noiseDb': noiseDb,
        'foodScore': foodScore,
        'tags': tags,
        'note': note,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory VenueReport.fromJson(Map<String, dynamic> json, {String? id}) {
    return VenueReport(
      id: id,
      userId: json['userId']?.toString() ?? '',
      userDisplayName: json['userDisplayName']?.toString() ?? 'MatchPint fan',
      pubId: json['pubId']?.toString() ?? '',
      pubName: json['pubName']?.toString() ?? '',
      fixtureId: json['fixtureId']?.toString() ?? '',
      fixtureTitle: json['fixtureTitle']?.toString() ?? '',
      isShowingMatch: json['isShowingMatch'] == true,
      screenQuality: _readInt(json['screenQuality'], fallback: 70),
      crowdLevel: _readInt(json['crowdLevel'], fallback: 60),
      noiseDb: _readInt(json['noiseDb'], fallback: 65),
      foodScore: _readInt(json['foodScore'], fallback: 70),
      tags: (json['tags'] as List<dynamic>? ?? const []).map((item) => item.toString()).toList(),
      note: json['note']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
    );
  }

  static int _readInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class VenueReportAggregate {
  const VenueReportAggregate({
    required this.pubId,
    required this.pubName,
    required this.fixtureId,
    required this.fixtureTitle,
    required this.reportCount,
    required this.confirmedCount,
    required this.averageScreenQuality,
    required this.averageCrowdLevel,
    required this.averageNoiseDb,
    required this.averageFoodScore,
    required this.latestNote,
    required this.latestReporterName,
    required this.latestAt,
  });

  final String pubId;
  final String pubName;
  final String fixtureId;
  final String fixtureTitle;
  final int reportCount;
  final int confirmedCount;
  final int averageScreenQuality;
  final int averageCrowdLevel;
  final int averageNoiseDb;
  final int averageFoodScore;
  final String latestNote;
  final String latestReporterName;
  final DateTime? latestAt;

  bool get hasReports => reportCount > 0;
  bool get isUserConfirmed => confirmedCount > 0;
  int get confidenceBoost => (confirmedCount * 8 + reportCount * 2).clamp(0, 24);
  String get statusLabel => isUserConfirmed ? 'User-confirmed showing' : 'No live user confirmation yet';

  Map<String, dynamic> toJson() => {
        'pubId': pubId,
        'pubName': pubName,
        'fixtureId': fixtureId,
        'fixtureTitle': fixtureTitle,
        'reportCount': reportCount,
        'confirmedCount': confirmedCount,
        'averageScreenQuality': averageScreenQuality,
        'averageCrowdLevel': averageCrowdLevel,
        'averageNoiseDb': averageNoiseDb,
        'averageFoodScore': averageFoodScore,
        'latestNote': latestNote,
        'latestReporterName': latestReporterName,
        'latestAt': latestAt?.toUtc().toIso8601String(),
      };

  factory VenueReportAggregate.fromJson(Map<String, dynamic> json) {
    return VenueReportAggregate(
      pubId: json['pubId']?.toString() ?? '',
      pubName: json['pubName']?.toString() ?? '',
      fixtureId: json['fixtureId']?.toString() ?? '',
      fixtureTitle: json['fixtureTitle']?.toString() ?? '',
      reportCount: VenueReport._readInt(json['reportCount'], fallback: 0),
      confirmedCount: VenueReport._readInt(json['confirmedCount'], fallback: 0),
      averageScreenQuality: VenueReport._readInt(json['averageScreenQuality'], fallback: 70),
      averageCrowdLevel: VenueReport._readInt(json['averageCrowdLevel'], fallback: 60),
      averageNoiseDb: VenueReport._readInt(json['averageNoiseDb'], fallback: 65),
      averageFoodScore: VenueReport._readInt(json['averageFoodScore'], fallback: 70),
      latestNote: json['latestNote']?.toString() ?? '',
      latestReporterName: json['latestReporterName']?.toString() ?? '',
      latestAt: DateTime.tryParse(json['latestAt']?.toString() ?? '')?.toLocal(),
    );
  }

  factory VenueReportAggregate.empty({required String pubId, required String pubName, required String fixtureId, required String fixtureTitle}) {
    return VenueReportAggregate(
      pubId: pubId,
      pubName: pubName,
      fixtureId: fixtureId,
      fixtureTitle: fixtureTitle,
      reportCount: 0,
      confirmedCount: 0,
      averageScreenQuality: 70,
      averageCrowdLevel: 60,
      averageNoiseDb: 65,
      averageFoodScore: 70,
      latestNote: '',
      latestReporterName: '',
      latestAt: null,
    );
  }
}
