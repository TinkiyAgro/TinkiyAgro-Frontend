import '../session_manager.dart';

class PilotSession {
  static const participantId = String.fromEnvironment('PILOT_PARTICIPANT_ID');
  static const sessionId = String.fromEnvironment('PILOT_SESSION_ID');
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
