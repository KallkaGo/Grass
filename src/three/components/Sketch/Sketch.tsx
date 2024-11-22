import { OrbitControls } from "@react-three/drei";
import { useInteractStore, useLoadedStore } from "@utils/Store";
import { useEffect } from "react";
import Sky from "./Sky";
import Ground from "./Ground";
import Grass from "./Grass";
import { useControls } from "leva";
import { useThree } from "@react-three/fiber";

const Sketch = () => {
  const controlDom = useInteractStore((state) => state.controlDom);

  useEffect(() => {
    useLoadedStore.setState({ ready: true });

  }, []);

  return (
    <>
      <OrbitControls domElement={controlDom} />
      <color attach={"background"} args={["black"]} />
      <Sky />
      <Ground />
      <Grass />
    </>
  );
};

export default Sketch;
