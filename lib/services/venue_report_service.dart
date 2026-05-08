import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/venue_report.dart';

class VenueReportService {
  bool get isAvailable => Firebase.apps.isNotEmpty;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String aggregateId({required String pubId, required String fixtureId}) {
    return '${_safe(pubId)}__${_safe(fixtureId)}';
  }

  Future<ReportServiceResult<VenueReportAggregate>> loadAggregate({required String pubId, required String pubName, required String fixtureId, required String fixtureTitle}) async {
    if (!isAvailable) {
      return ReportServiceResult.success(
        VenueReportAggregate.empty(pubId: pubId, pubName: pubName, fixtureId: fixtureId, fixtureTitle: fixtureTitle),
        message: 'Firebase is not configured, using local comment state.',
      );
    }
    try {
      final id = aggregateId(pubId: pubId, fixtureId: fixtureId);
      final snapshot = await _db.collection('matchpint_report_aggregates').doc(id).get();
      if (!snapshot.exists || snapshot.data() == null) {
        return ReportServiceResult.success(
          VenueReportAggregate.empty(pubId: pubId, pubName: pubName, fixtureId: fixtureId, fixtureTitle: fixtureTitle),
          message: 'No comments yet.',
        );
      }
      return ReportServiceResult.success(VenueReportAggregate.fromJson(snapshot.data()!));
    } catch (error) {
      return ReportServiceResult.failure('Could not load comments yet.');
    }
  }

  Future<ReportServiceResult<VenueReportAggregate>> submitReport(VenueReport report) async {
    if (!isAvailable) {
      return ReportServiceResult.failure('Firebase is not configured on this build.');
    }
    try {
      final reportRef = _db.collection('matchpint_venue_reports').doc();
      final aggregateRef = _db.collection('matchpint_report_aggregates').doc(
            aggregateId(pubId: report.pubId, fixtureId: report.fixtureId),
          );

      await _db.runTransaction((transaction) async {
        final aggregateSnapshot = await transaction.get(aggregateRef);
        final existing = aggregateSnapshot.exists && aggregateSnapshot.data() != null
            ? VenueReportAggregate.fromJson(aggregateSnapshot.data()!)
            : VenueReportAggregate.empty(
                pubId: report.pubId,
                pubName: report.pubName,
                fixtureId: report.fixtureId,
                fixtureTitle: report.fixtureTitle,
              );

        final nextCount = existing.reportCount + 1;
        final nextConfirmed = existing.confirmedCount + (report.isShowingMatch ? 1 : 0);
        final nextAggregate = VenueReportAggregate(
          pubId: report.pubId,
          pubName: report.pubName,
          fixtureId: report.fixtureId,
          fixtureTitle: report.fixtureTitle,
          reportCount: nextCount,
          confirmedCount: nextConfirmed,
          averageScreenQuality: _weightedAverage(existing.averageScreenQuality, existing.reportCount, report.screenQuality),
          averageCrowdLevel: _weightedAverage(existing.averageCrowdLevel, existing.reportCount, report.crowdLevel),
          averageNoiseDb: _weightedAverage(existing.averageNoiseDb, existing.reportCount, report.noiseDb),
          averageFoodScore: _weightedAverage(existing.averageFoodScore, existing.reportCount, report.foodScore),
          latestNote: report.note,
          latestReporterName: report.userDisplayName,
          latestAt: report.createdAt,
        );

        transaction.set(reportRef, report.toJson());
        transaction.set(aggregateRef, nextAggregate.toJson());
      });

      final loaded = await loadAggregate(
        pubId: report.pubId,
        pubName: report.pubName,
        fixtureId: report.fixtureId,
        fixtureTitle: report.fixtureTitle,
      );
      return loaded.ok
          ? ReportServiceResult.success(loaded.value!, message: 'Thanks — your comment improved this recommendation.')
          : ReportServiceResult.failure(loaded.error ?? 'Comment saved, but the summary could not refresh yet.');
    } catch (error) {
      return ReportServiceResult.failure('Could not save this comment. Check Firestore rules and network access.');
    }
  }

  int _weightedAverage(int oldAverage, int oldCount, int newValue) {
    if (oldCount <= 0) return newValue;
    return (((oldAverage * oldCount) + newValue) / (oldCount + 1)).round();
  }

  String _safe(String input) => input.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
}

class ReportServiceResult<T> {
  const ReportServiceResult._({this.value, this.error, this.message});

  final T? value;
  final String? error;
  final String? message;

  bool get ok => error == null;

  factory ReportServiceResult.success(T value, {String? message}) => ReportServiceResult._(value: value, message: message);
  factory ReportServiceResult.failure(String error) => ReportServiceResult._(error: error);
}
