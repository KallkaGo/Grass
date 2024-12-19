import { useLoader } from '@react-three/fiber'
import { useEffect } from 'react'
import { ClampToEdgeWrapping, DataArrayTexture, LinearFilter, LinearMipMapLinearFilter, RGBAFormat, TextureLoader, UnsignedByteType } from 'three'

class CanvasSingleton {
  private static instance: CanvasSingleton | null = null
  private canvas: HTMLCanvasElement
  private context: CanvasRenderingContext2D

  private constructor() {
    this.canvas = document.createElement('canvas')
    const context = this.canvas.getContext('2d', { willReadFrequently: true })
    if (!context) {
      throw new Error('Unable to create 2D rendering context')
    }
    this.context = context
  }

  static getInstance() {
    if (!CanvasSingleton.instance) {
      CanvasSingleton.instance = new CanvasSingleton()
    }
    return CanvasSingleton.instance
  }

  static clear() {
    if (CanvasSingleton.instance) {
      CanvasSingleton.instance = null
    }
  }

  getCanvas() {
    return this.canvas
  }

  getContext() {
    return this.context
  }
}

function getImageData(image: Image) {
  const instance = CanvasSingleton.getInstance()
  const canvas = instance.getCanvas()
  const context = instance.getContext()

  canvas.width = image.width
  canvas.height = image.height

  context.translate(0, image.height)
  context.scale(1, -1)
  context.drawImage(image, 0, 0)

  const imageData = context.getImageData(0, 0, image.width, image.height)

  context.clearRect(0, 0, image.width, image.height)

  return imageData
}

/**
 *
 * @param textureURLs urls of textures
 * @returns texture
 */
export function useTextureAtlas(textureURLs: string[]) {
  const textures = useLoader(TextureLoader, textureURLs)
  let width: any = null
  let height: any = null
  let data: any = null

  const imageDatas = textures.map((texture) => {
    const imageData = getImageData(texture.image)

    if (width === null || height === null) {
      width = imageData.width
      height = imageData.height
      data = new Uint8Array(textureURLs.length * 4 * width * height)
    }

    if (imageData.width !== width || imageData.height !== height) {
      console.error('Texture dimensions do not match')
      return null
    }

    return imageData
  })

  imageDatas.forEach((imageData, index) => {
    const offset = index * (4 * width * height)
    data.set(imageData!.data, offset)
  })

  const dataTexture = new DataArrayTexture(data, width, height, textures.length)
  dataTexture.format = RGBAFormat
  dataTexture.type = UnsignedByteType
  dataTexture.minFilter = LinearMipMapLinearFilter
  dataTexture.magFilter = LinearFilter
  dataTexture.wrapS = ClampToEdgeWrapping
  dataTexture.wrapT = ClampToEdgeWrapping
  dataTexture.generateMipmaps = true
  dataTexture.needsUpdate = true

  useEffect(() => {
    return () => {
      CanvasSingleton.clear()
      dataTexture.dispose()
    }
  }, [])

  return dataTexture
}
