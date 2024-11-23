import { useGLTF } from "@react-three/drei";
import RES from "../RES";
import { useEffect, useLayoutEffect, useMemo, useRef } from "react";
import CustomShaderMaterial from "three-custom-shader-material/vanilla";
import {
  Box3,
  Euler,
  Group,
  Mesh,
  MeshBasicMaterial,
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

  const baseParams = useRef({
    upDir: new Vector3(0, 1, 0),
    direction: new Vector3(0, 0, 0),
    angle: 0,
  });

  const uniforms = useMemo(
    () => ({
      uBallPos: new Uniform(new Vector3(0)),
      halfHeight: new Uniform(0),
    }),
    []
  );

  useEffect(() => {
    gltf.scene.traverse((child: Object3D) => {
      if ((child as Mesh).isMesh) {
        const mesh = child as Mesh;
        const oldMat = mesh.material as MeshStandardMaterial;
        mesh.material = new CustomShaderMaterial({
          defines: {
            CSM_SHADER: "",
          },
          baseMaterial: MeshToonMaterial,
          map: oldMat.map,
          vertexShader: vertexShader,
          silent: true,
          uniforms: uniforms,
        });
      }
    });
    const boundingBox = new Box3().setFromObject(gltf.scene);
    const halfHeight = Math.floor((boundingBox.max.y - boundingBox.min.y) / 2);
    uniforms.halfHeight.value = halfHeight;
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
      joystick: false,
      onChange: (val) => {
        const lastPos = new Vector3().copy(uniforms.uBallPos.value);
        const deltaX = val.x - lastPos.x;
        const deltaZ = val.z - lastPos.z;
        const { direction, upDir } = baseParams.current;

        direction.set(deltaX, 0, deltaZ).normalize();

        const axis = upDir.clone().cross(direction).normalize();

        const angle = Math.PI / 20;

        const q = new Quaternion().setFromAxisAngle(axis, angle);

        modelRef.current!.quaternion.premultiply(q);

        uniforms.uBallPos.value.set(val.x, 0, val.z);

        useGameStore.setState({
          BallPos: useGameStore.getState().BallPos.set(val.x, 0, val.z),
        });
      },
    },
  });

  return (
    <>
      <primitive object={gltf.scene} scale={20} ref={modelRef} />
      <directionalLight position={[10, 10, 10]} />
      <ambientLight intensity={2} />
    </>
  );
};

export default Ball;
