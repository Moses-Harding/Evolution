# How Evolution Works

## What Is This?

Evolution is a real-time simulation that demonstrates natural selection in action. You watch simple organisms compete for limited food resources, and over time, you'll see evolution happen right before your eyes as successful traits spread through the population.

## The Basic Cycle

Every "day" in the simulation follows a simple pattern:

1. **Food appears** - A small amount of food (usually 5 pieces) spawns in the environment
2. **Organisms search** - Each organism looks for the nearest food it can detect
3. **The race begins** - Organisms move toward their target food
4. **Winners and losers** - First to reach food survives; those who don't get food die
5. **Reproduction** - Organisms that ate have a chance to reproduce, creating offspring with slightly different traits
6. **A new day begins** - The cycle repeats with the next generation

The key is that there's **never enough food for everyone**. This scarcity creates competition, and only the most fit organisms pass on their genes.

## The Four Evolutionary Traits

Each organism has four characteristics that can evolve over time:

### 1. Speed (1-30)
How fast an organism moves toward food.
- **Visual**: Color-coded from blue (slow) to red (fast)
- **Tradeoff**: Faster organisms reach food first, but there's a cost...

### 2. Sense Range (50-400)
How far an organism can detect food.
- **Visual**: Semi-transparent circle showing detection radius
- **Tradeoff**: Better vision helps find food, but sometimes speed matters more

### 3. Size (0.5-2.0)
The physical size of the organism.
- **Visual**: Bigger circles on screen
- **Tradeoff**: Larger organisms are easier to collide with food BUT they move slower (up to 50% speed penalty). They also have a bigger collision radius, making it easier to "catch" food.

### 4. Fertility (0.5-1.5)
How likely an organism is to reproduce when it eats.
- **Base rate**: 70% chance of reproduction
- **High fertility (1.5)**: 95% reproduction chance - rapid population growth
- **Low fertility (0.5)**: 35% reproduction chance - slower, steadier growth
- **Tradeoff**: More offspring means faster population expansion, but can lead to overpopulation and mass starvation

## How Evolution Happens

When an organism reproduces, its offspring inherits its traits... **with small random mutations**:
- Speed can change by ±2
- Sense range can change by ±20
- Size can change by ±0.15
- Fertility can change by ±0.1

Over many generations, beneficial combinations of traits become more common because organisms with those traits are more likely to survive and reproduce.

## Environmental Pressures

To keep things interesting, the food distribution pattern changes every 10 days:

### Random Pattern
Food scattered randomly across the map. Balanced traits work best.

### Clustered Pattern
Food spawns in tight groups. Large size helps dominate clusters, and high fertility can explode population in abundance.

### Scattered Pattern
Food maximally spread apart. Speed and sense range are king - you need to cover ground fast.

### Ring Pattern
Food forms a circle around the center. Sense range is critical to locate the ring, balanced size helps.

Different environments favor different traits, preventing the population from converging on a single "perfect" organism.

## What Makes It Interesting

### Emergent Strategies
You'll see different evolutionary strategies emerge:
- **Speedsters**: Fast, small organisms that race to food
- **Giants**: Large organisms that use their size advantage for better collision detection
- **Sensors**: Long-range detectors that find hidden food
- **Breeders**: High-fertility organisms that rapidly populate during good times

### Visual Feedback
- **Elite Organisms**: Top 20% performers glow golden
- **Movement Trails**: See the paths organisms take
- **Population Health**: Color-coded indicators (🌟 thriving, 💀 critical)
- **Sense Range Visualization**: See what each organism can detect

### Population Dynamics
Watch the population size fluctuate:
- **Boom**: When food patterns favor current traits
- **Bust**: When the environment changes or overpopulation occurs
- **Recovery**: As evolution adapts the population to new conditions

### Multi-Generational Evolution
The simulation tracks generations. By day 50, you might see organisms that are radically different from the starting population, perfectly adapted to the current environment... until the food pattern changes again.

## The Evolutionary Arms Race

Because the environment keeps changing, there's no single "winner." Instead, you get an ongoing evolutionary arms race where different trait combinations rise and fall based on current conditions. This mirrors real-world evolution, where environmental changes drive continuous adaptation.

## Why It Matters

This simulation demonstrates core principles of evolutionary biology:
- **Natural Selection**: Better-adapted organisms survive and reproduce more
- **Genetic Drift**: Random mutations provide variation
- **Selection Pressure**: Limited resources drive competition
- **Fitness Landscapes**: Different environments favor different traits
- **r/K Selection**: Fast breeding vs. sustainable growth strategies

You're watching the same processes that shaped life on Earth, just on a much faster timescale!
