import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/asset_library.dart';
import '../services/sound_service.dart';
import '../services/skin_registry.dart';

/// Full-screen skin selection overlay (dark gradient, cyan accents).
class SkinSelector extends StatefulWidget {
  final VoidCallback onPlay;

  const SkinSelector({super.key, required this.onPlay});

  @override
  State<SkinSelector> createState() => _SkinSelectorState();
}

class _SkinSelectorState extends State<SkinSelector> {
  String _selectedId = 'default';
  Map<String, ui.Image> _previews = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('selected_skin') ?? 'default';
    final previews = await AssetLibrary.instance.loadPreviews();
    if (mounted) {
      setState(() {
        _selectedId = saved;
        _previews = previews;
        _loading = false;
      });
    }
  }

  Future<void> _selectAndPlay(String id) async {
    if (_loading) return;
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_skin', id);
    _selectedId = id;
    await AssetLibrary.instance.loadSkin(id);
    await SoundService.instance.loadSkin(id);
    widget.onPlay();
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
            const SizedBox(height: 24),
            const Text(
              'SELECT SKIN',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: GridView.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.85,
                        children: kSkins.map(_buildSkinCard).toList(),
                      ),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSkinCard(SkinInfo skin) {
    final selected = skin.id == _selectedId;
    final preview = _previews[skin.id];

    return GestureDetector(
      onTap: () => _selectAndPlay(skin.id),
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF1a1a4e) : const Color(0xFF0d0d20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.cyanAccent : Colors.white24,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(9)),
                child: preview != null
                    ? RawImage(
                        image: preview,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                    : Container(
                        color: Colors.black26,
                        child: const Center(
                          child: Icon(Icons.image_not_supported,
                              color: Colors.white24, size: 40),
                        ),
                      ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: selected ? Colors.cyanAccent.withAlpha(80) : Colors.white10,
                  ),
                ),
              ),
              child: Text(
                skin.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? Colors.cyanAccent : Colors.white70,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
