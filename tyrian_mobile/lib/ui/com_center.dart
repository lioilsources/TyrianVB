import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../game/tyrian_game.dart';
import '../game/platform_config.dart' as platform;
import '../systems/dev_type.dart';
import '../systems/device.dart';
import '../entities/vessel.dart';
import '../rendering/health_bar.dart';
import '../input/gamepad_input.dart';
import '../services/save_service.dart';
import 'high_scores.dart';

/// Ported from ComCenter.cls — the shop/equipment screen.
/// Aligned with original VBA layout: ship stats + scores left, weapon cards right.
class ComCenterScreen extends StatefulWidget {
  final TyrianGame game;
  final VoidCallback onStart;
  final VoidCallback? onJoinIp;

  const ComCenterScreen({
    super.key,
    required this.game,
    required this.onStart,
    this.onJoinIp,
  });

  @override
  State<ComCenterScreen> createState() => _ComCenterScreenState();
}

class _ComCenterScreenState extends State<ComCenterScreen>
    with SingleTickerProviderStateMixin {
  TyrianGame get game => widget.game;
  Vessel get vessel => game.vessel;

  // Weapon selection
  int _selectedWeaponIndex = 0;
  bool _showingSide = false; // false = front, true = side section focused

  // High scores
  List<HighScoreEntry> _highScores = [];

  // Animated background
  late AnimationController _bgAnim;
  int _bgPhase = 0;

  // Gamepad polling
  final GamepadInput _gamepad = GamepadInput();
  Timer? _pollTimer;
  bool _prevUp = false, _prevDown = false;
  bool _prevLeft = false, _prevRight = false;
  bool _prevConfirm = false, _prevStart = false, _prevBack = false;
  bool _prevSell = false;
  final FocusNode _focusNode = FocusNode();

  List<DevType> get _frontWeapons {
    final maxIdx = vessel.nextWeaponLevel.clamp(0, DevType.frontWeapons.length - 1);
    return DevType.frontWeapons.sublist(0, maxIdx + 1);
  }

  List<DevType> get _sideWeapons {
    final maxIdx = vessel.nextWeaponLevel.clamp(0, DevType.sideWeapons.length - 1);
    return DevType.sideWeapons.sublist(0, maxIdx + 1);
  }

  List<DevType> get _currentWeapons => _showingSide ? _sideWeapons : _frontWeapons;

  @override
  void initState() {
    super.initState();
    _loadScores();
    _bgAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // 12 phases × ~67ms
    )..repeat();
    _bgAnim.addListener(() {
      final newPhase = (_bgAnim.value * 12).floor() % 12;
      if (newPhase != _bgPhase) {
        setState(() => _bgPhase = newPhase);
      }
    });
    if (platform.isDesktop) {
      _pollTimer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => _pollGamepad(),
      );
    }
  }

  Future<void> _loadScores() async {
    final scores = await SaveService.loadHighScores();
    if (mounted) setState(() => _highScores = scores);
  }

  @override
  void dispose() {
    _bgAnim.dispose();
    _pollTimer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Gamepad ──

  void _pollGamepad() async {
    await _gamepad.poll();
    if (!mounted) return;
    final gp = _gamepad.primary;

    final up = gp.dpadUp || GamepadInput.deadzone(gp.leftStickY) < -0.5;
    final down = gp.dpadDown || GamepadInput.deadzone(gp.leftStickY) > 0.5;
    final left = gp.dpadLeft || GamepadInput.deadzone(gp.leftStickX) < -0.5;
    final right = gp.dpadRight || GamepadInput.deadzone(gp.leftStickX) > 0.5;
    final confirm = gp.buttonA || gp.buttonX;
    final start = gp.start;
    final back = gp.buttonB;
    final sell = gp.buttonY;

    if (up && !_prevUp) _moveWeapon(-1);
    if (down && !_prevDown) _moveWeapon(1);
    if (left && !_prevLeft) _switchSection(false);
    if (right && !_prevRight) _switchSection(true);
    if (confirm && !_prevConfirm) _confirmAction();
    if (sell && !_prevSell) _sellAction();
    if ((start && !_prevStart) || (back && !_prevBack)) widget.onStart();

    _prevUp = up; _prevDown = down;
    _prevLeft = left; _prevRight = right;
    _prevConfirm = confirm; _prevStart = start;
    _prevBack = back; _prevSell = sell;
  }

  void _moveWeapon(int delta) {
    final weapons = _currentWeapons;
    if (weapons.isEmpty) return;
    setState(() {
      _selectedWeaponIndex = (_selectedWeaponIndex + delta).clamp(0, weapons.length - 1);
    });
  }

  void _switchSection(bool toSide) {
    if (toSide != _showingSide) {
      setState(() {
        _showingSide = toSide;
        _selectedWeaponIndex = 0;
      });
    }
  }

  void _confirmAction() {
    if (_currentWeapons.isEmpty) return;
    final weapon = _currentWeapons[_selectedWeaponIndex];
    final owned = vessel.devices.any((d) => d.name == weapon.name);
    if (owned) {
      _upgradeWeapon(weapon);
    } else {
      _buyWeapon(weapon);
    }
  }

  void _sellAction() {
    if (_currentWeapons.isEmpty) return;
    final weapon = _currentWeapons[_selectedWeaponIndex];
    final owned = vessel.devices.any((d) => d.name == weapon.name);
    if (owned) _sellWeapon(weapon);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyW) {
      _moveWeapon(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.keyS) {
      _moveWeapon(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _switchSection(false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.keyD) {
      _switchSection(true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      _confirmAction();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      widget.onStart();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete || key == LogicalKeyboardKey.backspace) {
      _sellAction();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Buy / Upgrade / Sell ──

  void _buyWeapon(DevType weapon) {
    if (vessel.credit < weapon.price) return;

    WeaponSlot slot;
    if (!_showingSide) {
      slot = WeaponSlot.frontGun;
    } else {
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

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Stack(
        children: [
          // Animated gradient background
          _AnimatedBackground(phase: _bgPhase),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel: ship stats + scores
                      SizedBox(
                        width: 300,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildShipPreview(),
                              const SizedBox(height: 10),
                              _buildPilotName(),
                              const SizedBox(height: 10),
                              _buildStatValues(),
                              const SizedBox(height: 10),
                              _buildSlotList(),
                              const SizedBox(height: 6),
                              _buildGenInfo(),
                              const SizedBox(height: 16),
                              _buildScoreTable(),
                            ],
                          ),
                        ),
                      ),
                      Container(width: 1, color: Colors.white12),
                      // Right panel: weapon cards
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWeaponSection('FRONT WEAPONS', _frontWeapons, false),
                              const SizedBox(height: 16),
                              _buildWeaponSection('SIDE WEAPONS', _sideWeapons, true),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.cyanAccent.withAlpha(60))),
      ),
      child: Row(
        children: [
          const Text(
            'COMMAND CENTER',
            style: TextStyle(
              color: Colors.cyanAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const Spacer(),
          Text(
            'Credits: ${vessel.credit}',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (game.isCoop && game.vessel2 != null) ...[
            const SizedBox(width: 12),
            Text(
              'P2: ${game.vessel2!.pilotName}',
              style: const TextStyle(color: Color(0xFF00FF80), fontSize: 12),
            ),
          ],
          if (game.coopRole == CoopRole.host && game.hostIp != null) ...[
            const SizedBox(width: 12),
            Text(
              'IP: ${game.hostIp}',
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShipPreview() {
    return Center(
      child: Container(
        width: 120,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.cyanAccent.withAlpha(40)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.black26,
        ),
        child: Center(
          child: Text(
            'Lv ${game.currentSectorIndex + 1}',
            style: const TextStyle(
              color: Colors.cyanAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPilotName() {
    return TextField(
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
    );
  }

  Widget _buildStatValues() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _statChip('HP', '${vessel.hp}/${vessel.hpMax}', Colors.redAccent),
            const SizedBox(width: 8),
            _statChip('SH', '${vessel.shield.toInt()}/${vessel.shieldMax.toInt()}', Colors.cyanAccent),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            _statChip('GEN', '${vessel.genValue.toInt()}/${vessel.genMax.toInt()}', Colors.yellowAccent),
            const SizedBox(width: 8),
            _statChip('DPS', vessel.totalDps.toStringAsFixed(1), Colors.orangeAccent),
          ],
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Text('$label ', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildSlotList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlotRow('Front', WeaponSlot.frontGun),
        _buildSlotRow('Left', WeaponSlot.leftGun),
        _buildSlotRow('Right', WeaponSlot.rightGun),
        _buildSlotRow('Gen', WeaponSlot.generator),
      ],
    );
  }

  Widget _buildSlotRow(String label, WeaponSlot slot) {
    final device = vessel.devices.cast<Device?>().firstWhere(
      (d) => d?.slot == slot,
      orElse: () => null,
    );
    final name = device != null ? '${device.name} Lv.${device.level}' : '---';
    final color = device != null ? Colors.greenAccent : Colors.white24;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ),
          Expanded(
            child: Text(name, style: TextStyle(color: color, fontSize: 10)),
          ),
          if (device != null && slot != WeaponSlot.generator) ...[
            GestureDetector(
              onTap: () => _upgradeWeapon(DevType.frontWeapons.firstWhere(
                (w) => w.name == device.name,
                orElse: () => DevType.sideWeapons.firstWhere(
                  (w) => w.name == device.name,
                  orElse: () => DevType.generatorBasic,
                ),
              )),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  device.level >= Device.maxLevel ? 'MAX' : 'UPG',
                  style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 8),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                final wType = DevType.frontWeapons.cast<DevType?>().firstWhere(
                  (w) => w?.name == device.name,
                  orElse: () => DevType.sideWeapons.cast<DevType?>().firstWhere(
                    (w) => w?.name == device.name,
                    orElse: () => null,
                  ),
                );
                if (wType != null) _sellWeapon(wType);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'SELL',
                  style: TextStyle(color: Colors.redAccent, fontSize: 8),
                ),
              ),
            ),
          ],
          if (device != null && slot == WeaponSlot.generator)
            GestureDetector(
              onTap: () => _upgradeWeapon(DevType.generatorBasic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(40),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  device.level >= Device.maxLevel ? 'MAX' : 'UPG',
                  style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenInfo() {
    return Text(
      vessel.genInfo,
      style: TextStyle(
        color: vessel.generatorLoad > 100 ? Colors.redAccent : Colors.yellowAccent,
        fontSize: 10,
      ),
    );
  }

  Widget _buildScoreTable() {
    if (_highScores.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'TOP SCORES',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        for (int i = 0; i < _highScores.length && i < 10; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text(
                    '${i + 1}.',
                    style: TextStyle(
                      color: i < 3 ? Colors.cyanAccent : Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    _highScores[i].name,
                    style: TextStyle(
                      color: i < 3 ? Colors.cyanAccent : Colors.white54,
                      fontSize: 9,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Lv${_highScores[i].level}',
                  style: const TextStyle(color: Colors.white38, fontSize: 9),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_highScores[i].score}',
                  style: TextStyle(
                    color: i < 3 ? Colors.yellowAccent : Colors.white54,
                    fontSize: 9,
                    fontWeight: i < 3 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Weapon section (front or side) ──

  Widget _buildWeaponSection(String title, List<DevType> weapons, bool isSide) {
    final isFocused = _showingSide == isSide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: isFocused ? Colors.cyanAccent : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < weapons.length; i++)
              _buildWeaponCard(weapons[i], i, isSide),
          ],
        ),
      ],
    );
  }

  Widget _buildWeaponCard(DevType weapon, int index, bool isSide) {
    final isSelected = _showingSide == isSide && _selectedWeaponIndex == index;
    final owned = vessel.devices.any((d) => d.name == weapon.name);
    final canAfford = vessel.credit >= weapon.price;
    final device = owned
        ? vessel.devices.firstWhere((d) => d.name == weapon.name)
        : null;

    Color borderColor;
    if (isSelected) {
      borderColor = Colors.cyanAccent;
    } else if (owned) {
      borderColor = Colors.greenAccent.withAlpha(120);
    } else {
      borderColor = Colors.white12;
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showingSide = isSide;
          _selectedWeaponIndex = index;
        });
      },
      onDoubleTap: () {
        setState(() {
          _showingSide = isSide;
          _selectedWeaponIndex = index;
        });
        _confirmAction();
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1a1a4e) : const Color(0xFF0a0a1e),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + level
            Text(
              owned ? '${weapon.name} ${_romanLevel(device!.level)}' : weapon.name,
              style: TextStyle(
                color: owned ? Colors.greenAccent : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Stats
            Text(
              'DMG:${weapon.damage} SPD:${weapon.speed}',
              style: const TextStyle(color: Colors.white54, fontSize: 9),
            ),
            Text(
              'PWR:${weapon.pwrNeed.toInt()}${weapon.beam > 0 ? " BEAM" : ""}',
              style: TextStyle(
                color: weapon.beam > 0 ? Colors.purpleAccent : Colors.white38,
                fontSize: 9,
              ),
            ),
            const SizedBox(height: 4),
            // Price / action
            if (owned)
              Row(
                children: [
                  const Text('OWNED', style: TextStyle(color: Colors.greenAccent, fontSize: 9)),
                  const Spacer(),
                  if (device!.level < Device.maxLevel)
                    Text(
                      '${device.price}cr',
                      style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 8),
                    ),
                ],
              )
            else
              Text(
                '${weapon.price} cr',
                style: TextStyle(
                  color: canAfford ? Colors.yellowAccent : Colors.red.withAlpha(150),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 4),
            // Action button
            if (isSelected) _buildCardAction(weapon, owned, canAfford, device),
          ],
        ),
      ),
    );
  }

  Widget _buildCardAction(DevType weapon, bool owned, bool canAfford, Device? device) {
    if (owned) {
      final atMax = device!.level >= Device.maxLevel;
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: atMax ? null : () => _upgradeWeapon(weapon),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: atMax ? Colors.white10 : Colors.blue.withAlpha(60),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  atMax ? 'MAX' : 'UPGRADE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: atMax ? Colors.white24 : Colors.lightBlueAccent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => _sellWeapon(weapon),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(40),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Text(
                'SELL',
                style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: canAfford ? () => _buyWeapon(weapon) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: canAfford ? Colors.green.withAlpha(60) : Colors.white10,
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            canAfford ? 'BUY' : 'NO CREDITS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: canAfford ? Colors.greenAccent : Colors.white24,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  String _romanLevel(int level) {
    const numerals = ['', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
      'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX',
      'XXI', 'XXII', 'XXIII', 'XXIV', 'XXV'];
    return level >= 0 && level < numerals.length ? numerals[level] : '$level';
  }

  Widget _buildBottomBar() {
    final label = game.currentSectorIndex == 0 ? 'START MISSION' : 'CONTINUE MISSION';
    final showJoin = widget.onJoinIp != null &&
        game.coopRole != CoopRole.client &&
        game.vessel2 == null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.cyanAccent.withAlpha(60))),
      ),
      child: Row(
        children: [
          if (showJoin) ...[
            GestureDetector(
              onTap: widget.onJoinIp,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.orangeAccent.withAlpha(150)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'JOIN',
                  style: TextStyle(
                    color: Colors.orangeAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: widget.onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated background (VBA ComCenter.PaintBack — 12-phase gradient cycle) ──

class _AnimatedBackground extends StatelessWidget {
  final int phase;
  const _AnimatedBackground({required this.phase});

  @override
  Widget build(BuildContext context) {
    // Cycle through teal→indigo→purple gradients
    final t = phase / 12.0;
    final hue = 200 + (t * 60); // 200-260 range (teal to indigo)
    final c1 = HSLColor.fromAHSL(1, hue % 360, 0.6, 0.08).toColor();
    final c2 = HSLColor.fromAHSL(1, (hue + 30) % 360, 0.5, 0.03).toColor();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1, c2],
        ),
      ),
      child: CustomPaint(
        painter: _GridPainter(phase: phase),
        size: Size.infinite,
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int phase;
  _GridPainter({required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8 + (phase % 3) * 2)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.phase != phase;
}
