import '../session_manager.dart';
import 'package:uuid/uuid.dart';

class PilotSessionClock {
  PilotSessionClock({DateTime Function()? clock}) : clock = clock ?? DateTime.now;
  final DateTime Function() clock;
  String? _id;
  String? _owner;
  DateTime? _lastActivity;

  String current(String? owner, {bool activity = false}) {
    final now = clock();
    if (_id == null || owner != _owner ||
        (_lastActivity != null && now.difference(_lastActivity!) >= const Duration(minutes: 30))) {
      _id = const Uuid().v4();
      _owner = owner;
      _lastActivity = now;
    }
    if (activity) _lastActivity = now;
    return _id!;
  }
}

class PilotSession {
  static const participantId = String.fromEnvironment('PILOT_PARTICIPANT_ID');
  static final _clock = PilotSessionClock();
  static String get sessionId => _clock.current(SessionManager().username);
  static void activity() => _clock.current(SessionManager().username, activity: true);
  static const networkCondition = String.fromEnvironment(
    'PILOT_NETWORK_CONDITION',
    defaultValue: 'TOTAL',
  );
  static const _configuredOrder = String.fromEnvironment('PILOT_SECTION_ORDER');

  static String get sectionOrder {
    if (_configuredOrder == 'POPULARES_FIRST') return _configuredOrder;
    if (_configuredOrder == 'PARA_TI_FIRST') return _configuredOrder;
    final identity = participantId.isNotEmpty
        ? participantId
        : (SessionManager().username ?? 'anonymous');
    return identity.codeUnits.fold<int>(0, (sum, value) => sum + value).isEven
        ? 'PARA_TI_FIRST'
        : 'POPULARES_FIRST';
  }
}
