# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Evolution is an iOS simulation game demonstrating natural selection principles. Organisms compete for limited food resources, and successful ones reproduce with mutations, leading to evolutionary changes over time. Built with Swift, SpriteKit for 2D simulation, and SwiftUI for the statistics UI.

## Building and Testing

### Build and Run
```bash
# Open in Xcode
open Evolution.xcodeproj

# Build and run from command line (after opening in Xcode)
xcodebuild -scheme Evolution -destination 'platform=iOS Simulator,name=iPhone 15' build

# Run tests
xcodebuild test -scheme Evolution -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Xcode Shortcuts
- ⌘R - Build and run
- ⌘U - Run all tests
- ⌘6 - Open Test Navigator to run individual test suites

### Requirements
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+ (Swift Charts requirement)
- Swift 5.9+

## Architecture

### Three-Layer Architecture

**1. Model Layer** (`Evolution/Models/`)
- `Organism.swift` - Core entity with evolution logic (speed trait, reproduction with mutation, movement calculations, color gradient)
- `Food.swift` - Simple resource entity with position and claimed status
- `DailySnapshot.swift` - Statistics capture for historical tracking

**2. Simulation Engine** (`Evolution/GameScene.swift`)
- Inherits from `SKScene` for SpriteKit integration
- Manages 60-second day cycles with two phases:
  - Movement phase (0-50s): Organisms move toward nearest unclaimed food
  - Evaluation phase (50-60s): Calculate births/deaths, execute reproduction
- Publishes statistics via Combine's `PassthroughSubject`
- Handles collision detection, organism/food node management, and visual animations

**3. View Layer** (`Evolution/Views/`)
- `GameView.swift` - SwiftUI host for SpriteKit scene with adaptive layout (70/30 split, landscape=horizontal, portrait=vertical)
- `StatisticsPanel.swift` - Comprehensive dashboard with multiple sub-views:
  - LiveMetricsView - Current stats display
  - PopulationChartView - Population line chart
  - SpeedChartView - Average speed evolution
  - SpeedDistributionView - Speed histogram
  - OrganismListView - Scrollable organism list

### Data Flow
```
GameScene (SpriteKit simulation at 60 FPS)
    ↓ [PassthroughSubject publisher at day transitions]
GameViewModel (@ObservableObject bridge)
    ↓ [@Published property triggers UI updates]
GameView (SwiftUI)
    ↓ [Pass statistics to child views]
StatisticsPanel (Display charts and lists)
```

## Core Simulation Mechanics

### Day Cycle (60 seconds)
1. **Movement Phase (0-50s)**: Each organism finds nearest unclaimed food via O(n*m) brute force, moves toward it at speed-based rate, collision detection checks food capture
2. **Evaluation Phase (50-60s)**: Fed organisms have 70% reproduction chance, unfed organisms die and are removed from scene
3. **Day Transition (60s)**: Day counter increments, 5 new food items spawn randomly, statistics update and publish

### Evolution Parameters
- **Initial population**: 10 organisms at speed 10
- **Food per day**: 5 pieces (creates selection pressure)
- **Reproduction**: 70% probability if fed, speed mutates by ±0-2 (uniform distribution)
- **Speed range**: 1-30 (clamped during mutation)
- **Visual representation**: Blue=slow → Red=fast gradient based on speed ratio

### Collision Detection
- Organism radius: 10 points
- Food size: 8x8 points
- Distance-based: `sqrt((x2-x1)² + (y2-y1)²) < (organismRadius + foodRadius)`
- Checked every frame during movement phase

## Code Organization

### Model Classes (Reference Types)
Organisms and Food are classes (not structs) because:
- SpriteKit needs stable object identity for node mapping
- State changes frequently (position, hasFoodToday, isClaimed)
- GameScene maintains mutable references in arrays
- Food objects shared between Organism.targetFood references

### State Management
- `organisms: [Organism]` - Active population array
- `organismNodes: [UUID: SKShapeNode]` - Visual representation mapping
- `food: [Food]` and `foodNodes: [UUID: SKShapeNode]` - Food tracking
- Statistics published via Combine, received in GameViewModel, flows to SwiftUI

### Visual Feedback
- Yellow stroke when organism captures food
- Fade out + shrink animation on death
- Scale up animation on birth
- Color gradient reflects speed trait

## Testing Strategy

Tests follow TDD principles with comprehensive coverage:

**OrganismTests** (8 tests)
- Initialization, speed clamping, reproduction, mutation range, movement, color gradient

**FoodTests** (3 tests)
- Initialization, claiming mechanics

**GameSceneTests** (7 tests)
- Initial setup, speed distribution, reproduction probability (statistical validation), mutation boundaries, generation tracking, collision logic, statistics snapshots

Run individual test files:
```bash
xcodebuild test -scheme Evolution -only-testing:EvolutionTests/OrganismTests
xcodebuild test -scheme Evolution -only-testing:EvolutionTests/GameSceneTests
```

## Performance Characteristics

- **Current scale**: 10-200 organisms run smoothly at 60 FPS
- **Nearest food search**: O(n*m) brute force is sufficient for MVP scale (typically 10-100 organisms, 5 food)
- **Collision detection**: O(n) per frame during movement phase
- **Future optimization opportunities**: Spatial hashing/quadtree for larger populations (200+)

## Known Limitations (MVP Scope)

- Single trait evolution (speed only)
- No energy system or multi-trait mechanics
- No user controls (pause, speed adjustment, reset)
- No persistence or replay capability
- Population can go extinct with bad RNG (no minimum safeguards)
- Food can spawn on top of organisms
- No accessibility features

## Extension Points

### Adding New Traits
1. Add property to Organism model
2. Update `reproduce()` method with mutation logic
3. Modify `color` computed property if visual representation needed
4. Add statistics tracking in GameScene
5. Update StatisticsPanel UI with new metrics
6. Write unit tests for new behavior

### Adding Game Controls
1. Create control view in SwiftUI (pause/speed/reset buttons)
2. Add @Published state to GameViewModel
3. Pass state to GameScene via binding
4. Implement control logic in update loop

### Environmental Features (Phase 4 Roadmap)
- Create new model classes (Obstacle, Terrain)
- Extend GameScene with collision/pathfinding logic
- Add visual nodes for new elements
- Update movement calculations to account for environment

## Development Roadmap

**Phase 1: MVP** ✅ Complete
- Core simulation engine with speed evolution

**Phase 2: Enhanced Visualization** (Weeks 5-6)
- Organism movement trails, generation-based colors, better animations
- Playback controls (pause/resume, speed adjustment)
- Data export to CSV

**Phase 3: Multi-Trait System** (Weeks 7-10)
- Vision range, size, energy efficiency traits
- Energy system with consumption mechanics

**Phase 4: Environmental Complexity** (Weeks 11-14)
- Obstacles, climate cycles, terrain types
- Predator-prey dynamics

See Roadmap.md for complete development plan and technical specifications.

## Key Design Decisions

**Why SpriteKit?**
- Native iOS framework with efficient 2D rendering for 100+ entities
- Built-in scene management and collision detection
- Easy SwiftUI integration via SKView

**Why Combine?**
- Reactive data flow decouples simulation from UI
- Thread-safe updates (receive on main queue)
- Modern Swift concurrency pattern

**Why no hard population cap?**
- Natural regulation through food scarcity creates realistic biological model
- Allows study of population dynamics and self-balancing ecosystems

**Why uniform mutation distribution?**
- Simple ±0-2 range provides predictable evolution patterns
- Sufficient for demonstrating natural selection in MVP
- Future: Gaussian distribution for more realistic genetics
