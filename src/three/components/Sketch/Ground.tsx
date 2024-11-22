import { useEffect, useMemo } from "react";
import { BackSide, RepeatWrapping, Uniform, Vector2 } from "three";
import groundVertexShader from "../Shader/ground/vertex.glsl";
import groundFragmentShader from "../Shader/ground/fragment.glsl";
import { useTexture } from "@react-three/drei";
import RES from "../RES";
import { useInteractStore } from "@utils/Store";
import { ThreeEvent, useThree } from "@react-three/fiber";

const Ground = () => {
  const diffuseTex = useTexture(RES.textures.grid);
  diffuseTex.wrapS = diffuseTex.wrapT = RepeatWrapping;

  const groundTex = useTexture(RES.textures.ground);

  const controlDom = useInteractStore((state) => state.controlDom);

  const events = useThree((state) => state.events);

  const uniforms = useMemo(
    () => ({
      diffuseTexture: new Uniform(diffuseTex),
      groundTex: new Uniform(groundTex),
    }),
    []
  );

  useEffect(() => {
    events.connect!(controlDom);
  });

  const handlePointerDown = (event: ThreeEvent<PointerEvent>) => {
  };

  return (
    <>
      <mesh
        rotation-x={-Math.PI / 2}
        scale={50}
        onPointerDown={handlePointerDown}
      >
        <planeGeometry args={[1, 1, 128, 128]} />
        <shaderMaterial
          vertexShader={groundVertexShader}
          fragmentShader={groundFragmentShader}
          uniforms={uniforms}
        ></shaderMaterial>
      </mesh>
    </>
  );
};

export default Ground;
