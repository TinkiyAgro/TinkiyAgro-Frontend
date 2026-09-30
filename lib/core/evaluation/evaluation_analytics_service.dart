import 'dart:async';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api_client.dart';
import '../constants/app_constants.dart';
import '../offline/app_database.dart';
import 'pilot_session.dart';

class EvaluationAnalyticsService {
  EvaluationAnalyticsService._();
  static final instance = EvaluationAnalyticsService._();

  final AppDatabase _db = AppDatabase.instance;
  final Set<String> _impressions = <String>{};

  Future<void> impression({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) async {
    final key = '${PilotSession.sessionId}|$requestId|$section|$productId';
    if (!_impressions.add(key)) return;
    await _enqueue(
      'IMPRESSION',
      productId,
      farmer,
      section,
      position,
      requestId,
    );
  }

  Future<void> click({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) => _enqueue('CLICK', productId, farmer, section, position, requestId);

  Future<void> addToCart({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) =>
      _enqueue('ADD_TO_CART', productId, farmer, section, position, requestId);

  Future<void> _enqueue(
    String type,
    String productId,
    String farmer,
    String section,
    int position,
    String? requestId,
  ) async {
    if (farmer.isEmpty || section.isEmpty || position < 1) return;
    final now = DateTime.now().toUtc();
    await _db
        .into(_db.pendingEvaluationEvents)
        .insert(
          PendingEvaluationEventsCompanion.insert(
            id: const Uuid().v4(),
            eventType: type,
            productId: productId,
            farmerUsername: farmer,
            sourceSection: section,
            listPosition: position,
            createdAt: now,
            enqueuedAt: now,
            recommendationRequestId: Value(requestId),
            participantId: Value(
              PilotSession.participantId.isEmpty
                  ? null
                  : PilotSession.participantId,
            ),
            pilotSessionId: Value(
              PilotSession.sessionId.isEmpty ? null : PilotSession.sessionId,
            ),
            networkCondition: const Value(PilotSession.networkCondition),
          ),
        );
    unawaited(syncPending());
  }

  Future<void> syncPending() async {
    final pending =
        await (_db.select(_db.pendingEvaluationEvents)
              ..where(
                (row) =>
                    row.state.equals('PENDING') | row.state.equals('FAILED'),
              )
              ..limit(200))
            .get();
    if (pending.isEmpty) return;
    try {
      final response = await ApiClient.post(
        AppConstants.evaluationEventsEndpoint,
        pending
            .map(
              (event) => {
                'clientEventId': event.id,
                'eventType': event.eventType,
                'productId': event.productId,
                'farmerUsername': event.farmerUsername,
                'sourceSection': event.sourceSection,
                'listPosition': event.listPosition,
                'recommendationRequestId': event.recommendationRequestId,
                'participantId': event.participantId,
                'pilotSessionId': event.pilotSessionId,
                'clientCreatedAt': event.createdAt.toIso8601String(),
                'enqueuedAt': event.enqueuedAt.toIso8601String(),
                'networkCondition': event.networkCondition,
              },
            )
            .toList(),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }
      final ids = pending.map((event) => event.id).toList();
      await (_db.update(
        _db.pendingEvaluationEvents,
      )..where((row) => row.id.isIn(ids))).write(
        PendingEvaluationEventsCompanion(
          state: const Value('SYNCED'),
          syncedAt: Value(DateTime.now().toUtc()),
          lastError: const Value(null),
        ),
      );
    } catch (error) {
      final ids = pending.map((event) => event.id).toList();
      await (_db.update(
        _db.pendingEvaluationEvents,
      )..where((row) => row.id.isIn(ids))).write(
        PendingEvaluationEventsCompanion(
          state: const Value('FAILED'),
          lastError: Value(error.toString()),
        ),
      );
    }
  }
}
