//
//  ContentView.swift
//  HDRTesting
//
//  Created by Aether on 07/03/2025.
//

import SwiftUI
import CoreImage
import MetalKit
import CoreImage.CIFilterBuiltins
import PhotosUI

struct ContentView: View {
    var body: some View {
        HDRDemoView()
    }
}

// MARK: - Main Demo View
struct HDRDemoView: View {
    let hdrImageName = "hdrSample" // Make sure this exists in your asset catalog
    let nonHdrImageName = "hdrSample" // A regular SDR image
    @State private var showImages = true // New state variable, default is true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("SwiftUI HDR Demo")
                    .font(.title)
                    .padding(.top)
                
                // Info message
                Text("Note: HDR content requires a physical HDR-capable device to view properly. Simulator does not show HDR content.")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Toggle for showing/hiding images
                Toggle("Show Images", isOn: $showImages)
                    .padding(.horizontal)
                
                // EDR Headroom Monitor
                VStack {
                    Text("EDR Headroom Monitor")
                        .font(.headline)
                    EDRView()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                // HDR Circle Demo
                VStack {
                    Text("HDR Glowing Circles")
                        .font(.headline)
                    HStack{
                        HDRCircleView(hdrMultiplier: 1.0)
                        HDRCircleView(hdrMultiplier: 1.2)
                        HDRCircleView(hdrMultiplier: 1.5)
                        HDRCircleView(hdrMultiplier: 2.0)
                    }
                    .frame(height: 150)
                    .padding(.horizontal, 20)
                    .allowedDynamicRange(.constrainedHigh)
                }
                .padding()
                
                VStack {
                    Text("HDR Glowing Circles (Vivid Method)")
                        .font(.headline)
                    
                    VividCircleView()
                }
                
                if showImages {
                    HStack{
                        // Standard Non-HDR Image
                        VStack {
                            Text("Non-HDR")
                                .font(.headline)
                            
                            if let uiImage = UIImage(named: nonHdrImageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .overlay(
                                        Text("SDR")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4),
                                        alignment: .bottom
                                    )
                            } else {
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .overlay(
                                        Text("SDR")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4),
                                        alignment: .bottom
                                    )
                            }
                        }
                        
                        // HDR Image Method 1
                        VStack {
                            Text("HDR Method 1")
                                .font(.headline)
                            
                            if let uiImage = UIImage(named: hdrImageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .allowedDynamicRange(.constrainedHigh)
                                    .overlay(
                                        Text("HDR")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4),
                                        alignment: .bottom
                                    )
                            } else {
                                Text("HDR image not found")
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // HDR Image Method 2
                        VStack {
                            Text("HDR Method 2")
                                .font(.headline)
                            
                            if let uiImage = UIImage(named: hdrImageName) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 200)
                                    .allowedDynamicRange(.constrainedHigh)
                                    .overlay(
                                        Text("HDR")
                                            .foregroundColor(.white)
                                            .padding(6)
                                            .background(Color.black.opacity(0.6))
                                            .cornerRadius(4),
                                        alignment: .bottom
                                    )
                            } else {
                                Text("HDR image not found")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .padding()
            
            
        }
    }
}


// MARK: - EDR Headroom Monitor
struct EDRView: View {
    @State private var headroom: CGFloat = UIScreen.main.currentEDRHeadroom
    @State private var timer: Timer?
    @State private var supportsEDR: Bool = true
    
    var body: some View {
        VStack {
            if supportsEDR {
                Text("Current EDR Headroom: \(String(format: "%.2f", headroom))")
                    .font(.subheadline)
            } else {
                Text("This device does not support EDR/HDR")
                    .font(.subheadline)
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            // Check if device supports EDR
            supportsEDR = UIScreen.main.currentEDRHeadroom > 0
            
            // Start polling the headroom
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                headroom = UIScreen.main.currentEDRHeadroom
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

// MARK: - HDR Circle
struct HDRCircleView: View {
    let hdrMultiplier: CGFloat
    
    var body: some View {
        // Create an extended linear color in Display P3 with brightness > 1
        let extendedP3 = CGColorSpace(name: CGColorSpace.extendedLinearDisplayP3)!
        let hdrColor = CGColor(colorSpace: extendedP3,
                               components: [hdrMultiplier, hdrMultiplier, hdrMultiplier, 1.0])!
        
        return ZStack {
            Circle()
                .fill(Color(hdrColor))
        }
    }
}

#Preview {
    ContentView()
}
