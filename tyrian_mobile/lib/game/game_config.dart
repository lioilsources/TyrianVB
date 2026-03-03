/// All game constants ported from Module.bas lines 4-36 and other sources.
/// Frame-based values are converted to time-based where needed.
library;

const double frameDelay = 25.0; // ms per frame at original 40fps
const double originalFps = 1000.0 / frameDelay; // 40 fps
const int starCount = 1000;
const int ccColorCount = 12;
const double pi = 3.14159265359;
const int maxWeapLevel = 25;
const int explosionSteps = 15;
const int explosionVariants = 4;

// Original VBA screen dimensions
const double scrWidth = 600.0;
const double scrHeight = 832.0;
const double osdWidth = 280.0;

// Logical game resolution (play area only)
const double gameWidth = scrWidth;
const double gameHeight = scrHeight;

// Font style flags (from VBA)
const int fontBold = 1;
const int fontUnderlined = 2;
const int fontItalic = 4;
const int fontStrikeout = 8;

// Mouse button flags
const int mbLeft = 1;
const int mbMiddle = 2;
const int mbRight = 4;

// File names
const String stateFileName = 'state.json';

// Collectable icon size
const double iconWidth = 35.0;
const double iconHeight = 35.0;

// Sector delay
const double delayOnComplete = 2.0; // seconds

// Structure fall speed (original: 0.05 per frame)
const double structureFallSpeed = 0.05 * originalFps; // per second

// Vessel defaults
const double vesselDefaultSpeed = 0.2;

// Weapon upgrade formulas
const double upgDamageMultiplier = 1.1;
const double upgPwrNeedMultiplier = 1.2;
const double upgCooldownDivisor = 1.02;
const double upgPwrGenMultiplier = 1.255;
const double upgGenMaxMultiplier = 1.2;
