import '../rendering/shader_config.dart';

/// Defines available skins and their asset paths.
class SkinInfo {
  final String id;
  final String name;
  const SkinInfo(this.id, this.name);

  String get previewPath => 'skins/$id/ui/preview.png';
  String spritePath(String name) => 'skins/$id/sprites/$name.png';

  ShaderConfig get shaderConfig =>
      ShaderConfig.defaults[id] ?? const ShaderConfig();
}

const kSkins = [
  SkinInfo('space_invaders', 'Space Invaders (1978)'),
  SkinInfo('asteroids', 'Asteroids (1979)'),
  SkinInfo('galaga', 'Galaga (1981)'),
  SkinInfo('rtype', 'R-Type (1987)'),
  SkinInfo('blazing_lazers', 'Blazing Lazers (1989)'),
  SkinInfo('tyrian_dos', 'Tyrian DOS (1995)'),
  SkinInfo('ikaruga', 'Ikaruga (2001)'),
  SkinInfo('geometry_wars', 'Geometry Wars (2003)'),
  SkinInfo('gradius_v', 'Gradius V (2004)'),
  SkinInfo('luftrausers', 'Luftrausers (2014)'),
  SkinInfo('nuclear_throne', 'Nuclear Throne (2015)'),
  SkinInfo('nex_machina', 'Nex Machina (2017)'),
  SkinInfo('default', 'Kiran (2026)'),
];
