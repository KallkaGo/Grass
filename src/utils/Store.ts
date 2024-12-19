import { Vector3 } from 'three'
import { create } from 'zustand'
/**
 * 用户交互状态
 */
const useInteractStore = create(() => ({
  touch: false,
  auto: false,
  demand: false,
  isMute: false,
  audioAllowed: false,
  browserHidden: false,
  begin: false,
  controlDom: document.createElement('div'), // 轨道控制器的dom
  end: false,
}))

const useGameStore = create(() => ({
  time: 0,
  transfer: false,
  bodyColor: '#26d6e9',
  BallPos: new Vector3(0, 0, 0),
}))

const useLoadedStore = create(() => ({
  ready: false,
}))

export { useGameStore, useInteractStore, useLoadedStore }
