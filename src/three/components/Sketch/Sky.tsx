import { useFrame } from '@react-three/fiber'
import { useMemo } from 'react'
import { BackSide, Uniform, Vector2 } from 'three'
import skyFragmentShader from '../Shader/sky/fragment.glsl'
import skyVertexShader from '../Shader/sky/vertex.glsl'

function Sky() {
  const uniforms = useMemo(
    () => ({
      resolution: new Uniform(new Vector2(1, 1)),
    }),
    [],
  )

  useFrame((state, delta) => {
    const dpr = state.gl.getPixelRatio()
    uniforms.resolution.value.set(innerWidth * dpr, innerHeight * dpr)
  })

  return (
    <>
      <mesh>
        <sphereGeometry args={[200, 32, 15]} />
        <shaderMaterial
          side={BackSide}
          vertexShader={skyVertexShader}
          fragmentShader={skyFragmentShader}
          uniforms={uniforms}
        >
        </shaderMaterial>
      </mesh>
    </>
  )
}

export default Sky
