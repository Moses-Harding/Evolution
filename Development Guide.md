# Development Guide

## Autonomous Development Mode

When the user says **"Keep developing"** or **"Continue developing"**, they are granting you full creative autonomy to enhance the simulation in any way you see fit. This is not a request for a specific feature - it's permission to work independently and make design decisions.

### What This Means

You should:
- **Choose features autonomously** - Pick what to implement based on what would make the simulation more interesting, realistic, or engaging
- **Work continuously** - Don't stop after one feature. Keep implementing multiple features in succession until you've made substantial progress
- **Make design decisions** - You don't need permission for implementation details, architecture choices, or feature specifications
- **Prioritize quality** - Write clean, well-organized code with proper error handling
- **Document your work** - Write clear commit messages explaining what you added and why
- **Test as you go** - Ensure each feature works before moving to the next
- **Push frequently** - Commit and push after completing each major feature

### What NOT to Do

- Don't ask "What should I add next?" - decide yourself
- Don't ask "Is this okay?" - trust your judgment
- Don't stop after one feature - keep going
- Don't wait for approval between features - work autonomously
- Don't ask clarifying questions unless truly blocked - make reasonable assumptions

---

## Long-Term Vision: Playing God

> **IMPORTANT: This section describes the KIND of game the user wants, NOT a strict roadmap.**
>
> You have **COMPLETE CREATIVE CONTROL**. This vision is inspirational guidance, not a prescription.
>
> When developing autonomously:
> - **Make ALL decisions yourself** - architecture, features, implementation details, priorities
> - **Never ask questions** - if something is unclear, make a reasonable decision and move forward
> - **Don't stop to test/build manually** - just keep coding and committing
> - **No user intervention required** - you are the sole decision-maker
> - **Commit frequently** - that's the only requirement
> - **Keep going** - implement 5-10+ features without stopping
>
> Use this vision as inspiration for the DIRECTION and STYLE of features to build, not as a checklist.
> If you think of something cool that fits the spirit but isn't mentioned here - BUILD IT.

### Core Philosophy

**The user is playing God.** They create an initial organism with starting traits, then watch as evolution unfolds through random mutation and environmental pressure. The user's role is **not** to directly control organisms, but to:

1. **Design the initial conditions** - Set starting traits for the first organism
2. **Shape the environment** - Add obstacles, adjust temperature, control food distribution
3. **Observe emergence** - Watch as complex behaviors and capabilities emerge naturally

**Key principle**: The user defines the starting point; evolution does the rest.

---

## The Ultimate Goal

Create a simulation where **multiple species battle each other** through evolved traits, strategies, and behaviors. Over many generations:
- Organisms evolve diverse survival strategies
- Species emerge through genetic divergence and isolation
- Combat abilities develop through competition
- Environmental mastery emerges through adaptation

The endgame: **Species warfare** driven entirely by evolutionary pressure.

---

## Genetic & Evolution System

### Emergent Traits Through Underlying Systems

**DO NOT** pre-program complex abilities like "flight" or "swimming" as single toggleable traits.

**INSTEAD**, implement underlying physical properties that **combine** to enable emergent behaviors:

#### Example: Flight Emergence
Instead of a "canFly" boolean, implement:
- **Wing size** (affects lift)
- **Body weight** (affects gravity)
- **Muscle strength** (affects flapping power)
- **Bone density** (lighter = easier to lift)

When these traits combine correctly through mutation:
→ Wing size large enough + body weight low enough + muscle strength sufficient
→ **Flight emerges naturally**

#### Example: Swimming Emergence
Underlying traits:
- **Body density** (buoyancy)
- **Limb shape/flexibility** (propulsion efficiency)
- **Lung capacity** (breath holding)
- **Skin texture** (water resistance)

When combined correctly → **Swimming ability emerges**

### Mutation System

- All traits mutate independently during reproduction
- Mutations are **small, incremental changes** (not dramatic leaps)
- Occasionally allow **larger mutations** (rare, random gene shifts)
- Track **genetic distance** between organisms for speciation

### Gene Linkage (Pleiotropy)

Some genes affect **multiple unrelated traits simultaneously**:

**Example**: Size gene affects:
- Body size (primary effect)
- Energy consumption (secondary effect)
- Heat retention (tertiary effect)

This creates **trade-offs**: Increasing size for combat dominance accidentally increases energy cost and overheating in hot environments.

**Implementation approach**: Define trait linkages in code where logical. Make them discoverable through play.

---

## Species & Speciation

### Defining Species

**Species = reproductive isolation**

Two populations become separate species when:
1. **Genetic distance exceeds threshold** (e.g., 30% trait divergence)
2. Cannot produce viable offspring together
3. Tracked automatically by the system

**No infertile hybrids** - organisms either can or cannot reproduce (binary).

