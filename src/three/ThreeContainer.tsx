import { Canvas } from "@react-three/fiber";
import { Suspense } from "react";
import { useInteractStore } from "@utils/Store";
import { Perf } from "r3f-perf";
import { Leva } from "leva";
import Sketch from "./components/Sketch/Sketch";
import { NoToneMapping } from "three";
export default function ThreeContainer() {
    const demand = useInteractStore((state) => state.demand);
    return (
        <>
            <Leva collapsed hidden={location.hash !== "#debug"} />
            <Canvas
                frameloop={demand ? "never" : "always"}
                className="webgl"
                dpr={[1, 1]}
                camera={{
                    fov: 60,
                    near: 0.1,
                    position: [10, 5, 5],
                    far: 500,
                }}
                gl={{toneMapping:NoToneMapping}}

            >
                {location.hash.includes("debug") && (
                    <Perf position="top-left" />
                )}
                <Suspense fallback={null}>
                    <Sketch />
                </Suspense>
            </Canvas>
        </>
    );
}
