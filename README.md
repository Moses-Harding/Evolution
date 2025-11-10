# Evolution - Natural Selection Simulator

An iOS simulation game where organisms evolve traits based on natural selection and environmental pressures.

## Overview

Evolution is a real-time simulation that demonstrates natural selection principles. Organisms compete for limited food resources, and those who succeed reproduce with slight mutations, leading to evolutionary changes over time.

## MVP Features Implemented

### Core Simulation Engine
- **SpriteKit-based** 2D simulation with 60-second day cycles
- **Organisms** represented as colored circles (blue=slow, red=fast)
- **Food** spawns randomly as green squares (5 per day)
- **Movement system** with speed-based locomotion toward nearest food
- **Collision detection** for food capture

### Evolution Mechanics
- **Reproduction**: 70% chance when organism eats
- **Mutation**: Speed changes by ±0-2 with each generation
- **Natural selection**: Organisms that don't eat die at day's end
- **Generation tracking**: Monitor lineage progression
- **Population dynamics**: Natural growth without hard caps

### Statistics & Visualization
- **Live metrics dashboard**:
  - Current day counter
  - Population size
  - Average, min, and max speed
  - Births and deaths per day

- **Interactive charts** (using Swift Charts):
  - Population over time (line chart)
  - Average speed over time (line chart)
  - Speed distribution (histogram)

- **Organism list**:
  - Sortable by speed
  - Shows ID, speed, generation, and fed status
  - Live updates

### UI/UX
- **Adaptive layout**:
  - Landscape: Side-by-side (70% simulation, 30% stats)
  - Portrait: Stacked (70% top, 30% bottom)
- **Basic animations**:
  - Birth: Scale up effect
  - Death: Fade out and shrink
- **Visual feedback**:
  - Yellow highlight when organism captures food
  - Color gradient from blue (slow) to red (fast)

## Project Structure

```
Evolution/
├── Models/
│   ├── Organism.swift       # Organism entity with evolution logic
│   ├── Food.swift           # Food entity
│   └── DailySnapshot.swift  # Statistics snapshot
├── Views/
│   ├── GameView.swift       # Main game view with SpriteKit integration
│   └── StatisticsPanel.swift # Stats UI with charts
├── GameScene.swift          # Core simulation engine
├── ContentView.swift        # App entry view
└── EvolutionApp.swift       # App definition

EvolutionTests/
├── OrganismTests.swift      # Unit tests for Organism
├── FoodTests.swift          # Unit tests for Food
└── GameSceneTests.swift     # Integration tests for game logic
```

## How It Works

### Day Cycle (60 seconds)
1. **Movement Phase (0-50s)**: Organisms move toward nearest unclaimed food
2. **Evaluation Phase (50-60s)**: Reproduction and death calculations
3. **Day Transition**: New food spawns, statistics update

### Evolution Process
1. Organism finds and moves toward nearest food
2. Upon collision, organism is marked as "fed"
3. At day's end:
   - Fed organisms: 70% chance to reproduce
   - Unfed organisms: Die and are removed
   - Children spawn near parents with mutated speed (±0-2)
   - Food respawns for next day

### Natural Selection Pressure
- **Speed advantage**: Faster organisms reach food first
- **Limited resources**: Only 5 food for potentially many organisms
- **Competition**: Multiple organisms may target same food
- **Mutation**: Random speed changes allow exploration of trait space

## Building & Running

### Requirements
- Xcode 15.0+
- iOS 17.0+ / iPadOS 17.0+
- Swift 5.9+

### Steps
1. Open `Evolution.xcodeproj` in Xcode
2. Select your target device/simulator
3. Press ⌘R to build and run

### Running Tests
1. Press ⌘U to run all tests
2. Or use Test Navigator (⌘6) to run individual test suites

## Testing

The project follows TDD principles with comprehensive test coverage:

- **OrganismTests**: Movement, reproduction, mutation, speed clamping
- **FoodTests**: Initialization and claiming mechanics
- **GameSceneTests**: Integration tests for evolution logic and statistics

## Implementation Notes

### Design Decisions
- **Random food spawning**: Creates unpredictable selection pressure
- **Uniform mutation distribution**: Simple ±0-2 for predictable evolution
- **Natural population growth**: No hard caps, population self-regulates
- **Adaptive UI**: Single codebase works across iPhone and iPad

### Performance Considerations
- 60 FPS target with efficient collision detection
- Spatial queries for nearest-food calculations
- Scene updates only during movement phase
- Batch visual updates during phase transitions

### Known Limitations (MVP)
- Single trait evolution (speed only)
- No energy system
- No environmental complexity
- No predator-prey dynamics
- Maximum population naturally limited by food scarcity

## Future Enhancements (Roadmap)

See `Roadmap.md` for complete development plan including:
- Phase 2: Enhanced visualization (trails, better animations)
- Phase 3: Multi-trait system (vision, size, efficiency)
- Phase 4: Environmental complexity (obstacles, climate, terrain)

## Statistics Explained

### Population Over Time
Shows ecosystem stability. Healthy simulations stabilize between 20-100 organisms.

### Average Speed Over Time
Demonstrates evolutionary pressure. Should trend upward as faster organisms out-compete slower ones.

### Speed Distribution
Visualizes trait diversity in population. Shows how natural selection shapes the gene pool.

## Troubleshooting

### Population Dies Out
- Expected behavior with unlucky RNG early on
- Restart simulation for new initial conditions

### Population Explodes
- May happen if many organisms get lucky
- Will self-correct when food becomes too scarce

### Slow Performance
- Expected with 200+ organisms on older devices
- Close background apps
- Try on newer device/simulator

## License

Created as part of Evolution game development.
