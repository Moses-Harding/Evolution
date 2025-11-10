
# Evolution iOS Game - Detailed Development Roadmap

## Project Overview
**Game Title:** Evolution  
**Platform:** iOS (iPhone/iPad)  
**Technology Stack:** Swift, SpriteKit, SwiftUI (for UI overlay)  
**Genre:** Simulation/Strategy  
**Core Concept:** Natural selection simulator where organisms evolve traits based on environmental pressures

## Phase 1: MVP (Weeks 1-4)

### Week 1-2: Core Simulation Engine
**Goal:** Basic organisms moving and eating in 2D space

**Technical Requirements:**
- Create SpriteKit scene with dark background (600x800 default size)
- Implement Organism class with properties:
  - `id: UUID`
  - `speed: Int` (initial value: 10, range: 1-30)
  - `position: CGPoint`
  - `hasFoodToday: Bool`
  - `targetFood: Food?`
  - `generation: Int`
- Implement Food class with properties:
  - `id: UUID`
  - `position: CGPoint`
  - `isClaimed: Bool`
- Day cycle: 60 seconds total
  - 0-50 seconds: Movement phase
  - 50-60 seconds: Reproduction/death calculations
- Movement logic:
  - Straight line movement toward nearest unclaimed food
  - Speed determines pixels/second movement rate
  - Stop movement when food is captured
- Collision detection: 
  - Organism radius: 10 points
  - Food size: 8x8 points
  - Collision when distance < combined radii

**Visual Design:**
- Organisms: Colored circles (blue=slow, red=fast using speed ratio)
- Food: Green squares
- No image assets needed (pure geometric shapes)

### Week 3: Evolution Mechanics
**Goal:** Implement reproduction, mutation, and natural selection

**Reproduction System:**
- Trigger: End of each day (60-second mark)
- Conditions: Organism must have eaten
- Probability: 70% chance if fed
- Mutation: Parent speed +/- random(0,2)
- Child spawn position: 30 points away from parent at random angle
- Generation tracking: Child.generation = Parent.generation + 1

**Death System:**
- Condition: Organism didn't eat during the day
- Action: Remove from scene (no food replacement)
- Visual: Fade out animation (optional)

**Initial Parameters:**
- Starting organisms: 10
- Starting speed: 10 for all
- Food per day: 5 pieces
- Food respawn: Complete refresh each day

### Week 4: Basic Statistics & UI
**Goal:** Display evolution metrics

**Stats Panel Requirements:**
- **Live Metrics:**
  - Current day counter
  - Population count
  - Average speed (1 decimal place)
  - Min/max speed in population
- **Organism List:**
  - Scrollable list showing all organisms
  - Sort by speed (descending)
  - Display: ID (truncated), Speed, Generation, Fed status
- **Charts (using Swift Charts framework):**
  - Population over time (line graph)
  - Average speed over time (line graph)
  - Speed distribution (histogram)

**Layout:**
- Main simulation view: 70% of screen
- Stats panel: 30% of screen (right side on iPad, bottom on iPhone)
- Implement using SwiftUI overlay on SpriteKit view

## Phase 2: Enhanced Visualization (Weeks 5-6)

### Visual Improvements
- **Organism trails:** Show last 5 seconds of movement
- **Generation colors:** Hue shift based on generation number
- **Food competition visualization:** Draw lines from organisms to target food
- **Death animation:** Shrink and fade
- **Birth animation:** Grow from small size
- **Speed indicator:** Size variation (faster = slightly larger)

### UI Enhancements
- **Playback controls:**
  - Pause/Resume simulation
  - Speed controls (0.5x, 1x, 2x, 5x)
  - Reset simulation button
- **Data export:** Save statistics to CSV
- **Camera controls:** Pan and zoom for larger simulations

## Phase 3: Advanced Traits (Weeks 7-10)

### Multi-Trait System
**New Organism Traits:**
1. **Vision Range** (10-100 pixels)
   - Affects food detection distance
   - Energy cost: Higher vision = more energy consumption
