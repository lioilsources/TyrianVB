import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/high_scores.dart';

/// Ported from state file persistence — saves game state and high scores.
/// Uses shared_preferences for mobile storage (replaces VBA "state.d" file).
class SaveService {
  static const _keyHighScores = 'high_scores';
  static const _keyGameState = 'game_state';
  static const _maxScores = 10;

  /// Load high scores
  static Future<List<HighScoreEntry>> loadHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyHighScores);
    if (jsonStr == null) return [];

    final List<dynamic> list = jsonDecode(jsonStr);
    return list.map((e) => HighScoreEntry.fromJson(e)).toList();
  }

  /// Save a new high score. Returns true if it made the top 10.
  static Future<bool> saveHighScore(HighScoreEntry entry) async {
    final scores = await loadHighScores();
    scores.add(entry);
    scores.sort((a, b) => b.score.compareTo(a.score));

    if (scores.length > _maxScores) {
      scores.removeRange(_maxScores, scores.length);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyHighScores,
      jsonEncode(scores.map((e) => e.toJson()).toList()),
    );

    return scores.contains(entry);
  }

  /// Save game state (vessel stats, credit, level)
  static Future<void> saveGameState({
    required String pilotName,
    required int credit,
    required int score,
    required int hp,
    required int hpMax,
    required double shield,
    required double shieldMax,
    required double genMax,
    required double genPower,
    required int level,
    required List<Map<String, dynamic>> weapons,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final state = {
      'pilotName': pilotName,
      'credit': credit,
      'score': score,
      'hp': hp,
      'hpMax': hpMax,
      'shield': shield,
      'shieldMax': shieldMax,
      'genMax': genMax,
      'genPower': genPower,
      'level': level,
      'weapons': weapons,
    };
    await prefs.setString(_keyGameState, jsonEncode(state));
  }

  /// Load game state. Returns null if no saved state.
  static Future<Map<String, dynamic>?> loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyGameState);
    if (jsonStr == null) return null;
    return jsonDecode(jsonStr) as Map<String, dynamic>;
  }

  /// Clear saved game state
  static Future<void> clearGameState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyGameState);
  }
}
