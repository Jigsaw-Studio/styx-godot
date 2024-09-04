//
//  StyxApp.swift
//  Styx
//
//  Created by Steve Castellotti on 9/4/24.
//
// Copyright (c) 2024 Steve Castellotti
// This file is part of styx-os and is released under the MIT License.
// See LICENSE file in the project root for full license information.

import SwiftUI

// visionOS will silently clamp to volume size if set above or below limits
// max for all dimensions is 1.98
// min for all dimensions is 0.24
let VOLUME_SIZE = simd_double3(1.8, 1.0, 1.5)

@main
struct StyxApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.volumetric)
        .defaultSize(width: VOLUME_SIZE.x, height: VOLUME_SIZE.y, depth: VOLUME_SIZE.z, in: .meters)
    }
}
