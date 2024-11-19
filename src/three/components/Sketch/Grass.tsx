import { useMemo } from "react";
import {
  BackSide,
  InstancedBufferGeometry,
  RepeatWrapping,
  Sphere,
  Uniform,
  Vector2,
  Vector3,
  Vector4,
} from "three";
import grassVertexShader from "../Shader/grass/vertex.glsl";
import grassFragmentShader from "../Shader/grass/fragment.glsl";

import { useFrame } from "@react-three/fiber";

const NUM_GRASS = 16 * 1024 * 3;
const GRASS_SEGMENTS = 6;
const GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;
const GRASS_PATCH_SIZE = 32;
const GRASS_WIDTH = 0.25;
const GRASS_HEIGHT = 2;

const Grass = () => {
  const geometry = useMemo(() => {
    const indices: number[] = [];
    for (let i = 0; i < GRASS_SEGMENTS; i++) {
      const vi = i * 2;
      indices[i * 12 + 0] = vi + 0;
      indices[i * 12 + 1] = vi + 1;
      indices[i * 12 + 2] = vi + 2;

      indices[i * 12 + 3] = vi + 2;
      indices[i * 12 + 4] = vi + 1;
      indices[i * 12 + 5] = vi + 3;

      const fi = GRASS_VERTICES + vi;
      indices[i * 12 + 6] = fi + 2;
      indices[i * 12 + 7] = fi + 1;
      indices[i * 12 + 8] = fi + 0;

      indices[i * 12 + 9] = fi + 3;
      indices[i * 12 + 10] = fi + 1;
      indices[i * 12 + 11] = fi + 2;
    }

    const geo = new InstancedBufferGeometry();
    geo.instanceCount = NUM_GRASS;
    geo.setIndex(indices);
    geo.boundingSphere = new Sphere(new Vector3(0), 1 + GRASS_PATCH_SIZE * 2);

    return geo;
  }, []);

  const uniforms = useMemo(
    () => ({
      grassParams: new Uniform(
        new Vector4(GRASS_SEGMENTS, GRASS_PATCH_SIZE, GRASS_WIDTH, GRASS_HEIGHT)
      ),
      resolution: new Uniform(new Vector2(1, 1)),
      time: new Uniform(0),
    }),
    []
  );

  useFrame((state, delta) => {
    delta %= 1;
    const dpr = state.gl.getPixelRatio();
    uniforms.resolution.value.set(innerWidth * dpr, innerHeight * dpr);
    uniforms.time.value += delta;
  });

  return (
    <>
      <mesh geometry={geometry}>
        <shaderMaterial
          vertexShader={grassVertexShader}
          fragmentShader={grassFragmentShader}
          uniforms={uniforms}
        ></shaderMaterial>
      </mesh>
    </>
  );
};

export default Grass;
