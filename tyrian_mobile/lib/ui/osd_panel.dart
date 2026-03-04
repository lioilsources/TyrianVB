import 'package:flutter/material.dart';
import '../game/tyrian_game.dart';
import '../rendering/health_bar.dart';

/// Ported from OSD panel rendering — HUD overlay showing ship stats.
/// Implemented as a Flutter overlay widget (not Flame).
class OsdPanel extends StatelessWidget {
  final TyrianGame game;

  const OsdPanel({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    final vessel = game.vessel;
    final sector = game.currentSector;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withAlpha(0),
                Colors.black.withAlpha(180),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sector name + Level
              if (sector != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    sector.caption,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ),

              // Stats bars
              Row(
                children: [
                  // HP
                  Expanded(
                    child: HealthBar(
                      label: 'HP',
                      value: vessel.hp.toDouble(),
                      maxValue: vessel.hpMax.toDouble(),
                      color: Colors.red,
                      height: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Shield
                  Expanded(
                    child: HealthBar(
                      label: 'Shield',
                      value: vessel.shield,
                      maxValue: vessel.shieldMax,
                      color: Colors.cyan,
                      height: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Generator
                  Expanded(
                    child: HealthBar(
                      label: 'Power',
                      value: vessel.genValue,
                      maxValue: vessel.genMax,
                      color: Colors.yellow,
                      height: 10,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Bottom row: Credit + Score + Pause
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Credits: ${vessel.credit}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Score: ${vessel.score}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => game.togglePause(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        game.state == GameState.paused ? 'RESUME' : 'PAUSE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
