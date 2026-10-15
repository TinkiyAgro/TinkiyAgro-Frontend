import 'package:drift/drift.dart';

import '../api_client.dart';
import '../constants/app_constants.dart';
import '../offline/app_database.dart';
import 'pilot_events.dart';

class EvaluationAnalyticsService {
  EvaluationAnalyticsService._();
  static final instance = EvaluationAnalyticsService._();

  final AppDatabase _db = AppDatabase.instance;

  Future<void> impression({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) async {
    // Pilot impressions require a server-issued list, never a search result.
    if (section == 'RECOMMENDED' || section == 'POPULAR') {
      await PilotEventsQueue.instance.record('ITEM_IMPRESSION', listId: requestId, productId: productId);
    }
  }

  Future<void> click({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) => PilotEventsQueue.instance.record('CLICK', productId: productId,
      listId: section == 'RECOMMENDED' || section == 'POPULAR' ? requestId : null);

  Future<void> addToCart({
    required String productId,
    required String farmer,
    required String section,
    required int position,
    String? requestId,
  }) =>
      PilotEventsQueue.instance.record('INTEREST', productId: productId,
          listId: section == 'RECOMMENDED' || section == 'POPULAR' ? requestId : null);

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
                'clientCreatedAt': event.createdAt.toUtc().toIso8601String(),
                'enqueuedAt': event.enqueuedAt.toUtc().toIso8601String(),
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
