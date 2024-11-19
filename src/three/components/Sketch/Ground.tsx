import { useMemo } from "react";
import { BackSide, RepeatWrapping, Uniform, Vector2 } from "three";
import groundVertexShader from "../Shader/ground/vertex.glsl";
import groundFragmentShader from "../Shader/ground/fragment.glsl";
import { useTexture } from "@react-three/drei";
import RES from "../RES";

const Ground = () => {
  const diffuseTex = useTexture(RES.textures.grid);
  diffuseTex.wrapS = diffuseTex.wrapT = RepeatWrapping;

  const uniforms = useMemo(
    () => ({
      diffuseTexture: new Uniform(diffuseTex),
    }),
    []
  );

  return (
    <>
      <mesh rotation-x={-Math.PI / 2} scale={10}>
        <planeGeometry args={[1, 1, 512, 512]} />
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
