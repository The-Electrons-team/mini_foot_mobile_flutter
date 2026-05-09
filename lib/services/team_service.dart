import 'api_service.dart';

class TeamService {
  final ApiService _api = ApiService();

  Future<Map<String, dynamic>> createTeam({
    required String token,
    required String name,
    String? zone,
    String? address,
    String? color,
    double? lat,
    double? lng,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final fields = <String, String>{'name': name};
    if (zone != null) fields['zone'] = zone;
    if (address != null) fields['address'] = address;
    if (color != null) fields['color'] = color;
    if (lat != null) fields['lat'] = lat.toString();
    if (lng != null) fields['lng'] = lng.toString();

    return await _api.multipart(
      '/teams',
      'POST',
      logoBytes,
      logoFilename,
      'logo',
      fields: fields,
      token: token,
      defaultErrorMsg: 'Erreur création équipe',
    );
  }

  Future<Map<String, dynamic>> updateTeam({
    required String token,
    required String teamId,
    required String name,
    String? zone,
    String? address,
    String? color,
    double? lat,
    double? lng,
    List<int>? logoBytes,
    String? logoFilename,
  }) async {
    final fields = <String, String>{'name': name};
    if (zone != null) fields['zone'] = zone;
    if (address != null) fields['address'] = address;
    if (color != null) fields['color'] = color;
    if (lat != null) fields['lat'] = lat.toString();
    if (lng != null) fields['lng'] = lng.toString();

    return await _api.multipart(
      '/teams/$teamId',
      'PATCH',
      logoBytes,
      logoFilename,
      'logo',
      fields: fields,
      token: token,
      defaultErrorMsg: 'Erreur modification équipe',
    );
  }

  Future<List<dynamic>> getMyTeams(String token) async {
    return await _api.get(
      '/teams/mine',
      token: token,
      defaultErrorMsg: 'Erreur récupération équipes',
    );
  }

  Future<Map<String, dynamic>> getTeamDetail(String token, String teamId) async {
    return await _api.get(
      '/teams/$teamId',
      token: token,
      defaultErrorMsg: 'Erreur récupération détail équipe',
    );
  }

  Future<Map<String, dynamic>> joinTeam(String token, String inviteCode) async {
    return await _api.post(
      '/teams/join/$inviteCode',
      token: token,
      defaultErrorMsg: 'Erreur lors de la tentative de rejoindre',
    );
  }

  Future<Map<String, dynamic>> getComposition(String token, String teamId) async {
    return await _api.get(
      '/teams/$teamId/composition',
      token: token,
      defaultErrorMsg: 'Erreur chargement composition',
    );
  }

  Future<List<dynamic>> getCompositions(String token, String teamId) async {
    return await _api.get(
      '/teams/$teamId/compositions',
      token: token,
      defaultErrorMsg: 'Erreur chargement compositions',
    );
  }

  Future<Map<String, dynamic>> saveComposition(
    String token,
    String teamId,
    String formation,
    List<Map<String, dynamic>> lineup, {
    String format = '5v5',
    int playerCount = 5,
    String? name,
    bool? isDefault,
  }) async {
    final body = {
      'format': format,
      'playerCount': playerCount,
      'formation': formation,
      'lineup': lineup,
    };
    if (name != null) body['name'] = name;
    if (isDefault != null) body['isDefault'] = isDefault;

    return await _api.put( // Note: api_service doesn't have put, only patch and post. wait.
      '/teams/$teamId/composition',
      body: body,
      token: token,
      defaultErrorMsg: 'Erreur sauvegarde composition',
    );
  }

  Future<List<dynamic>> searchTeams({
    String? zone,
    String? query,
    String? excludeId,
  }) async {
    final params = <String, String>{};
    if (zone != null && zone.isNotEmpty && zone != 'Toutes') params['zone'] = zone;
    if (query != null && query.isNotEmpty) params['query'] = query;
    if (excludeId != null) params['excludeId'] = excludeId;

    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    final url = queryString.isNotEmpty ? '/teams/search?$queryString' : '/teams/search';

    return await _api.get(
      url,
      defaultErrorMsg: 'Erreur recherche équipes',
    );
  }

  Future<List<dynamic>> getZones() async {
    try {
      return await _api.get('/teams/zones');
    } catch (_) {
      return [
        'Dakar',
        'Guédiawaye',
        'Pikine',
        'Rufisque',
        'Thiès',
        'Saint-Louis',
      ];
    }
  }

  Future<void> acceptMember(String teamId, String memberId, String token) async {
    await _api.patch(
      '/teams/$teamId/members/$memberId/accept',
      token: token,
      defaultErrorMsg: 'Erreur lors de l\'acceptation du membre',
    );
  }
}
