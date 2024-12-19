import { OrbitControls } from '@react-three/drei'
import { useInteractStore, useLoadedStore } from '@utils/Store'
import { useEffect } from 'react'
import Ball from './Ball'
import Grass from './Grass'
import Ground from './Ground'
import Sky from './Sky'

function Sketch() {
  const controlDom = useInteractStore(state => state.controlDom)

  useEffect(() => {
    useLoadedStore.setState({ ready: true })
  }, [])

  return (
    <>
      <OrbitControls domElement={controlDom} />
      <color attach="background" args={['black']} />
      <Sky />
      <Ground />
      <Grass />
      <Ball />
    </>
  )
}

export default Sketch
