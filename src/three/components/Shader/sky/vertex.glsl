void main() {
  vec4 localSpacePosition = vec4(position, 1.0);

  gl_Position = projectionMatrix * modelViewMatrix * localSpacePosition;
}