# Background Execution Configuration

This document describes the configuration needed to enable background execution for the Evolution simulation.

## Code Changes

The following code changes have been implemented to support background execution:

1. **GameView.swift**: Added scene phase monitoring to prevent the simulation from pausing when the app goes to background
2. **EvolutionApp.swift**: Added app-level scene phase monitoring
3. **GameScene.swift**: Configured SpriteKit view settings for continuous rendering

## Xcode Project Configuration

To enable full background execution, you need to add the following to your project:

### Info.plist Keys

Add these keys to your `Info.plist` file (or use Xcode's Info tab):

```xml
<key>UIBackgroundModes</key>
<array>
    <string>processing</string>
</array>
```

### Project Settings (Alternative Method)

In Xcode:
1. Select your project in the navigator
2. Select the "Evolution" target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "Background Modes"
6. Check "Background processing"

## How It Works

When the app moves to the background:
- The `scenePhase` environment variable detects the change
- The code explicitly sets `scene.isPaused = false` to keep the simulation running
- SpriteKit continues to update the game logic (movement, collisions, reproduction)
- Statistics continue to be updated
- Animations may be throttled by iOS to conserve battery

## Limitations

iOS may suspend the app after some time in the background to conserve battery. For truly continuous background execution, you may need to:
- Implement background tasks using `BGProcessingTask`
- Request additional background time
- Consider making this a Mac app for unlimited background execution

## Testing

To test background execution:
1. Run the app
2. Press the home button or switch to another app
3. Check the console logs for "App moved to background - simulation continues"
4. Return to the app after a few seconds/minutes
5. Verify that the simulation has progressed (check day counter and population changes)
