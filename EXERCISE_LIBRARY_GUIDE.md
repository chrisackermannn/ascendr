# Exercise Library Guide

## Overview

The exercise library contains **200+ exercises** organized by category, muscle groups, and equipment. The library is stored in `ExerciseLibrary.swift` and can be easily edited and expanded.

## Current Exercise Count

- **Chest**: 20 exercises
- **Back**: 30 exercises
- **Shoulders**: 19 exercises
- **Arms (Biceps)**: 12 exercises
- **Arms (Triceps)**: 13 exercises
- **Arms (Forearms)**: 4 exercises
- **Legs (Quadriceps)**: 15 exercises
- **Legs (Hamstrings)**: 8 exercises
- **Legs (Glutes)**: 7 exercises
- **Legs (Calves)**: 6 exercises
- **Core**: 19 exercises
- **Cardio**: 12 exercises
- **Full Body**: 8 exercises

**Total: 173+ exercises**

## Exercise Data Structure

Each exercise includes:
- **Name**: Full exercise name
- **Category**: Primary category (Chest, Back, Shoulders, etc.)
- **Muscle Groups**: Array of muscles targeted
- **Equipment**: Required equipment type
- **GIF URL**: Optional URL to exercise demonstration GIF
- **Instructions**: Optional text instructions

## Adding Exercise GIFs

### Option 1: Use ExerciseDB API (Recommended)

The ExerciseDB API provides free exercise GIFs:
- Base URL: `https://api.exercisedb.io/image/`
- Format: `https://api.exercisedb.io/image/{exercise-name}`

Example:
```swift
ExerciseItem(
    name: "Push-ups",
    category: .chest,
    muscleGroups: [.pectorals, .anteriorDeltoids, .triceps],
    equipment: .bodyweight,
    gifURL: "https://api.exercisedb.io/image/push-up"
)
```

### Option 2: Use Custom GIF URLs

You can add any GIF URL from:
- Your own server
- GIPHY (with proper attribution)
- Other exercise databases

Example:
```swift
ExerciseItem(
    name: "Bench Press",
    category: .chest,
    muscleGroups: [.pectorals, .anteriorDeltoids, .triceps],
    equipment: .barbell,
    gifURL: "https://your-server.com/exercises/bench-press.gif"
)
```

### Option 3: Local Assets

For local GIFs, you can:
1. Add GIF files to your Xcode project
2. Reference them as: `gifURL: "bench-press"` (without extension)
3. Load them using `Bundle.main.path(forResource:ofType:)`

## How to Edit the Exercise Library

1. Open `Ascendr/Ascendr/Models/ExerciseLibrary.swift`
2. Find the `createExerciseDatabase()` function
3. Add new exercises to the array:

```swift
ExerciseItem(
    name: "Your Exercise Name",
    category: .chest,  // Choose from ExerciseCategory enum
    muscleGroups: [.pectorals, .anteriorDeltoids],  // Array of MuscleGroup
    equipment: .barbell,  // Choose from Equipment enum
    gifURL: "https://api.exercisedb.io/image/your-exercise",  // Optional
    instructions: "Optional instructions text"  // Optional
)
```

## Search Functionality

The exercise picker supports searching by:
- Exercise name
- Category
- Muscle group
- Equipment type

Users can:
- Type in the search bar to filter exercises
- Tap category chips to filter by category
- Combine search text with category filters

## Exercise Categories

- **Chest**: Pectoral-focused exercises
- **Back**: Lat, rhomboid, and erector spinae exercises
- **Shoulders**: Deltoid exercises
- **Arms**: Biceps, triceps, and forearm exercises
- **Legs**: Quadriceps, hamstrings, glutes, and calves
- **Core**: Abdominal and oblique exercises
- **Cardio**: Cardiovascular exercises
- **Full Body**: Multi-muscle group exercises
- **Other**: Miscellaneous exercises

## Muscle Groups

The library tracks these muscle groups:
- Pectorals, Anterior/Lateral/Posterior Deltoids
- Trapezius, Latissimus Dorsi, Rhomboids, Erector Spinae
- Biceps, Triceps, Forearms
- Quadriceps, Hamstrings, Glutes, Calves
- Abdominals, Obliques

## Equipment Types

- **Bodyweight**: No equipment needed
- **Barbell**: Barbell exercises
- **Dumbbell**: Dumbbell exercises
- **Machine**: Gym machines
- **Cable**: Cable machine exercises
- **Smith Machine**: Smith machine exercises
- **Kettlebell**: Kettlebell exercises
- **Resistance Band**: Resistance band exercises
- **Other**: Miscellaneous equipment

## Tips for Adding GIFs

1. **ExerciseDB API**: Most exercises can use the ExerciseDB format
   - Convert exercise name to lowercase
   - Replace spaces with hyphens
   - Example: "Bench Press" → "bench-press"

2. **GIF Quality**: Use high-quality GIFs (at least 200x200px)

3. **Loading States**: The UI automatically shows a placeholder while loading

4. **Fallback**: If GIF fails to load, a default icon is shown

## Future Enhancements

Potential additions:
- Exercise instructions/descriptions
- Difficulty levels
- Recommended sets/reps
- Common variations
- Alternative names
- Video links
- Muscle group diagrams

## Notes

- The exercise library is loaded once at app startup
- All exercises are stored in memory for fast searching
- The library can be easily extended with new exercises
- GIF URLs are optional - exercises work fine without them

