// Topographic contour backdrop.
//
// Slowly drifting elevation lines, a nod to the GIS plot boundaries at the core
// of the app. Line thickness is derived from a finite-difference gradient so
// strokes stay a constant pixel width without relying on derivative support.
#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uBase;
uniform vec3 uLine;
// Line opacity, 0..1.
uniform float uIntensity;
// Number of contour bands across the height range.
uniform float uBands;

out vec4 fragColor;

vec2 hash22(vec2 p) {
  p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
  return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

float gnoise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);
  vec2 u = f * f * (3.0 - 2.0 * f);
  float a = dot(hash22(i), f);
  float b = dot(hash22(i + vec2(1.0, 0.0)), f - vec2(1.0, 0.0));
  float c = dot(hash22(i + vec2(0.0, 1.0)), f - vec2(0.0, 1.0));
  float d = dot(hash22(i + vec2(1.0, 1.0)), f - vec2(1.0, 1.0));
  return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float height(vec2 p, float t) {
  float h = 0.0;
  float a = 0.55;
  vec2 q = p + vec2(t * 0.035, t * 0.02);
  for (int i = 0; i < 3; i++) {
    h += a * gnoise(q);
    q = q * 1.9 + vec2(4.2, 1.7);
    a *= 0.5;
  }
  return h;
}

void main() {
  vec2 frag = FlutterFragCoord().xy;
  float scale = 2.4 / min(uSize.x, uSize.y);
  vec2 p = frag * scale;
  float t = uTime;

  float h = height(p, t);
  float e = scale;
  float hx = height(p + vec2(e, 0.0), t);
  float hy = height(p + vec2(0.0, e), t);
  float grad = length(vec2(hx - h, hy - h)) / e;

  float v = h * uBands;
  float distBand = abs(fract(v) - 0.5);
  // Distance to the nearest line in pixels.
  float px = (0.5 - distBand) / max(grad * uBands * scale, 1e-4);
  float line = 1.0 - smoothstep(0.55, 1.35, px);

  // Every fifth line is an index contour, drawn a touch stronger.
  float index = step(0.5, 1.0 - step(0.5, abs(mod(floor(v + 0.5), 5.0))));
  float alpha = line * uIntensity * mix(0.65, 1.0, index);

  fragColor = vec4(mix(uBase, uLine, alpha), 1.0);
}
