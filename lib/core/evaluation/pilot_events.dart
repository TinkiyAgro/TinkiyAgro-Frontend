import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../api_client.dart';
import '../offline/app_database.dart';
import '../session_manager.dart';
import 'pilot_session.dart';

typedef PilotBatchSender = Future<List<dynamic>> Function(List<Map<String, dynamic>> events);

class PilotEventsQueue {
  PilotEventsQueue(this.db, {required this.owner, required this.send, DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  static final instance = PilotEventsQueue(
    AppDatabase.instance,
    owner: () => SessionManager().isLoggedIn ? SessionManager().username : null,
    send: (events) async {
      final response = await ApiClient.post('/api/pilot/events/batch', events)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('HTTP ${response.statusCode}');
      }
      return jsonDecode(response.body) as List;
    },
  );

  final AppDatabase db;
  final String? Function() owner;
  final PilotBatchSender send;
  final DateTime Function() clock;
  bool _sending = false;

  Future<void> record(String type, {String? listId, String? productId, String? sessionId}) async {
    final identity = owner();
    if (identity == null || identity.isEmpty) return;
    final now = clock().toUtc();
    final id = const Uuid().v4();
    final once = type == 'LIST_VIEWED' || type == 'ITEM_IMPRESSION';
    if (once && listId == null) return;
    await db.into(db.pilotEvents).insert(
      PilotEventsCompanion.insert(
        id: id,
        owner: identity,
        payload: jsonEncode({
          'eventId': id,
          'type': type,
          'occurredAt': now.toIso8601String(),
          'sessionId': sessionId ?? PilotSession.sessionId,
          'listId': listId,
          'productId': productId,
        }),
        dedupKey: Value(once ? '$identity|$type|$listId|$productId' : null),
        nextAttemptAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> syncPending() async {
    final identity = owner();
    if (_sending || identity == null) return;
    _sending = true;
    try {
      final pending = await (db.select(db.pilotEvents)
        ..where((e) => e.owner.equals(identity) & e.state.equals('PENDING') & e.nextAttemptAt.isSmallerOrEqualValue(clock().toUtc()))
        ..limit(100)).get();
      if (pending.isEmpty) return;
      List<dynamic> results;
      try {
        results = await send(pending.map((e) => (jsonDecode(e.payload) as Map).cast<String, dynamic>()).toList());
      } catch (error) {
        for (final event in pending) {
          await _retry(event, error.toString());
        }
        return;
      }
      final receipts = <String, Map>{
        for (final result in results.whereType<Map>())
          if (result['eventId'] is String) result['eventId'] as String: result,
      };
      for (final event in pending) {
        final receipt = receipts[event.id];
        final status = receipt?['status'];
        if (status == 'ACCEPTED' || status == 'DUPLICATE') {
          await (db.update(db.pilotEvents)..where((e) => e.id.equals(event.id))).write(
            PilotEventsCompanion(state: const Value('SYNCED'), syncedAt: Value(clock().toUtc()), lastError: const Value(null)),
          );
        } else if (status == 'REJECTED') {
          await (db.update(db.pilotEvents)..where((e) => e.id.equals(event.id))).write(
            PilotEventsCompanion(state: const Value('FAILED'), lastError: Value(receipt?['reason']?.toString() ?? 'REJECTED')),
          );
        } else {
          await _retry(event, 'Missing or invalid acknowledgement');
        }
      }
    } finally {
      _sending = false;
    }
  }

  Future<void> _retry(PilotEvent event, String reason) =>
      (db.update(db.pilotEvents)..where((e) => e.id.equals(event.id))).write(
        PilotEventsCompanion(
          attempts: Value(event.attempts + 1),
          nextAttemptAt: Value(clock().toUtc().add(Duration(seconds: min(900, 5 * pow(2, min(event.attempts, 8)).toInt())))),
          lastError: Value(reason),
        ),
      );
}
