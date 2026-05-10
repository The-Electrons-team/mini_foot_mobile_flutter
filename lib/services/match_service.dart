import 'api_service.dart';

class MatchService {
  final ApiService _api = ApiService();

  Future<List<dynamic>> getMatches({String? token, String? zone}) async {
    var url = '/matches';
    if (zone != null) url += '?zone=$zone';
    
    return await _api.get(
      url,
      token: token,
      defaultErrorMsg: 'Erreur chargement matchs',
    );
  }

  Future<List<dynamic>> getMyTeamMatches(String token, String teamId, {String? status, String? opponentId, String? date, int? page, int? limit}) async {
    var url = '/matches/team/$teamId';
    List<String> queries = [];
    if (status != null) queries.add('status=$status');
    if (opponentId != null) queries.add('opponentId=$opponentId');
    if (date != null) queries.add('date=$date');
    if (page != null) queries.add('page=$page');
    if (limit != null) queries.add('limit=$limit');
    
    if (queries.isNotEmpty) {
      url += '?${queries.join('&')}';
    }

    return await _api.get(
      url,
      token: token,
      defaultErrorMsg: 'Erreur chargement matchs équipe',
    );
  }

  Future<List<dynamic>> getPendingChallenges(String token, String teamId) async {
    return await _api.get(
      '/matches/challenges/pending/$teamId',
      token: token,
      defaultErrorMsg: 'Erreur chargement défis',
    );
  }

  Future<List<dynamic>> getTeamChallenges(String token, String teamId) async {
    return await _api.get(
      '/matches/challenges/team/$teamId',
      token: token,
      defaultErrorMsg: 'Erreur chargement défis',
    );
  }

  Future<void> sendChallenge({
    required String token,
    required String fromTeamId,
    required String opponentTeamId,
    required String date,
    required String time,
    required int durationMinutes,
    required String zone,
    required String format,
    required String terrainId,
    String? subTerrainId,
    String? terrainName,
  }) async {
    final body = {
      'fromTeamId': fromTeamId,
      'toTeamId': opponentTeamId,
      'date': date,
      'time': time,
      'durationMinutes': durationMinutes,
      'zone': zone,
      'format': format,
      'terrainId': terrainId,
      if (subTerrainId != null && subTerrainId.isNotEmpty) 'subTerrainId': subTerrainId,
      if (terrainName != null && terrainName.isNotEmpty) 'terrainName': terrainName,
    };
    
    await _api.post(
      '/matches/challenge',
      body: body,
      token: token,
      defaultErrorMsg: 'Erreur envoi défi',
    );
  }

  Future<void> respondChallenge(String token, String challengeId, bool accept) async {
    await _api.patch(
      '/matches/challenge/$challengeId/respond',
      body: {'accept': accept},
      token: token,
      defaultErrorMsg: 'Erreur réponse défi',
    );
  }

  Future<Map<String, dynamic>> getChallengePaymentLink(String token, String challengeId) async {
    return await _api.post(
      '/matches/challenge/$challengeId/payment-link',
      body: {},
      token: token,
      defaultErrorMsg: 'Erreur paiement défi',
    );
  }

  Future<void> updateScore(String token, String matchId, int homeScore, int awayScore) async {
    await _api.patch(
      '/matches/$matchId/score',
      body: {'homeScore': homeScore, 'awayScore': awayScore},
      token: token,
      defaultErrorMsg: 'Erreur mise à jour score',
    );
  }
}
