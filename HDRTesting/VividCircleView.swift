
import SwiftUI
import UIKit
import Foundation
import AVFoundation

struct VividCircleView: View {
    @State private var selectedBlendMode: BlendMode = .colorDodge
    
    let blendModes: [(name: String, mode: BlendMode)] = [
        ("Normal", .normal),
        ("Multiply", .multiply),
        ("Screen", .screen),
        ("Overlay", .overlay),
        ("Darken", .darken),
        ("Lighten", .lighten),
        ("Color Dodge", .colorDodge),
        ("Color Burn", .colorBurn),
        ("Soft Light", .softLight),
        ("Hard Light", .hardLight),
        ("Difference", .difference),
        ("Exclusion", .exclusion),
        ("Hue", .hue),
        ("Saturation", .saturation),
        ("Color", .color),
        ("Luminosity", .luminosity)
    ]
    
    let colors: [(name: String, color: Color, textColor: Color)] = [
        ("Red", .red, .black),
        ("Blue", .blue, .white),
        ("Green", .green, .black),
        ("Purple", .purple, .white),
        ("Yellow", .yellow, .black),
        ("Orange", .orange, .black),
        ("Pink", .pink, .black),
        ("Cyan", .cyan, .black),
        ("Indigo", .indigo, .white),
        ("Mint", .mint, .black),
        ("Teal", .teal, .white),
        ("Brown", .brown, .white)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Circles")
                    .font(.headline)
                
//                // Blend mode picker
//                Picker("Blend Mode", selection: $selectedBlendMode) {
//                    ForEach(blendModes, id: \.name) { blendMode in
//                        Text(blendMode.name).tag(blendMode.mode)
//                    }
//                }
//                .pickerStyle(.menu)
//                .padding(.bottom)
//                
//                Text("Current Blend Mode: \(blendModes.first(where: { $0.mode == selectedBlendMode })?.name ?? "Unknown")")
//                    .font(.subheadline)
//                    .padding(.bottom)
                
                // Create a row for each color
                ForEach(colors.indices, id: \.self) { index in
                    colorPair(colorInfo: colors[index])
                        .padding(.bottom, 15)
                }
            }
            .padding()
        }
    }
    
    @ViewBuilder
    func colorPair(colorInfo: (name: String, color: Color, textColor: Color)) -> some View {
        VStack(alignment: .center) {
            Text(colorInfo.name)
                .font(.headline)
                .padding(.bottom, 5)
            
            HStack(spacing: 30) {
                // Normal circle
                VStack {
                    Circle()
                        .fill(colorInfo.color)
                        .frame(width: 120, height: 120)
                        .overlay {
                            Text("Plain")
                                .foregroundStyle(colorInfo.textColor)
                        }
                    Text("Plain")
                }
                
                // Circle with Metal rendering
                VStack {
                    ZStack {
                        Circle()
                            .fill(colorInfo.color)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Text("Metal")
                                    .foregroundStyle(colorInfo.textColor)
                            }
                        
                        VividRepresentable()
//                            .blendMode(selectedBlendMode)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    }
                    Text("With Vivid")
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.1))
        )
    }
}


import SwiftUI
import Foundation
import UIKit
import AVFoundation

struct VividRepresentable: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = ViewController
    
    func makeUIViewController(context: Context) -> ViewController {
        let controller = ViewController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
        
    }
}


class ViewController: UIViewController {
    let vividRenderLayer : CAMetalLayer = CAMetalLayer()
    var renderPass : MTLRenderPassDescriptor?
    var drawable : CAMetalDrawable?
    var commandQueue : MTLCommandQueue?
    var defaultLibrary : MTLLibrary?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVivid()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure the Metal layer's frame and drawable size match the view's bounds.
        vividRenderLayer.frame = view.bounds
        vividRenderLayer.drawableSize = view.bounds.size
    }
}


import Foundation
import AVFoundation
import SwiftUI

extension ViewController {
    
    func setupVivid() {
        vividRenderLayer.device = MTLCreateSystemDefaultDevice()
        commandQueue = vividRenderLayer.device!.makeCommandQueue()
        defaultLibrary = vividRenderLayer.device!.makeDefaultLibrary()
        
        // Enable HDR content
        vividRenderLayer.setValue(NSNumber(booleanLiteral: true), forKey: "wantsExtendedDynamicRangeContent")
        
        vividRenderLayer.pixelFormat = .bgr10a2Unorm
        vividRenderLayer.colorspace = CGColorSpace(name: CGColorSpace.displayP3_PQ)
        vividRenderLayer.framebufferOnly = false // Change to false to allow content sampling
        vividRenderLayer.frame = self.view.bounds
        vividRenderLayer.backgroundColor = UIColor.clear.cgColor
        vividRenderLayer.isOpaque = false
        vividRenderLayer.drawableSize = self.view.frame.size
        
        // Change the blending mode to screen or add to brighten underlying content
        vividRenderLayer.compositingFilter = "CIColorDodgeBlendMode" // or "addBlendMode" for more intensity
        vividRenderLayer.opacity = 1.0
        
        self.view.layer.insertSublayer(vividRenderLayer, at: 100)
        
        render()
    }
    
    @objc public func render() {
        guard let device = vividRenderLayer.device,
              let commandQueue = commandQueue else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        commandBuffer?.label = "RenderFrameCommandBuffer"
        
        // Create a texture to sample the underlying content if needed
        // This part would require more complex Metal code to sample the view beneath
        
        let renderPassDescriptor = self.currentFrameBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        
        // Here you would set up a shader that enhances brightness
        // For now, we'll use a simple approach with a brighter clear color
        
        renderEncoder?.endEncoding()
        
        commandBuffer?.present(self.currentDrawable())
        commandBuffer?.commit()
        
        renderPass = nil
        drawable = nil
    }
    
    public func currentFrameBuffer() -> MTLRenderPassDescriptor {
        if (renderPass == nil) {
            let newDrawable = self.currentDrawable()
            
            renderPass = MTLRenderPassDescriptor()
            renderPass?.colorAttachments[0].texture = newDrawable.texture
            renderPass?.colorAttachments[0].loadAction = .clear
            
            // Use a much brighter color for HDR - these values can go beyond 1.0 for HDR
            // Using PQ color space, values like 3.0 or higher will appear very bright on HDR displays
            renderPass?.colorAttachments[0].clearColor = MTLClearColorMake(1.0, 1.0, 1.0, 0.5)
            
            
            renderPass?.colorAttachments[0].storeAction = .store
        }
        
        return renderPass!
    }
    
    public func currentDrawable() -> CAMetalDrawable {
        while (drawable == nil) {
            drawable = vividRenderLayer.nextDrawable()
        }
        
        return drawable!
    }
}

