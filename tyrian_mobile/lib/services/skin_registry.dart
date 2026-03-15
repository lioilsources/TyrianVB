/// Defines available skins and their asset paths.
class SkinInfo {
  final String id;
  final String name;
  const SkinInfo(this.id, this.name);

  String get previewPath => 'skins/$id/ui/preview.png';
  String spritePath(String name) => 'skins/$id/sprites/$name.png';
}

const kSkins = [
  SkinInfo('default', 'Tyrian Classic'),
  SkinInfo('space_invaders', 'Space Invader'),
  SkinInfo('galaga', 'Galaga Ace'),
  SkinInfo('asteroids', 'Vector Pilot'),
  SkinInfo('geometry_wars', 'Neon Destroyer'),
  SkinInfo('ikaruga', 'Polarity'),
  SkinInfo('nuclear_throne', 'Wasteland Mutant'),
  SkinInfo('luftrausers', 'Rauser Ace'),
  SkinInfo('nex_machina', 'Voxel Storm'),
  SkinInfo('tyrian_dos', 'DOS Reforged'),
  SkinInfo('gradius_v', 'Vic Viper'),
  SkinInfo('rtype', 'Bydo Slayer'),
  SkinInfo('blazing_lazers', 'Gunhed'),
];
