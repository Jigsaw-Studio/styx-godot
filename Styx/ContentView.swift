//
//  ContentView.swift
//  Styx
//
//  Created by Steve Castellotti on 9/4/24.
//
// Copyright (c) 2024 Steve Castellotti
// This file is part of styx-os and is released under the MIT License.
// See LICENSE file in the project root for full license information.

import SwiftUI
import RealityKit
import GodotVision

struct ContentView: View {
    @StateObject private var godotVision = GodotVisionCoordinator()

    var body: some View {
        GeometryReader3D { (geometry: GeometryProxy3D) in
            RealityView { content in
                
                let pathToGodotProject = "Godot"
                
                // Initialize Godot
                let rkEntityGodotRoot = godotVision.setupRealityKitScene(content,
                                                                         volumeSize: VOLUME_SIZE,
                                                                         projectFileDir: pathToGodotProject)
                
                print("Godot scene root: \(rkEntityGodotRoot)")
                
            } update: { content  in
                // update called when SwiftUI @State in this ContentView changes. See docs for RealityView.
                // user can change the volume size from the default by selecting a different zoom level.
                // we watch for changes via the GeometryReader and scale the godot root accordingly
                let frame = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                let volumeSize = simd_double3(frame.max - frame.min)
                godotVision.changeScaleIfVolumeSizeChanged(volumeSize)
            }
        }
        .modifier(GodotVisionRealityViewModifier(coordinator: godotVision))
    }
        
    @ViewBuilder
    func sceneButton(label: String, resourcePath: String) -> some View {
        Button {
            godotVision.changeSceneToFile(atResourcePath: resourcePath)
        } label: {
            Text(label)
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
