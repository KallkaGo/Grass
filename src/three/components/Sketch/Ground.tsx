import { useTexture } from '@react-three/drei'
import { useMemo } from 'react'
import { RepeatWrapping, Uniform } from 'three'
import RES from '../RES'
import groundFragmentShader from '../Shader/ground/fragment.glsl'
import groundVertexShader from '../Shader/ground/vertex.glsl'

function Ground() {
  const diffuseTex = useTexture(RES.textures.grid)
  diffuseTex.wrapS = diffuseTex.wrapT = RepeatWrapping

  const groundTex = useTexture(RES.textures.ground)

  const uniforms = useMemo(
    () => ({
      diffuseTexture: new Uniform(diffuseTex),
      groundTex: new Uniform(groundTex),
    }),
    [],
  )
  return (
    <>
      <mesh rotation-x={-Math.PI / 2} scale={50}>
        <planeGeometry args={[1, 1, 128, 128]} />
        <shaderMaterial
          vertexShader={groundVertexShader}
          fragmentShader={groundFragmentShader}
          uniforms={uniforms}
        >
        </shaderMaterial>
      </mesh>
    </>
  )
}

export default Ground
