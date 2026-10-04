import 'dart:convert';
import '../api_client.dart';
import 'pilot_session.dart';

class PilotFeedList {
  PilotFeedList.fromJson(Map<String, dynamic> json, this.sessionId)
      : id = json['id'] as String,
        segment = json['segment'] as String,
        section = json['section'] as String,
        blockPosition = (json['blockPosition'] as num).toInt(),
        listPosition = (json['listPosition'] as num).toInt(),
        recBasis = json['recBasis']?.toString(),
        items = (json['items'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  final String id, sessionId, segment, section;
  final String? recBasis;
  final int blockPosition, listPosition;
  final List<Map<String, dynamic>> items;
}

class PilotFeedService {
  Future<List<PilotFeedList>> load() async {
    final session = PilotSession.sessionId;
    final response = await ApiClient.get('/api/home/feed?session_id=$session');
    if (response.statusCode != 200) throw StateError('No se pudo cargar el inicio');
    return parse(jsonDecode(response.body) as Map<String, dynamic>, session);
  }

  static List<PilotFeedList> parse(Map<String, dynamic> json, String session) {
    final lists = (json['lists'] as List).whereType<Map>()
        .where((e) => e['displayed'] != false && e['variant'] != 'SHADOW_NO_CARS')
        .map((e) => PilotFeedList.fromJson(e.cast<String, dynamic>(), session))
        .where((e) => const ['RETAIL', 'WHOLESALE'].contains(e.segment) && const ['RECOMMENDED', 'POPULAR'].contains(e.section))
        .toList();
    lists.sort((a, b) {
      final block = a.blockPosition.compareTo(b.blockPosition);
      return block == 0 ? a.listPosition.compareTo(b.listPosition) : block;
    });
    return lists;
  }
}
