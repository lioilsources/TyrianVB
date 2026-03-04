import 'dart:math';
import '../game/game_config.dart' as config;

/// Path types from VBA PathType enum
enum PathType { linear, cosinus, sinCos, sinus }

/// What happens when a path ends (VBA PathAction enum)
enum PathAction { destroy, freezeFleet, noop, replacePath, stay }

/// A single node in the path linked list.
/// Ported from Position.cls — but stored in a List for Dart.
class PathNode {
  final double x;
  final double y;
  const PathNode(this.x, this.y);
}

/// Ported from Path.cls — generates movement trajectories.
class PathSystem {
  final List<PathNode> nodes = [];
  int currentIndex = 0;
  PathAction onExit = PathAction.destroy;
  bool cycled = false;

  PathNode? get current =>
      nodes.isNotEmpty && currentIndex < nodes.length
          ? nodes[currentIndex]
          : null;

  bool get isComplete => currentIndex >= nodes.length;

  /// Advance to next node. Returns true if still has nodes.
  bool advance() {
    if (nodes.isEmpty) return false;
    currentIndex++;
    if (currentIndex >= nodes.length) {
      if (cycled) {
        currentIndex = 0;
        return true;
      }
      return false;
    }
    return true;
  }

  /// Port of Path.Generate (Path.cls)
  /// Generates path nodes from (sx,sy) to (dx,dy) with given type.
  void generate(
    int steps,
    double sx,
    double sy,
    double dx,
    double dy,
    PathType type, {
    double amplitude = 100,
    int cycles = 4,
    double amplMultiplier = 1.0,
  }) {
    if (steps <= 0) return;

    final length = sqrt((dx - sx) * (dx - sx) + (dy - sy) * (dy - sy));
    final angStep =
        length > 0 ? (2 * config.pi * cycles) / length : 0.0;

    // Axis direction components
    final ax = (dx - sx) / steps;
    final ay = (dy - sy) / steps;

    // Perpendicular normalized
    double xs = 0, ys = 0;
    if (length > 0) {
      xs = -(dy - sy) / length;
      ys = (dx - sx) / length;
    }

    double cx = sx;
    double cy = sy;
    double ang = 0;
    double ampl = amplitude;

    for (int i = 0; i <= steps; i++) {
      double px, py;
      switch (type) {
        case PathType.linear:
          px = cx;
          py = cy;
        case PathType.cosinus:
          px = cx + sin(ang) * ampl * ys;
          py = cy;
        case PathType.sinus:
          px = cx;
          py = cy + sin(ang) * ampl * xs;
        case PathType.sinCos:
          px = cx + sin(ang) * ampl * ys;
          py = cy + cos(ang) * ampl * xs;
      }

      nodes.add(PathNode(px, py));

      cx += ax;
      cy += ay;
      ang += angStep;
      ampl *= amplMultiplier;
    }
  }

  /// Jump to the last node (VB6 Path.Finish)
  void finish() {
    if (nodes.isNotEmpty) {
      currentIndex = nodes.length - 1;
    }
  }

  /// Append another path's nodes (onExit from appended path overrides)
  void addPath(PathSystem other) {
    nodes.addAll(other.nodes);
    onExit = other.onExit;
  }

  /// Make path cyclic (last -> first)
  void encycle() {
    cycled = true;
  }

  /// Clone: new PathSystem sharing the same node data, starting at 0
  PathSystem clone() {
    final p = PathSystem();
    p.nodes.addAll(nodes);
    p.onExit = onExit;
    p.cycled = cycled;
    return p;
  }

  /// Generate a cycle path (out and back) and loop it
  static PathSystem createCyclePath(
    int steps,
    double x,
    double y,
    double dx,
    double dy,
    PathType type, {
    double amplitude = 100,
    int cycles = 4,
    double amplMultiplier = 1.0,
  }) {
    final path = PathSystem();
    path.generate(steps, x, y, x + dx, y + dy, type,
        amplitude: amplitude,
        cycles: cycles,
        amplMultiplier: amplMultiplier);
    final returnPath = PathSystem();
    returnPath.generate(steps, x + dx, y + dy, x, y, type,
        amplitude: amplitude,
        cycles: cycles,
        amplMultiplier: amplMultiplier);
    path.addPath(returnPath);
    path.encycle();
    return path;
  }
}
