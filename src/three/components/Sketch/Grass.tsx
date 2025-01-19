import { useMemo } from "react";
import {
  BackSide,
  InstancedBufferGeometry,
  RepeatWrapping,
  Sphere,
  SRGBColorSpace,
  Uniform,
  Vector2,
  Vector3,
  Vector4,
} from "three";
import grassVertexShader from "../Shader/grass/vertex.glsl";
import grassFragmentShader from "../Shader/grass/fragment.glsl";

import { useFrame } from "@react-three/fiber";
import { useTexture } from "@react-three/drei";
import RES from "../RES";
import { useTextureAtlas } from "@utils/useTextureAtlas";
import { useControls } from "leva";
import { useGameStore } from "@utils/Store";

const NUM_GRASS = 32 * 1024;
const GRASS_SEGMENTS = 6;
const GRASS_VERTICES = (GRASS_SEGMENTS + 1) * 2;
const GRASS_PATCH_SIZE = 25;
const GRASS_WIDTH = 0.15;
const GRASS_HEIGHT = 2;

const Grass = () => {
  const tileDataTex = useTexture(RES.textures.tileData);
  tileDataTex.flipY = false;

  // grass diffuse
  // ex 1:
  // const grassDiffuse = useTextureAtlas([
  //   RES.textures.grass1,
  //   RES.textures.grass2,
  // ]);

  // ex 2:
  const grassDiffuse = useTexture(RES.textures.grass);
  grassDiffuse.generateMipmaps = false

  const geometry = useMemo(() => {
    const indices: number[] = [];
    // 正面 0->1->2  2->1->3 背面和正面顺序相反
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
      tileDataTexture: new Uniform(tileDataTex),
      grassDiffuseTex: new Uniform(grassDiffuse),
      playerPos: new Uniform(new Vector3()),
    }),
    []
  );

  useFrame((state, delta) => {
    delta %= 1;
    const dpr = state.gl.getPixelRatio();
    uniforms.resolution.value.set(innerWidth * dpr, innerHeight * dpr);
    uniforms.time.value += delta;
    const ballPos = useGameStore.getState().BallPos;
    uniforms.playerPos.value.set(ballPos.x, 0, ballPos.z);
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
