import { useTexture } from '@react-three/drei'
import { useControls } from 'leva'
import { useMemo } from 'react'
import { Color, RepeatWrapping, SRGBColorSpace, Uniform } from 'three'
import RES from '../RES'
import groundFragmentShader from '../Shader/ground/fragment.glsl'
import groundVertexShader from '../Shader/ground/vertex.glsl'

function Ground() {
  const [diffuseTex, roughnessTex, groundTex] = useTexture([RES.textures.grid, RES.textures.roughnessTex, RES.textures.ground3])
  diffuseTex.wrapS = diffuseTex.wrapT = RepeatWrapping
  groundTex.colorSpace = SRGBColorSpace

  const uniforms = useMemo(
    () => ({
      diffuseTexture: new Uniform(diffuseTex),
      groundTex: new Uniform(groundTex),
      groundColor: new Uniform(new Color()),
      roughnessTex: new Uniform(roughnessTex),
    }),
    [],
  )

  useControls('groundColor', {
    color: {
      // #9ddb7e
      value: ' #86e852',
      onChange: (val) => {
        uniforms.groundColor.value.set(val)
      },
    },
  })

  return (
    <>
      <mesh rotation-x={-Math.PI / 2} scale={250}>
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
