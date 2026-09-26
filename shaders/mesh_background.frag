#include <flutter/runtime_effect.glsl>

// A simplified port of the "mesh drift" shader: a handful of soft
// colored blobs drifting in slow circular orbits and blending together,
// in the app's own palette. Dropped from the original for a small,
// reliably-compiling Flutter fragment shader: cursor interactivity,
// domain warp, film grain, hue/contrast/saturation post-processing and
// OKLab mixing — the drifting-blob blend is the part that actually reads
// as "mesh gradient" at a glance.

uniform vec2 uSize;
uniform float uTime;
uniform vec3 uColor0;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform vec3 uColor3;

out vec4 fragColor;

vec3 shade(vec2 p, float t) {
  vec3 acc = uColor0 * 0.25;
  float total = 0.25;

  vec2 c0 = vec2(sin(t * 0.21), cos(t * 0.17)) * 0.55;
  float w0 = exp(-dot(p - c0, p - c0) * 2.6);
  acc += uColor0 * w0;
  total += w0;

  vec2 c1 = vec2(sin(t * 0.28 + 2.4), cos(t * 0.26 + 2.4)) * 0.55;
  float w1 = exp(-dot(p - c1, p - c1) * 2.6);
  acc += uColor1 * w1;
  total += w1;

  vec2 c2 = vec2(sin(t * 0.19 + 4.8), cos(t * 0.31 + 4.8)) * 0.55;
  float w2 = exp(-dot(p - c2, p - c2) * 2.6);
  acc += uColor2 * w2;
  total += w2;

  vec2 c3 = vec2(sin(t * 0.24 + 1.2), cos(t * 0.22 + 1.2)) * 0.55;
  float w3 = exp(-dot(p - c3, p - c3) * 2.6);
  acc += uColor3 * w3;
  total += w3;

  return acc / total;
}

void main() {
  vec2 p = (FlutterFragCoord().xy - 0.5 * uSize) / min(uSize.x, uSize.y);
  vec3 col = shade(p, uTime);
  fragColor = vec4(col, 1.0);
}
