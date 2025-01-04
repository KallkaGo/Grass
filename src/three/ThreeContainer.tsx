import { Canvas } from '@react-three/fiber'
import { useInteractStore } from '@utils/Store'
import { Leva } from 'leva'
import { Perf } from 'r3f-perf'
import { Suspense } from 'react'
import { NoToneMapping } from 'three'
import Sketch from './components/Sketch/Sketch'

export default function ThreeContainer() {
  const demand = useInteractStore(state => state.demand)
  return (
    <>
      <Leva collapsed />
      <Canvas
        frameloop={demand ? 'never' : 'always'}
        className="webgl"
        dpr={[1, 1.5]}
        camera={{
          fov: 60,
          near: 0.1,
          position: [10, 5, 5],
          far: 500,
        }}
        gl={{ toneMapping: NoToneMapping }}
      >
        <Perf position="top-left" />
        <Suspense fallback={null}>
          <Sketch />
        </Suspense>
      </Canvas>
    </>
  )
}
