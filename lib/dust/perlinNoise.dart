class PerlinNoise {
  late List<int> _permutation;
  PerlinNoise() {
    _permutation = List.generate(512, (index) => index % 256)..shuffle();
  }

  double _fade(double t) => t * t * t * (t * (t * 6 - 15) + 10);

  double _lerp(double a, double b, double t) => a + t * (b - a);

  double _grad(int hash, double x, double y) {
    final h = hash & 15;
    final u = h < 8 ? x : y;
    final v = h < 4
        ? y
        : h == 12 || h == 14
            ? x
            : 0;
    return ((h & 1) == 0 ? u : -u) + ((h & 2) == 0 ? v : -v);
  }

  double perlin(double x, double y) {
    final xf = x.floor();
    final yf = y.floor();
    final X = xf & 255;
    final Y = yf & 255;
    x -= xf;
    y -= yf;
    final u = _fade(x);
    final v = _fade(y);
    final a = (_permutation[X] + Y) & 255;
    final b = (_permutation[X + 1] + Y) & 255;

    return _lerp(
      _lerp(_grad(_permutation[a], x, y), _grad(_permutation[b], x - 1, y), u),
      _lerp(_grad(_permutation[a + 1], x, y - 1),
          _grad(_permutation[b + 1], x - 1, y - 1), u),
      v,
    );
  }
}
