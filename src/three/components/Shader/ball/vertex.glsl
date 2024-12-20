#include '../includes/common.glsl'

uniform vec3 uBallPos;
uniform float halfHeight;

vec3 terrianHeight(vec3 worldPos) {
  return vec3(worldPos.x, noise(worldPos * .02) * 15.0, worldPos.z);
}

void main() {
  vec3 worldPos = (modelMatrix * vec4(position, 1.0)).xyz;
  float offsetY = terrianHeight(uBallPos).y;
  worldPos.y += offsetY;
  worldPos.y += halfHeight;
  worldPos.y -= 2.5;
  csm_PositionRaw = projectionMatrix * viewMatrix * vec4(worldPos, 1.0);
}