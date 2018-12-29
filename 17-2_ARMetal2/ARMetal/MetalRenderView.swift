//
//  MetalRenderView.swift
//  ARMetal2
//
//  Created by Shuichi Tsutsumi on 2017/09/25.
//  Copyright © 2017 Shuichi Tsutsumi. All rights reserved.
//

import UIKit
import MetalKit

class MetalRenderView: MTKView, MTKViewDelegate {

    private var commandQueue: MTLCommandQueue!
    
    internal var textureLoader: MTKTextureLoader!
    
    private let vertexData: [Float] = [
        -1, -1, 0, 1,
         1, -1, 0, 1,
        -1,  1, 0, 1,
         1,  1, 0, 1
    ]
    private lazy var vertexBuffer: MTLBuffer? = {
        let size = vertexData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: vertexData, length: size)
    }()
    
    private let textureCoordinateData: [Float] = [
        0, 1,
        1, 1,
        0, 0,
        1, 0
    ]
    private lazy var texCoordBuffer: MTLBuffer? = {
        let size = textureCoordinateData.count * MemoryLayout<Float>.size
        return makeBuffer(bytes: textureCoordinateData, length: size)
    }()
    

    private var cameraTexture: MTLTexture?
    private var snapshotTexture: MTLTexture?
    private var timeBuffer: MTLBuffer?
    var time: Float? {
        didSet {
            if time != nil {
                timeBuffer = makeBuffer(bytes: &time, length: MemoryLayout<Float>.size)
            } else {
                timeBuffer = nil
            }
        }
    }

    private var renderDescriptor: MTLRenderPipelineDescriptor?
    private var renderPipeline: MTLRenderPipelineState?
    
    
    init(frame frameRect: CGRect) {
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        guard let device = MTLCreateSystemDefaultDevice() else {fatalError()}
        self.device = device
        commonInit()
    }
    
    private func commonInit() {
        guard let device = device else {fatalError()}
        commandQueue = device.makeCommandQueue()
        textureLoader = MTKTextureLoader(device: device)

        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        renderDescriptor = descriptor

        framebufferOnly = false
        enableSetNeedsDisplay = true
        isPaused = true
        delegate = self
    }
    
    // MARK: - Private
    
    func makeBuffer(bytes: UnsafeRawPointer, length: Int) -> MTLBuffer {
        guard let device = device else {fatalError()}
        return device.makeBuffer(bytes: bytes, length: length, options: [])!
    }
    
    private func encodeShaders(commandBuffer: MTLCommandBuffer) {
        guard let renderPipeline = renderPipeline else {fatalError()}
        guard let renderPassDescriptor = currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].storeAction = .store
        
        guard let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {return}
        
        renderEncoder.setRenderPipelineState(renderPipeline)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setVertexBuffer(texCoordBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentTexture(snapshotTexture, index: 0)
        renderEncoder.setFragmentTexture(cameraTexture, index: 1)
        renderEncoder.setFragmentBuffer(timeBuffer, offset: 0, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        renderEncoder.endEncoding()
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("\(self.classForCoder)/" + #function)
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable else {return}
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        
        // レンダーパイプラインステート作成
        guard let texture = snapshotTexture else {return}
        guard let descriptor = renderDescriptor else {return}
        guard let device = device else {fatalError()}
        descriptor.colorAttachments[0].pixelFormat = texture.pixelFormat
        renderPipeline = try? device.makeRenderPipelineState(descriptor: descriptor)
        
        encodeShaders(commandBuffer: commandBuffer)
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    internal func registerTexturesFor(cameraImage: CGImage, snapshotImage: CGImage) {
        cameraTexture = try? self.textureLoader.newTexture(cgImage: cameraImage)
        snapshotTexture = try? self.textureLoader.newTexture(cgImage: snapshotImage)

        setNeedsDisplay()
    }
}

