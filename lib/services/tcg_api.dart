import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import '../models/pokemon_card.dart';

// Inline key so we don't need secrets.dart
const String kPokemonTcgApiKey = '53a7767d-38aa-4077-bd41-1ac373d9a915';

class TcgApi {
  // Call the API directly (no isomorphic proxy)
  static const String _apiBase = 'https://api.pokemontcg.io/v2/cards';

  static Uri _buildUri({int pageSize = 150}) {
    // NOTE: no CORS wrapper now; we'll run Chrome with CORS disabled
    final base = _apiBase;
    return Uri.parse(base).replace(queryParameters: {
      'q': 'types:grass supertype:pokemon',
      'orderBy': 'name',
      'pageSize': '$pageSize',
    });
  }

  static Future<List<PokemonCard>> fetchGrassCards({int pageSize = 150}) async {
    final uri = _buildUri(pageSize: pageSize);

    final resp = await http.get(uri, headers: {
      'Accept': 'application/json',
      'X-Api-Key': kPokemonTcgApiKey,
    });

    if (resp.statusCode != 200) {
      throw Exception('API error ${resp.statusCode}: ${resp.body}');
    }

    final decoded = json.decode(resp.body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>? ?? [];

    return data
        .map((e) => PokemonCard.fromJson(e as Map<String, dynamic>))
        .where((c) => c.imageUrl.isNotEmpty)
        .toList();
  }
}