### Speciation Mechanisms

1. **Geographic isolation** - Populations separated by obstacles evolve independently
2. **Behavioral isolation** - Different mating behaviors prevent interbreeding
3. **Temporal isolation** - Different reproductive timing
4. **Genetic drift** - Random mutations accumulate over generations

### Visual Species Identification

**Color/pattern as species marker**:
- Each species gets a distinct color palette
- Variations within species (individual differences)
- Allows user to visually track species diversity

**Additional visual markers**:
- Body shape variations
- Pattern types (stripes, spots, solid)
- Size range differences
- Movement style differences

---

## Reproduction System

### Sexual Reproduction (Replaces Asexual)

**Sex-based mechanics**:
- **Male organisms**: Compete for access to females
- **Female organisms**: Select mates based on traits + proximity

**Mate Selection Process**:
1. Female becomes receptive (fertility cycle)
2. Nearby males detect fertile female
3. Males compete through:
   - Combat (aggression vs defense)
   - Display (size, coloration, fitness)
   - Resource control (territory, food access)
4. Winner mates with female
5. Offspring inherit traits from **both parents** (genetic crossover)

**Genetic Crossover**:
- Each trait has 50% chance from mother, 50% from father
- Plus mutation on top
- Creates diverse offspring even from same parents

**Implementation priority**: This is a major system change. Implement after core environmental features are solid.

---

## Environmental Interaction & Control

### Temperature System

**Effects on organisms**:
- **Cold environments**: Higher energy consumption (metabolism increase)
- **Hot environments**: Movement speed penalty, faster energy drain
- **Extreme temperatures**: Death zones
- **Optimal range**: Each organism has preferred temperature based on traits

**User controls**:
- Set global temperature
- Create temperature zones (hot/cold regions)
- Temperature cycles (day/night, seasonal)

**Evolutionary pressure**: Organisms evolve heat/cold tolerance traits

### Other Environmental Factors

**Water/Moisture**:
- Dry zones: Increased energy cost
- Wet zones: Movement changes (requires swimming traits)
- Organisms need water trait for aquatic environments

**Terrain Types**:
- **Grassland**: Default, no modifiers
- **Desert**: Hot, low food, high energy cost
- **Forest**: Dense obstacles, clustered food
- **Mountains**: Vertical climbing requirements

**Day/Night Cycles**:
- Affects visibility (sense range)
- Energy costs vary by time
- Enables nocturnal vs diurnal evolution

**Seasonal Changes**:
- Food abundance varies
- Temperature shifts
- Migration pressure

---

## Movement & Locomotion System

### Movement Types (Emergent)

Don't create "movement type" as a selectable option. Instead, **movement capabilities emerge** from physical traits:

#### Ground Movement (Walking)
- Base: Speed + size penalty
- Enhanced by: Leg strength, muscle efficiency
- Limited by: Body weight, terrain type

#### Aquatic Movement (Swimming)
- Emerges from: Low body density + limb flexibility
- Enhanced by: Webbed appendages, streamlined shape
- Limited by: Lung capacity, water temperature tolerance

#### Aerial Movement (Flying)
- Emerges from: Wing size + low weight + muscle strength
- Enhanced by: Hollow bones, efficient metabolism
- Limited by: Energy cost, wind resistance

#### Climbing
- Emerges from: Grip strength + body flexibility + low weight
- Enhanced by: Claw development, spatial awareness
- Limited by: Surface type, vertical distance

#### Jumping/Leaping
- Emerges from: Leg muscle power + body weight ratio
- Enhanced by: Reaction time, trajectory calculation
- Limited by: Landing surface, energy cost

**Implementation**: Gradually add underlying traits. Movement types emerge as trait combinations reach thresholds.

---

## Combat & Resource Competition

### Current System (Food Competition)
- Organisms contest food when multiple are nearby
- Aggression vs Defense determines winner
- Size provides advantage

### Future: Direct Combat

**Predator-Prey System**:
- Carnivores: Hunt other organisms for food
- Herbivores: Eat plants/default food
- Omnivores: Flexible diet

**Combat Mechanics**:
- **HP system**: Organisms have health
- **Damage calculation**: Aggression + size + weapons
- **Defense calculation**: Defense + armor + dodge
- **Combat initiation**: Proximity + hunger + aggression threshold

**Weapons & Armor (Emergent)**:
- Sharp appendages emerge from: Claw size + density + sharpness trait
- Thick hide emerges from: Skin thickness + scale hardness
- Speed/agility as defense emerges from: Speed + reaction time

### Territorial Behavior

**Territory control**:
- Organisms claim areas
- Fight intruders
- Defend resources within territory

**Pack behavior** (future):
- Multiple organisms cooperate
- Share resources
- Group hunting

---

## Neutral/Aesthetic Traits

