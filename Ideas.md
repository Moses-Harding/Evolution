# Evolution Trait Ideas

This document contains ideas for additional evolutionary traits that could make the simulation more interesting and complex.

## Implemented Traits

### Speed
- **Status**: ✅ Implemented
- **What it does**: Determines how fast organisms move toward food
- **Range**: 1-30 (configurable)
- **Mutation**: ±0-2 per generation
- **Visualization**: Color gradient (blue=slow, red=fast)

### Sense Range / Vision Range
- **Status**: 🚧 In Progress
- **What it does**: How far an organism can "see" to detect food
- **Why it's interesting**: Creates natural tradeoff with speed
  - Fast + short vision = might zoom past food without seeing it
  - Slow + long vision = can target food from far away but takes time to reach
  - Forces evolution to balance perception vs. action
- **Visualization**: Faint circle around organisms showing detection radius (optional)
- **Implementation complexity**: Medium
- **Gameplay impact**: High - completely changes optimal strategies

## Proposed Traits

### 1. Size
- **Status**: 💡 Idea
- **What it does**: Physical size affecting collision radius and potentially movement
- **Tradeoffs**:
  - Larger = easier to collect food (bigger collision radius) but slower movement
  - Smaller = faster movement but harder to catch food
  - Could affect reproduction (larger organisms produce more/larger offspring)
  - Could affect energy consumption
- **Visualization**: Already easy - vary the organism radius based on size trait
- **Implementation complexity**: Low-Medium
- **Gameplay impact**: Medium-High

### 2. Energy Efficiency
- **Status**: 💡 Idea
- **What it does**: How much "energy" organisms use while moving
- **Tradeoffs**:
  - Efficient organisms use less energy per movement, can afford to search longer
  - Inefficient organisms must reach food quickly or run out of energy
  - Could require organisms to eat multiple food items to survive
  - Creates pressure for efficient movement patterns
- **Implementation complexity**: Medium-High (requires adding energy system)
- **Gameplay impact**: Very High - fundamentally changes survival mechanics
- **Note**: Would work well with Size (larger = less efficient)

### 3. Memory / Intelligence
- **Status**: 💡 Idea
- **What it does**: Ability to remember where food spawned previously or learn patterns
- **Tradeoffs**:
  - Smart organisms patrol high-probability food spawn areas
  - Dumb organisms wander randomly or always chase nearest food
  - Could remember locations of past food
  - Could learn optimal search patterns
- **Implementation complexity**: Medium-High
- **Gameplay impact**: High - emergent intelligent behavior
- **Concerns**: Might be too abstract to visualize clearly

### 4. Reproduction Rate / Fertility
- **Status**: 💡 Idea
- **What it does**: Probability of reproduction when fed
- **Tradeoffs**:
  - High fertility = more offspring but potentially overpopulation
  - Low fertility = slower growth but less competition
  - r/K selection theory dynamics
- **Implementation complexity**: Low
- **Gameplay impact**: Medium
- **Note**: Currently all organisms use config.reproductionProbability (70%)

### 5. Lifespan / Age
- **Status**: 💡 Idea
- **What it does**: Organisms die of old age after N days, even if fed
- **Tradeoffs**:
  - Long lifespan = stable population but slower evolution
  - Short lifespan = rapid turnover and faster evolution
  - Could affect reproduction (older = less fertile)
- **Implementation complexity**: Low-Medium
- **Gameplay impact**: Medium-High
- **Gameplay dynamics**: Prevents single lineages from dominating forever

### 6. Social Behavior / Cooperation
- **Status**: 💡 Idea (Advanced)
- **What it does**: Ability to cooperate with nearby organisms
- **Possibilities**:
  - Share food with nearby organisms
  - Pack hunting / coordinated movement
  - Altruistic behavior (help related organisms)
- **Implementation complexity**: High
- **Gameplay impact**: Very High
- **Concerns**: Very complex, might need genetic relatedness tracking

### 7. Camouflage / Visibility
- **Status**: 💡 Idea (For predator/prey phase)
- **What it does**: How visible organisms are to predators
- **Note**: Only relevant once predator-prey dynamics are added
- **Tradeoffs**:
  - Well-camouflaged = safe from predators but potentially slower
  - Highly visible = vulnerable but potentially faster/stronger
- **Implementation complexity**: Medium (needs predator system first)
- **Gameplay impact**: High (in predator-prey context)

### 8. Aggression / Territoriality
- **Status**: 💡 Idea (Advanced)
- **What it does**: Ability to defend or steal food from other organisms
- **Tradeoffs**:
  - Aggressive organisms can steal food but use energy fighting
  - Passive organisms avoid conflict but lose resources
- **Implementation complexity**: High
- **Gameplay impact**: Very High
- **Concerns**: Requires combat/interaction system

## Trait Interaction Matrix

Some traits work particularly well together:

- **Speed + Sense Range**: Natural opposites that create interesting balance
- **Size + Energy Efficiency**: Large organisms should use more energy
- **Speed + Energy Efficiency**: Fast movement costs more energy
- **Memory + Sense Range**: Low sense range makes memory more valuable
- **Size + Aggression**: Larger organisms could be better fighters
- **Lifespan + Reproduction Rate**: r/K selection dynamics

## Implementation Priority

### Phase 1 (MVP+): ✅ Complete
- Speed

### Phase 2 (Current): 🚧
- Sense Range (in progress)

### Phase 3 (Next):
- Size (easy win, good visual impact)
- Energy Efficiency (pairs with size)

### Phase 4 (Advanced):
- Memory/Intelligence
- Lifespan
- Reproduction Rate

### Phase 5 (Complex Systems):
- Social Behavior
- Aggression
- Predator-prey traits

## Design Principles

When adding new traits:
1. **Meaningful Tradeoffs**: Every trait should have costs and benefits
2. **Visual Clarity**: Users should be able to see trait differences
3. **Emergent Behavior**: Traits should combine in interesting ways
4. **Balance**: No single trait should dominate all scenarios
5. **Testability**: New traits should have unit tests
6. **Performance**: Consider O(n²) interactions carefully
