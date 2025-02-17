# styx-godot

An engine to visualize and interact with network traffic data in Augmented and Virtual Reality

<div style="text-align:center;">
  <img src="docs/images/styx-360x360.png" alt="Styx Logo" width="360"/>
</div>

In Greek mythology the River Styx was the boundary between the world of the living and Hades

The Styx project provides a boundary between your devices and the Underworld of the Internet

<div style="text-align:center;">
  <img src="docs/images/styx-matrix-1080p.jpg" alt="Matrix Visualization" width="640"/>
</div>

## Features
- Augmented Reality live pass-through support
- Virtual Reality native support for Meta Quest, SteamVR, and OpenXR headsets
- Apple Vision Pro native support for visionOS
- WebXR support for installation-free use with walled-garden devices
- "Teleport" locomotion for AR/VR/XR environments
- On-screen Joystick Touch Pad support for mobile and tablet devices

## Platforms
- Apple Vision Pro
- Meta Quest 3, 3s, and 2
- SteamVR and OpenXR headsets (such as Valve Index)
- WebXR supported devices
- Android
- iPhone and iPad

## Dependencies

### Network Access Point
- [styx-os](https://github.com/Jigsaw-Studio/styx-os) on a Raspberry Pi 3, 4, or 5

### Apple Vision Pro
- Reference: [GodotVision](https://godot.vision/)
- Requires updates from Godot 4.2 to 4.3
- Download Godot 4.3 version of modules:
    ```
    git clone git@github.com:kevinw/GodotVision.git
    git clone git@github.com:multijam/SwiftGodot.git
    git clone git@github.com:multijam/SwiftGodotKit.git
    ```
- Download Godot 4.3 version of [libgodot.xcframework.zip](https://github.com/multijam/SwiftGodot/releases/download/4.3.0/libgodot.xcframework.zip)
- Extract `libgodot.xcframework` and place into `SwiftGodot` root directory from git repository (this prevents a later error during import that local binary targets `libgodot_tests` and `binary_libgodot` at the `SwiftGodot/libgodot.xcframework` location "does not contain a binary artifact.")
- Open `GodotProject/project.godot` once in Godot 4.3 editor to automatically import assets
- Open `Styx.xcodeproj` Xcode project in Xcode 16.2
- Build and Run on visionOS simulator or install to Apple Vision Pro (will require adding App Store Team ID)

### Meta Quest and Android devices
- Follow the standard Godot [Deploying to Android](https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html) guide

### WebXR
- Reference: Godot [Exporting for the Web](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html) guide
- Generate a Web Export to a build directory with name `index.html`
- Transfer all files from build directory to [styx-os](https://github.com/Jigsaw-Studio/styx-os) at path `/srv/styx-web/html`
- Example all-in-one command on macOS:
    ```
    /Applications/Godot\ 4.3.app/Contents/MacOS/Godot \
  	  --path $HOME/styx-godot/Godot_Project \
  	  --headless \
  	  --export-release "Web" \
            $HOME/styx-godot/Godot_Project/build/html/index.html \
    && rsync --delete -zvaP \
        $HOME/styx-godot/Godot_Project/build/html/* \
        172.16.100.1:/srv/styx-web/html
    ```

### iOS and iPadOS
- Reference: Godot [Exporting for iOS](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html) guide
- In most cases the default settings for exporting to iOS should be sufficient

## Credits
- Godot XR Tools: [Website](https://godotvr.github.io/godot-xr-tools/), [GitHub](https://github.com/GodotVR/godot-xr-tools) (special thanks [Bastiaan Olij](https://github.com/BastiaanOlij))
- [GodotVision](https://godot.vision/) (special thanks [Kevin Watters](https://github.com/kevinw))
- [Pocket Godot](https://github.com/lukky-nl/Pocket-Godot) (special thanks [@lukky-nl](https://github.com/lukky-nl))
- David Snopek's [How to make a VR game for WebXR with Godot 4](https://www.snopekgames.com/tutorial/2023/how-make-vr-game-webxr-godot-4)