2. **Size** (5-20 radius)
   - Affects food capacity (larger = can eat 2 food)
   - Affects speed (inverse relationship)
3. **Energy Efficiency** (0.5-2.0 multiplier)
   - Affects daily energy consumption
   - Trade-off with reproduction rate

**Trait Mutation System:**
- Each trait mutates independently
- Mutation rate: 30% chance per trait
- Mutation magnitude: Gaussian distribution
- Correlated traits (e.g., size affects speed)

### Energy System
- **Daily energy consumption:** Base + (Speed × Size × Vision) / Efficiency
- **Food provides energy:** Different amounts (1-5 units)
- **Starvation:** Die if energy < 0
- **Reproduction cost:** 50% of current energy

## Phase 4: Environmental Complexity (Weeks 11-14)

### Environmental Features
1. **Obstacles:**
   - Static walls requiring pathfinding
   - Moving hazards causing death
   - Safe zones with abundant food

2. **Climate Cycles:**
   - Temperature affecting movement speed
   - Seasons affecting food availability
   - Random disasters (kills 50% randomly)

3. **Food Variety:**
   - Different nutritional values
   - Poisonous food (red) requiring trait to detect
   - Rare super-food providing reproduction bonus

4. **Terrain Types:**
   - Water (requires swimming trait)
   - Hills (slower movement)
   - Fertile areas (more food spawns)

### Predator-Prey Dynamics
- **Carnivore trait:** Can eat other organisms
- **Defense trait:** Armor/spikes reducing predation chance
- **Herding behavior:** Safety in numbers
- **Camouflage:** Reduced detection by predators

## Technical Considerations

### Performance Optimization
- **Spatial partitioning** for collision detection (QuadTree)
- **LOD system** for large populations (simplify distant organisms)
- **Batch rendering** for organisms of same type
- **Background threading** for evolution calculations

### Data Structure Recommendations
```swift
// Use for efficient nearest-neighbor queries
class SpatialGrid {
    var cells: [GridPosition: [Organism]]
}

// For family tree tracking
class LineageNode {
    weak var parent: LineageNode?
    var children: [LineageNode]
    var organism: Organism
    var birthDay: Int
}

// For statistics
struct DailySnapshot {
    let day: Int
    let population: Int
    let averageTraits: [String: Float]
    let foodAvailable: Int
    let births: Int
    let deaths: Int
}
```

### Testing Requirements
- **Unit tests:** Evolution logic, mutation ranges, reproduction probability
- **Integration tests:** Full day cycles, food distribution
- **Performance tests:** Handle 1000+ organisms
- **Balancing tests:** Ensure no runaway evolution

### Key Decision Points

1. **Maximum population:** Hard cap at 500 or natural limitation?
2. **Mutation distribution:** Uniform, Gaussian, or Poisson?
3. **Food spawning:** Fixed positions or random each day?
4. **Time scale:** Allow user to adjust day length?
5. **Species divergence:** Track as separate populations or one pool?
6. **Trait interactions:** Linear relationships or complex formulas?
7. **Rendering method:** SpriteKit for everything or Metal for large populations?

### Success Metrics
- Stable population between 20-100 organisms
- Clear evolutionary pressure toward optimal traits
- Visible adaptation within 50 generations
- No memory leaks over 1000+ day simulations
- 60 FPS with 200 organisms on iPhone 12

### Common Pitfalls to Avoid
- Population explosion (add carrying capacity)
- Genetic homogenization (ensure mutation variance)
- Extinction spirals (implement minimum population safeguards)
- Memory leaks (properly remove dead organism references)
- UI blocking during calculations (use async processing)

## Resources Needed
- **No external assets required** (all programmatic shapes)
- **Frameworks:** SpriteKit, SwiftUI, Swift Charts, GameplayKit (for randomization)
- **Testing devices:** iPhone SE (small screen) to iPad Pro (large screen)
- **Analytics:** Consider Firebase for tracking evolution patterns across users

This roadmap provides a complete path from basic simulation to complex ecosystem. Each phase builds on the previous one, allowing for iterative development and testing.
