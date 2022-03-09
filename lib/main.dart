import 'dart:math';
import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.setLandscape();
  await Future.delayed(const Duration(seconds: 1));
  final game = OfficeGame();
  runApp(GameWidget(game: game));
}

class OfficeGame extends FlameGame with HasTappables, HasCollisionDetection {
  final stars = <PlayerComponent>[];

  @override
  Future<void>? onLoad() {
    stars.add(PlayerComponent.random(size.toSize()));
    addAll(stars);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    final bounds = canvasSize.toSize();
    for (var s in stars) {
      s.bounds = bounds;
    }
  }
  
  @override
  void onTapDown(int pointerId, TapDownInfo info) {
    super.onTapDown(pointerId, info);
    final star = PlayerComponent.random(size.toSize());
    star.position = info.eventPosition.game;
    stars.add(star);
    add(star);
  }
}

class OfficeComponent extends PositionComponent {
  final paint = Paint()..color = Colors.grey;
  @override
  void render(Canvas canvas) {
    canvas.drawPoints(PointMode.polygon, [
      const Offset(0.0, 0.0),
      const Offset(0.0, 1.0),
      const Offset(1.0, 1.0),
      const Offset(1.0, 0.0),
    ], paint);
  }
}
final rand = Random();

Vector2 rVector(double magnitude) => Vector2(rand.nextDouble() - 0.5, rand.nextDouble() - 0.5).normalized() * magnitude;
const _radius = 24.0;
final _size = Vector2(2 * _radius, 2 * _radius);
class PlayerComponent extends PositionComponent with CollisionCallbacks {
  PlayerComponent(Color color, this.bounds)
    : paint = Paint()..color = color,
      velocity = rVector(rand.nextDouble() * bounds.longestSide / 5),
      acceleration = Vector2.zero(),//rVector(rand.nextDouble() * 5),
      super(
        size: _size,
        position: Vector2(rand.nextDouble() * bounds.width, rand.nextDouble() * bounds.height),
      ) {
    add(CircleHitbox(
      radius: _radius,
      anchor: Anchor.center,
    ));
  }

  factory PlayerComponent.random(Size bounds) => PlayerComponent(Color.fromRGBO(rand.nextInt(255), rand.nextInt(255), rand.nextInt(255), 1.0), bounds);
  
  final Paint paint;
  Vector2 velocity;
  Vector2? pendingVelocity;
  Vector2 acceleration;
  Size bounds;

  double t = 0;
  @override
  void update(double dt) {
    t += dt;
    acceleration += rVector(rand.nextDouble() * 2) * dt;
    if (acceleration.length.abs() > 2.0 && velocity.length.abs() > 5.0) {
      acceleration *= 0.9;
    }
    if (pendingVelocity != null) {
      velocity = pendingVelocity!;
      pendingVelocity = null;
    }
    velocity += acceleration * dt;
    position += velocity * dt;
    if (center.x < 0) {
      position.x %= bounds.width;
    }
    if (center.y < 0) {
      position.y %= bounds.height;
    }
    if (center.x > bounds.width) {
      position.x %= bounds.width;
    }
    if (center.y > bounds.height) {
      position.y %= bounds.height;
    }
  }
  double extraRandomness = 0;
  double get r {
    final r = rand.nextDouble();
    if (r < 0.5) {
      return 0.9 - 0.2 * r;
    }
    if (r < 0.9) {
      extraRandomness += r/10;
      return 1.0;
    }
    final b = 0.9 + extraRandomness * rand.nextDouble() + 2 * rand.nextDouble() * t % 0.5;
    extraRandomness = 0.0;
    return b;
  }

  @override
  void render(Canvas canvas) {
    //canvas.drawRect(Offset.zero & size.toSize(), Paint()..color = Colors.white);
    final vertices = Vertices(
      VertexMode.triangleFan,
      [
        const Offset(0, 0) * r,
        
        const Offset(-5, 1) * r,

        const Offset(-5, -1) * r,
        const Offset(-4, -3) * r,
        const Offset(-3, -4) * r,
        const Offset(-1, -5) * r,

        const Offset(1, -5) * r,
        const Offset(3, -4) * r,
        const Offset(4, -3) * r,
        const Offset(5, -1) * r,

        const Offset(5, 1) * r,
        const Offset(4, 3) * r,
        const Offset(3, 4) * r,
        const Offset(1, 5) * r,

        const Offset(-1, 5) * r,
        const Offset(-3, 4) * r,
        const Offset(-4, 3) * r,
        const Offset(-5, 1) * r,
      ],
    );
    canvas.translate(width/2, height/2);
    canvas.scale(width/10, height/10);
    canvas.drawVertices(vertices, BlendMode.srcATop, paint);
    //canvas.rotate(-angle);
    //canvas.translate(width/2, height/2);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);
    if (other is PlayerComponent) {
      pendingVelocity = (pendingVelocity ?? Vector2.zero()) + other.velocity;
      final axis = other.center - center;
      final dist = axis.length;
      final minDist = size.length;
      final c = (minDist - dist) / 2;
      if (c > 0) {
        final adj = axis.normalized() * c;
        other.position += adj;
        position -= adj;
      }
    }
  }
}
