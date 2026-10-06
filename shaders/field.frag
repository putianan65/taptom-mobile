// Living field backdrop.
//
// Layered, wind-swept hills drawn in the brand palette: a warm paper sky, a
// low sun, misty far ridges and darker foreground grass whose blade tips sway
// with slow gusts. All colours arrive as uniforms so the same program serves
// both light and dark themes.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uSkyTop;
uniform vec3 uSkyBottom;
uniform vec3 uFar;
uniform vec3 uNear;
uniform vec3 uSun;
// 0..1 position of the horizon from the top of the canvas.
uniform float uHorizon;

out vec4 fragColor;

float hash(float n) { return fract(sin(n) * 43758.5453123); }

float hash2(vec2 p) {
  p = fract(p * vec2(123.34, 456.21));
  p += dot(p, p + 45.32);
  return fract(p.x * p.y);
}

float noise(float x) {
  float i = floor(x);
  float f = fract(x);
  float u = f * f * (3.0 - 2.0 * f);
  return mix(hash(i), hash(i + 1.0), u);
}

float fbm(float x) {
  float v = 0.0;
  float a = 0.5;
  for (int i = 0; i < 4; i++) {
    v += a * noise(x);
    x = x * 2.03 + 17.0;
    a *= 0.5;
  }
  return v;
}

// Rounded canopy bumps: a row of shrubs or trees along a ridge.
float canopy(float x, float density, float sway, float seed) {
  float cell = x * density + sway * 0.12;
  float id = floor(cell);
  float f = fract(cell) - 0.5;
  float r = 0.32 + 0.18 * hash(id + seed);
  float bump = sqrt(max(0.0, r * r - f * f)) / r;
  return bump * (0.55 + 0.45 * hash(id * 3.1 + seed));
}

// Thin grass blades whose tips lean with the wind.
float blades(float x, float density, float sway, float seed) {
  float cell = x * density;
  float id = floor(cell);
  float f = fract(cell) - 0.5;
  float h = 0.3 + 0.7 * hash(id + seed);
  float lean = sway * (0.5 + 0.5 * hash(id * 1.7 + seed)) * 0.45;
  float w = 0.32 + 0.16 * hash(id * 5.3 + seed);
  float tip = 1.0 - smoothstep(0.0, w, abs(f - lean));
  return tip * h;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  vec2 uv = frag / uSize;
  float aspect = uSize.x / uSize.y;
  float t = uTime;

  // Sky: vertical blend with a soft sun bloom just above the horizon.
  vec3 col = mix(uSkyTop, uSkyBottom, smoothstep(0.0, uHorizon + 0.1, uv.y));
  vec2 sunPos = vec2(0.72, uHorizon - 0.06);
  vec2 d = (uv - sunPos) * vec2(aspect, 1.0);
  float sun = exp(-dot(d, d) * 60.0);
  float halo = exp(-dot(d, d) * 5.0);
  col = mix(col, uSun, sun * 0.75 + halo * 0.14);

  // Wind: a slow travelling gust that bends the blades in sequence.
  float gust = 0.5 + 0.5 * sin(t * 0.9 - uv.x * 3.0);
  gust = 0.35 + 0.65 * gust * gust;

  // Five ridges from far to near: open hills, tree lines, then grass.
  for (int i = 0; i < 5; i++) {
    float fi = float(i);
    float k = fi / 4.0;
    float base = uHorizon + 0.015 + k * k * (1.0 - uHorizon) * 0.6;
    float freq = 1.1 + fi * 0.75;
    float drift = t * (0.004 + 0.01 * k);
    float ridge = base - (fbm(uv.x * freq * aspect + fi * 11.3 + drift) - 0.5) * (0.09 + 0.06 * k);
    float sway = sin(t * (1.1 + 0.5 * k) + uv.x * 7.0 + fi) * gust;

    float detail = 0.0;
    if (i == 1) detail = 0.006 * canopy(uv.x * aspect, 42.0, sway * 0.3, 3.0) * (0.4 + fbm(uv.x * 6.0 * aspect));
    if (i == 2) detail = 0.020 * canopy(uv.x * aspect, 16.0, sway * 0.5, 9.0);
    if (i == 3) detail = 0.014 * canopy(uv.x * aspect, 26.0, sway * 0.7, 21.0)
                       + 0.008 * blades(uv.x * aspect, 120.0, sway, 4.0);
    if (i == 4) detail = 0.044 * blades(uv.x * aspect, 38.0, sway, 13.0)
                       + 0.028 * blades(uv.x * aspect + 0.37, 64.0, sway * 1.2, 29.0)
                       + 0.014 * blades(uv.x * aspect + 0.71, 100.0, sway * 1.4, 41.0);
    float edge = ridge - detail;

    vec3 layer = mix(uFar, uNear, k);
    // Atmospheric perspective keeps the far ridges pale.
    layer = mix(layer, uSkyBottom, (1.0 - k) * (1.0 - k) * 0.6);
    // Soft vertical shading: each ridge darkens slightly toward its base.
    layer *= 1.0 - 0.10 * smoothstep(edge, edge + 0.25, uv.y);
    // Faint rim light along the crest, facing the sun.
    float rim = smoothstep(0.012, 0.0, uv.y - edge) * (1.0 - k) * 0.5;
    layer = mix(layer, uSun, rim * 0.25);

    float aa = 1.2 / uSize.y;
    float m = smoothstep(edge - aa, edge + aa, uv.y);
    col = mix(col, layer, m);
  }

  // Drifting pollen, very sparse and only in the air above the near field.
  vec2 pg = vec2(uv.x * aspect, uv.y) * 18.0 + vec2(t * 0.15, -t * 0.25);
  vec2 cell = floor(pg);
  vec2 fp = fract(pg) - 0.5;
  float r = hash2(cell);
  vec2 off = vec2(hash2(cell + 3.1), hash2(cell + 7.7)) - 0.5;
  float speck = smoothstep(0.06, 0.0, length(fp - off * 0.6)) * step(0.93, r);
  speck *= smoothstep(uHorizon + 0.35, uHorizon - 0.1, uv.y) * (0.5 + 0.5 * sin(t * 2.0 + r * 30.0));
  col = mix(col, uSun, speck * 0.55);

  // Fine grain stops gradients from banding on 8-bit panels.
  float grain = hash2(frag + fract(t) * 100.0) - 0.5;
  col += grain * 0.018;

  fragColor = vec4(col, 1.0);
}