Traits that **don't directly affect survival** but provide variation:

### Visual Traits
- **Coloration**: Base color, pattern overlay
- **Patterns**: Stripes, spots, gradients, solid
- **Bioluminescence**: Glow in dark (could affect mate selection)
- **Body decorations**: Crests, horns, tail features

### Audio Traits (Future)
- **Calls/sounds**: Different frequencies
- **Volume**: Loud vs quiet

### Behavioral Quirks (Future)
- **Movement style**: Smooth, jerky, bouncing
- **Rest behavior**: Sleep patterns
- **Social behavior**: Solitary, gregarious, pack

**Purpose**:
1. Visual diversity makes simulation interesting
2. Can become sexually selected (peacock effect)
3. May accidentally correlate with fitness (linkage)

---

## Initial Setup & Creation Menu

### Game Start Flow

1. **Creation Menu** appears
2. User designs **one initial organism**:
   - Set starting trait values (sliders/input)
   - See visual preview
   - Name the organism (optional)
3. Simulation begins with this **single organism**
4. Evolution takes over through reproduction + mutation

### Creation Menu Options

**Physical Traits**:
- Speed (1-30)
- Size (0.5-2.0)
- Sense range (50-400)

**Energy Traits**:
- Energy efficiency (0.5-1.5)
- Metabolism (0.5-1.5)
- Max age (100-400)

**Combat Traits**:
- Aggression (0-100%)
- Defense (0-100%)

**Reproduction Traits**:
- Fertility (0.5-1.5)

**Starting conditions**:
- Starting energy (0-100)
- Starting position (click on map)

---

## Development Roadmap Priorities

> **NOTE**: These phases are SUGGESTIONS for the general direction, not requirements.
> You can implement features from any phase in any order, skip phases entirely, or
> create completely new features not listed here. Trust your judgment.

### Phase 1: Foundation ✅ (Complete)
- Basic movement and energy
- Multi-trait evolution
- Food competition
- Environmental obstacles

### Phase 2: Environmental Complexity (Next)
- Temperature zones and effects
- Different terrain types
- Seasonal changes
- Day/night cycles
- Advanced food distribution patterns

### Phase 3: Species & Genetics
- Genetic distance tracking
- Species identification system
- Color-based species visualization
- Population divergence mechanics
- Speciation events

### Phase 4: Sexual Reproduction
- Male/female sex mechanics
- Mate competition
- Genetic crossover inheritance
- Mate selection behaviors

### Phase 5: Advanced Movement
- Underlying physical traits for movement
- Swimming emergence
- Climbing emergence
- Flight emergence (long-term)

### Phase 6: Direct Combat
- HP/damage system
- Predator-prey mechanics
- Weapons/armor emergence
- Territorial behavior

### Phase 7: Complex Behaviors
- Pack dynamics
- Migration patterns
- Social structures
- Communication systems

### Phase 8: Polish & Scale
- Performance optimization for 1000+ organisms
- Advanced visualization
- Data export and analysis
- Replay system

---

## Key Design Principles

1. **Emergence over programming** - Complex behaviors emerge from simple rules
2. **Incremental evolution** - Small mutations compound over time
3. **Environmental pressure drives adaptation** - Changes force evolution
4. **Trade-offs everywhere** - No perfect organism, every trait has a cost
5. **User observes, doesn't control** - God-mode = environment manipulation, not organism control
6. **Long timescale** - Interesting evolution takes hundreds of generations
7. **Visual feedback** - User can see evolution happening in real-time

---

## Work Style

When in autonomous mode, you are the **sole decision-maker**:

1. **Plan independently** - Use TodoWrite to organize your work, but YOU decide what to build
2. **Implement continuously** - Don't stop after one feature, keep going
3. **Commit frequently** - After each feature is complete
4. **No testing breaks** - Don't stop to manually test in simulator unless you need to verify something works
5. **No approval needed** - Make architectural decisions, choose features, prioritize work
6. **Make assumptions** - If something is unclear, decide what makes sense and build it
7. **Keep momentum** - 5-10+ features per session minimum
8. **Document in commits** - Clear commit messages are your only reporting requirement
9. **Trust yourself** - You understand the vision, you know Swift/SpriteKit, you can make good decisions
10. **Be creative** - If you have a cool idea that fits the spirit of the game, implement it

**Remember**: The user wants to be surprised by what you create. Don't ask permission - just build cool stuff.

### Example Session

```
User: "Keep developing"

You should:
1. Read this Development Guide
2. Review the current state of the project
3. Identify 5-10 features to implement
4. Start implementing them one by one
5. Commit and push after each feature
6. Keep going until substantial progress is made
7. Summarize what was accomplished
```

Remember: **You are the lead developer.** Make decisions, write code, and ship features. The user trusts your judgment.
