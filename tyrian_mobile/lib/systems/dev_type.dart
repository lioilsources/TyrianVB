// Weapon definition — ported from DevType.cls and ComCenter.GetDevType.
// Contains base stats for all weapon types.

enum WeaponSlot {
  frontGun,  // 1
  generator, // 2
  leftGun,   // 3
  notAvailable, // 4
  rightGun,  // 5
  satellite, // 6
  shieldCapacitor, // 7
}

class DevType {
  final String name;
  final String imgName;
  final int damage;
  final int speed;
  final int guide;
  final double pwrNeed;
  final double pwrGen;
  final int cooldown; // in frames (convert to seconds: * 25 / 1000)
  final int beam; // 0 = projectile, >0 = beam weapon
  final int seqs; // beam animation steps
  final int xShiftMax;
  final int price;
  final double upgCost;
  final bool scaleProjectile;
  final double minProjScale;
  final double maxProjScale;

  const DevType({
    required this.name,
    required this.imgName,
    this.damage = 10,
    this.speed = 5,
    this.guide = 0,
    this.pwrNeed = 1.0,
    this.pwrGen = 0.0,
    this.cooldown = 10,
    this.beam = 0,
    this.seqs = 0,
    this.xShiftMax = 0,
    this.price = 100,
    this.upgCost = 0.1,
    this.scaleProjectile = false,
    this.minProjScale = 1.0,
    this.maxProjScale = 1.0,
  });

  double get cooldownSeconds => cooldown * 25.0 / 1000.0;

  /// All front weapons
  static const List<DevType> frontWeapons = [
    bubbleGun,
    vulcanCannon,
    blaster,
    laser,
  ];

  /// All side weapons
  static const List<DevType> sideWeapons = [
    smallBubble,
    smallVulcan,
    starGun,
    smallLaser,
  ];

  // ---- Front Weapons (VB6 ComCenter.GetDevType values) ----

  static const bubbleGun = DevType(
    name: 'Bubble Gun',
    imgName: 'bubble',
    damage: 21,
    speed: 15,
    guide: 0,
    pwrNeed: 12,
    cooldown: 9,
    price: 2000,
    upgCost: 0.25,
    scaleProjectile: true,
    minProjScale: 0.5,
    maxProjScale: 0.85,
  );

  static const vulcanCannon = DevType(
    name: 'Vulcan Cannon',
    imgName: 'vulcan',
    damage: 24,
    speed: 30,
    guide: 0,
    pwrNeed: 16,
    cooldown: 3,
    price: 16000,
    upgCost: 0.30,
    xShiftMax: 14,
  );

  static const blaster = DevType(
    name: 'Blaster',
    imgName: 'blaster',
    damage: 250,
    speed: 27,
    guide: 2,
    pwrNeed: 85,
    cooldown: 15,
    price: 60000,
    upgCost: 0.30,
  );

  static const laser = DevType(
    name: 'Laser',
    imgName: 'laser',
    damage: 64,
    speed: 12,
    guide: 3,
    pwrNeed: 66,
    cooldown: 15,
    beam: 1,
    seqs: 6,
    price: 175000,
    upgCost: 0.42,
  );

  // ---- Side Weapons (VB6 ComCenter.GetDevType values) ----

  static const smallBubble = DevType(
    name: 'Small Bubble',
    imgName: 'bubble',
    damage: 6,
    speed: 15,
    guide: 0,
    pwrNeed: 4,
    cooldown: 9,
    price: 750,
    upgCost: 0.25,
    scaleProjectile: true,
    minProjScale: 0.3,
    maxProjScale: 0.55,
  );

  static const smallVulcan = DevType(
    name: 'Small Vulcan',
    imgName: 'vulcan',
    damage: 6,
    speed: 30,
    guide: 0,
    pwrNeed: 4,
    cooldown: 3,
    price: 8000,
    upgCost: 0.30,
    xShiftMax: 14,
  );

  static const starGun = DevType(
    name: 'Star Gun',
    imgName: 'starg',
    damage: 30,
    speed: 17,
    guide: 10,
    pwrNeed: 10,
    cooldown: 8,
    price: 30000,
    upgCost: 0.33,
  );

  static const smallLaser = DevType(
    name: 'Small Laser',
    imgName: 'laser',
    damage: 28,
    speed: 12,
    guide: 3,
    pwrNeed: 27,
    cooldown: 15,
    beam: 1,
    seqs: 6,
    price: 80000,
    upgCost: 0.42,
  );

  // ---- Generator ----

  static const List<DevType> generators = [generatorBasic];

  static const generatorBasic = DevType(
    name: 'Falcon Basic',
    imgName: 'generator',
    pwrGen: 4.35,
    price: 2000,
    upgCost: 0.35,
  );
}
