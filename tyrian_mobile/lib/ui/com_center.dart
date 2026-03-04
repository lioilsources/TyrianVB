import 'package:flutter/material.dart';
import '../game/tyrian_game.dart';
import '../systems/dev_type.dart';
import '../systems/device.dart';
import '../entities/vessel.dart';
import '../rendering/health_bar.dart';

/// Ported from ComCenter.cls — the shop/equipment screen.
/// Implemented as a Flutter Material screen (not Flame).
class ComCenterScreen extends StatefulWidget {
  final TyrianGame game;
  final VoidCallback onStart;

  const ComCenterScreen({
    super.key,
    required this.game,
    required this.onStart,
  });

  @override
  State<ComCenterScreen> createState() => _ComCenterScreenState();
}

class _ComCenterScreenState extends State<ComCenterScreen> {
  int _selectedCategory = 0; // 0 = Front, 1 = Side
  int _selectedWeaponIndex = 0;

  TyrianGame get game => widget.game;
  Vessel get vessel => game.vessel;

  /// Weapons filtered by score-based unlock tier (VB6 WepLevScores)
  /// Index maps to tier: 0=starter, 1=400k, 2=4M, 3=14M
  List<DevType> get currentWeapons {
    final all = _selectedCategory == 0 ? DevType.frontWeapons : DevType.sideWeapons;
    final maxIndex = vessel.nextWeaponLevel.clamp(0, all.length - 1);
    return all.sublist(0, maxIndex + 1);
  }

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
            _buildHeader(),
            Expanded(
              child: Column(
                children: [
                  // Top: Ship stats (compact)
                  _buildShipStats(),
                  const Divider(color: Colors.white24, height: 1),
                  // Bottom: Weapon shop
                  Expanded(child: _buildWeaponShop()),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'COMMAND CENTER',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          Text(
            'Credits: ${vessel.credit}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShipStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pilot name + stats row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: TextEditingController(text: vessel.pilotName),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'Pilot',
                    labelStyle: TextStyle(color: Colors.white54, fontSize: 12),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.cyanAccent),
                    ),
                  ),
                  onChanged: (v) => vessel.pilotName = v,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'DPS: ${vessel.totalDps.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
              ),
              const SizedBox(width: 12),
              Text(
                'Lv: ${game.currentSectorIndex + 1}',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Health bars in a row
          Row(
            children: [
              Expanded(
                child: HealthBar(
                  label: 'HP',
                  value: vessel.hp.toDouble(),
                  maxValue: vessel.hpMax.toDouble(),
                  color: Colors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HealthBar(
                  label: 'SH',
                  value: vessel.shield,
                  maxValue: vessel.shieldMax,
                  color: Colors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HealthBar(
                  label: 'GEN',
                  value: vessel.genValue,
                  maxValue: vessel.genMax,
                  color: Colors.yellow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Equipped weapons in a compact row
          Wrap(
            spacing: 12,
            children: [
              for (final d in vessel.devices)
                Text(
                  '${d.slot.name}: ${d.name} Lv.${d.level}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                ),
            ],
          ),
          const SizedBox(height: 4),
          // Generator load info (VB6 Vessel.GenInfo)
          Text(
            vessel.genInfo,
            style: TextStyle(
              color: vessel.generatorLoad > 100 ? Colors.redAccent : Colors.yellowAccent,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeaponShop() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Category tabs
          Row(
            children: [
              _buildTab('Front Weapons', 0),
              const SizedBox(width: 8),
              _buildTab('Side Weapons', 1),
            ],
          ),
          const SizedBox(height: 12),

          // Weapon list
          Expanded(
            child: ListView.builder(
              itemCount: currentWeapons.length,
              itemBuilder: (ctx, i) {
                final w = currentWeapons[i];
                final isSelected = i == _selectedWeaponIndex;
                final owned = vessel.devices.any((d) => d.name == w.name);

                return GestureDetector(
                  onTap: () => setState(() => _selectedWeaponIndex = i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF1a1a4e) : const Color(0xFF0a0a2e),
                      border: Border.all(
                        color: isSelected
                            ? Colors.cyanAccent
                            : owned
                                ? Colors.greenAccent.withAlpha(100)
                                : Colors.white24,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              w.name,
                              style: TextStyle(
                                color: owned ? Colors.greenAccent : Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (owned)
                              const Text('OWNED', style: TextStyle(color: Colors.greenAccent, fontSize: 10))
                            else
                              Text(
                                '${w.price} cr',
                                style: const TextStyle(color: Colors.yellowAccent, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DMG: ${w.damage}  SPD: ${w.speed}  PWR: ${w.pwrNeed}  ${w.beam > 0 ? "BEAM" : ""}',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Action buttons
          if (currentWeapons.isNotEmpty) _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _selectedCategory == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = index;
        _selectedWeaponIndex = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.cyanAccent.withAlpha(40) : Colors.transparent,
          border: Border.all(
            color: isActive ? Colors.cyanAccent : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.cyanAccent : Colors.white54,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final weapon = currentWeapons[_selectedWeaponIndex];
    final owned = vessel.devices.any((d) => d.name == weapon.name);
    final canAfford = vessel.credit >= weapon.price;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          if (!owned)
            Expanded(
              child: ElevatedButton(
                onPressed: canAfford ? () => _buyWeapon(weapon) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade800,
                  foregroundColor: Colors.white,
                ),
                child: Text('BUY (${weapon.price})'),
              ),
            ),
          if (owned) ...[
            Expanded(
              child: Builder(builder: (context) {
                final device = vessel.devices.firstWhere((d) => d.name == weapon.name);
                final atMax = device.level >= Device.maxLevel;
                return ElevatedButton(
                  onPressed: atMax ? null : () => _upgradeWeapon(weapon),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(atMax ? 'MAX LV' : 'UPGRADE'),
                );
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _sellWeapon(weapon),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade800,
                  foregroundColor: Colors.white,
                ),
                child: const Text('SELL'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _buyWeapon(DevType weapon) {
    if (vessel.credit < weapon.price) return;

    // Determine slot
    WeaponSlot slot;
    if (_selectedCategory == 0) {
      slot = WeaponSlot.frontGun;
    } else {
      // Check which side slot is free
      final hasLeft = vessel.devices.any((d) => d.slot == WeaponSlot.leftGun);
      slot = hasLeft ? WeaponSlot.rightGun : WeaponSlot.leftGun;
    }

    vessel.credit -= weapon.price;
    vessel.equipWeapon(weapon, slot);
    setState(() {});
  }

  void _upgradeWeapon(DevType weapon) {
    final device = vessel.devices.firstWhere((d) => d.name == weapon.name);
    final cost = device.price;
    if (vessel.credit < cost) return;

    vessel.credit -= cost;
    device.upgrade();
    setState(() {});
  }

  void _sellWeapon(DevType weapon) {
    final device = vessel.devices.firstWhere((d) => d.name == weapon.name);
    vessel.credit += device.price;
    vessel.removeWeapon(device.slot);
    setState(() {});
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: widget.onStart,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(
            game.currentSectorIndex == 0 ? 'START MISSION' : 'CONTINUE MISSION',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
