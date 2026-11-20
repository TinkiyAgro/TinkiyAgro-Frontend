import 'package:flutter_test/flutter_test.dart';
import 'package:tinkiyagro_app/core/evaluation/pilot_feed.dart';

void main() {
  test('parses the visible agricultural season from the feed', () {
    final feed = PilotFeedService.parse({
      'lists': <Object>[],
      'season': {
        'date': '2026-11-15',
        'month': 11,
        'monthName': 'noviembre',
        'timezone': 'America/Lima',
      },
    }, 'session');

    expect(feed.lists, isEmpty);
    expect(feed.season?.monthName, 'noviembre');
    expect(feed.season?.date, DateTime(2026, 11, 15));
    expect(feed.season?.timezone, 'America/Lima');
  });
}
