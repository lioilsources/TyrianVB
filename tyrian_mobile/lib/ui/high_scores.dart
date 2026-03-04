import 'package:flutter/material.dart';

/// Ported from Record.cls — high score table (top 10).
class HighScoreEntry {
  final String name;
  final int score;
  final int level;

  const HighScoreEntry({
    required this.name,
    required this.score,
    required this.level,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'score': score,
        'level': level,
      };

  factory HighScoreEntry.fromJson(Map<String, dynamic> json) {
    return HighScoreEntry(
      name: json['name'] as String? ?? 'Unknown',
      score: json['score'] as int? ?? 0,
      level: json['level'] as int? ?? 0,
    );
  }
}

class HighScoresScreen extends StatelessWidget {
  final List<HighScoreEntry> scores;
  final VoidCallback onClose;

  const HighScoresScreen({
    super.key,
    required this.scores,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a0a2e), Color(0xFF000010)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'HIGH SCORES',
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: scores.length,
                itemBuilder: (ctx, i) {
                  final entry = scores[i];
                  final isTop3 = i < 3;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isTop3
                          ? Colors.cyanAccent.withAlpha(20)
                          : Colors.white.withAlpha(5),
                      border: Border.all(
                        color: isTop3 ? Colors.cyanAccent.withAlpha(60) : Colors.white12,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '#${i + 1}',
                            style: TextStyle(
                              color: isTop3 ? Colors.cyanAccent : Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.name,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                        Text(
                          'Lv.${entry.level}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '${entry.score}',
                          style: TextStyle(
                            color: isTop3 ? Colors.yellowAccent : Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
