import type { Group, Mesh, MeshStandardMaterial, Object3D } from 'three'
import { useGLTF } from '@react-three/drei'
import { useGameStore } from '@utils/Store'
import { useControls } from 'leva'
import { useEffect, useMemo, useRef } from 'react'
import { Box3, MeshToonMaterial, Quaternion, Uniform, Vector3 } from 'three'
import CustomShaderMaterial from 'three-custom-shader-material/vanilla'
import RES from '../RES'
import vertexShader from '../Shader/ball/vertex.glsl'

function Ball() {
  const gltf = useGLTF(RES.models.masterBall)

  const modelRef = useRef<Group>(null)

  const baseParams = useRef({
    upDir: new Vector3(0, 1, 0),
    direction: new Vector3(0, 0, 0),
    angle: 0,
  })

  const uniforms = useMemo(
    () => ({
      halfHeight: new Uniform(0),
      uBallPos: new Uniform(new Vector3()),
    }),
    [],
  )

  useEffect(() => {
    gltf.scene.traverse((child: Object3D) => {
      if ((child as Mesh).isMesh) {
        const mesh = child as Mesh
        const oldMat = mesh.material as MeshStandardMaterial
        mesh.material = new CustomShaderMaterial({
          defines: {
            CSM_SHADER: '',
          },
          baseMaterial: MeshToonMaterial,
          map: oldMat.map,
          vertexShader,
          silent: true,
          uniforms,
        })
      }
    })
    const boundingBox = new Box3().setFromObject(gltf.scene)
    const halfHeight = Math.floor((boundingBox.max.y - boundingBox.min.y) / 2)
    uniforms.halfHeight.value = halfHeight
  }, [])

  useControls('ball', {
    position: {
      value: {
        x: 0,
        z: 0,
      },
      max: 25,
      min: -25,
      step: 0.1,
      invert: true,
      onChange: (val) => {
        const lastPos = modelRef.current!.position
        const deltaX = val.x - lastPos.x
        const deltaZ = val.z - lastPos.z
        const { direction, upDir } = baseParams.current

        direction.set(deltaX, 0, deltaZ).normalize()

        const axis = upDir.clone().cross(direction).normalize()

        const angle = Math.PI / 20

        const q = new Quaternion().setFromAxisAngle(axis, angle)

        modelRef.current!.position.set(val.x, 2.5, val.z)

        modelRef.current!.quaternion.premultiply(q)

        uniforms.uBallPos.value.set(val.x, 0, val.z)

        useGameStore.setState({
          BallPos: useGameStore.getState().BallPos.set(val.x, 0, val.z),
        })
      },
    },
  })

  return (
    <>
      <primitive object={gltf.scene} scale={20} ref={modelRef} />
      <directionalLight position={[10, 10, 10]} />
      <ambientLight intensity={2} />
    </>
  )
}

export default Ball
