import 'package:flutter/material.dart';
import '../game/tyrian_game.dart';
import '../entities/vessel.dart';
import '../rendering/health_bar.dart';

/// Ported from OSD panel rendering — HUD overlay showing ship stats.
/// Implemented as a Flutter overlay widget (not Flame).
class OsdPanel extends StatelessWidget {
  final TyrianGame game;

  const OsdPanel({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
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

              // P1 stats
              _buildVesselStats(game.vessel, 'P1'),

              // P2 stats (co-op only)
              if (game.isCoop) ...[
                const SizedBox(height: 4),
                _buildVesselStats(game.vessel2!, 'P2'),
              ],

              const SizedBox(height: 4),

              // Bottom row: Credits + Pause button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    game.isCoop
                        ? 'P1: ${game.vessel.credit}cr  P2: ${game.vessel2!.credit}cr'
                        : 'Credits: ${game.vessel.credit}',
                    style: const TextStyle(
                      color: Colors.greenAccent,
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

  Widget _buildVesselStats(Vessel vessel, String label) {
    final dead = !vessel.visible || vessel.hp <= 0;
    return Row(
      children: [
        if (game.isCoop)
          SizedBox(
            width: 22,
            child: Text(
              label,
              style: TextStyle(
                color: dead ? Colors.red : (label == 'P2' ? const Color(0xFF00FF80) : Colors.cyanAccent),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        Expanded(
          child: HealthBar(
            label: 'SH',
            value: vessel.shield,
            maxValue: vessel.shieldMax,
            color: Colors.cyan,
            height: 10,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HealthBar(
            label: 'PWR',
            value: vessel.genValue,
            maxValue: vessel.genMax,
            color: Colors.yellow,
            height: 10,
          ),
        ),
      ],
    );
  }
}
