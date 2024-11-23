import { useGLTF } from "@react-three/drei";
import RES from "../RES";
import { useLayoutEffect, useMemo, useRef } from "react";
import CustomShaderMaterial from "three-custom-shader-material/vanilla";
import {
  Euler,
  Group,
  Mesh,
  MeshStandardMaterial,
  MeshToonMaterial,
  Object3D,
  Quaternion,
  Uniform,
  Vector2,
  Vector3,
} from "three";
import vertexShader from "../Shader/ball/vertex.glsl";
import { useControls } from "leva";
import { useGameStore } from "@utils/Store";

const Ball = () => {
  const gltf = useGLTF(RES.models.masterBall);

  const modelRef = useRef<Group>(null);

  const uniforms = useMemo(
    () => ({
      uBallPos: new Uniform(new Vector3(0)),
    }),
    []
  );

  useLayoutEffect(() => {
    console.log("gltf", gltf);
    gltf.scene.traverse((child: Object3D) => {
      if ((child as Mesh).isMesh) {
        const mesh = child as Mesh;
        const oldMat = mesh.material as MeshStandardMaterial;
        mesh.material = new CustomShaderMaterial({
          baseMaterial: MeshToonMaterial,
          color: oldMat.color,
          vertexShader: vertexShader,
          silent: true,
          uniforms: uniforms,
        });
      }
    });
  }, []);

  useControls("ball", {
    position: {
      value: {
        x: 0,
        z: 0,
      },
      max: 25,
      min: -25,
      step: 0.1,
      onChange: (val) => {
        const lastPos = new Vector3().copy(uniforms.uBallPos.value);
        const deltaX = val.x - lastPos.x;
        const deltaZ = val.z - lastPos.z;
        modelRef.current!.rotation.z -= deltaX;
        modelRef.current!.rotation.x += deltaZ;
        uniforms.uBallPos.value.set(val.x, 0, val.z);

        useGameStore.setState({
          BallPos: useGameStore.getState().BallPos.set(val.x, 0, val.z),
        });
      },
    },
  });

  return (
    <>
      <directionalLight position={[10, 10, 10]} />
      <ambientLight />
      <primitive object={gltf.scene} scale={20} ref={modelRef} />
    </>
  );
};

export default Ball;
