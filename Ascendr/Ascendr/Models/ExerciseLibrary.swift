//
//  ExerciseLibrary.swift
//  Ascendr
//
//  Comprehensive exercise library with categories and GIF support
//

import Foundation

struct ExerciseItem: Identifiable, Codable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let muscleGroups: [MuscleGroup]
    let equipment: Equipment
    let gifURL: String?
    let instructions: String?
    
    init(id: String = UUID().uuidString, name: String, category: ExerciseCategory, muscleGroups: [MuscleGroup], equipment: Equipment, gifURL: String? = nil, instructions: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.gifURL = gifURL
        self.instructions = instructions
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case arms = "Arms"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case other = "Other"
}

enum MuscleGroup: String, Codable, CaseIterable {
    case pectorals = "Pectorals"
    case anteriorDeltoids = "Anterior Deltoids"
    case lateralDeltoids = "Lateral Deltoids"
    case posteriorDeltoids = "Posterior Deltoids"
    case trapezius = "Trapezius"
    case latissimusDorsi = "Latissimus Dorsi"
    case rhomboids = "Rhomboids"
    case erectorSpinae = "Erector Spinae"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case forearms = "Forearms"
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case abdominals = "Abdominals"
    case obliques = "Obliques"
}

enum Equipment: String, Codable, CaseIterable {
    case bodyweight = "Bodyweight"
    case barbell = "Barbell"
    case dumbbell = "Dumbbell"
    case machine = "Machine"
    case cable = "Cable"
    case smithMachine = "Smith Machine"
    case kettlebell = "Kettlebell"
    case resistanceBand = "Resistance Band"
    case other = "Other"
}

class ExerciseLibrary {
    static let shared = ExerciseLibrary()
    
    let exercises: [ExerciseItem]
    
    private init() {
        self.exercises = ExerciseLibrary.createExerciseDatabase()
    }
    
    static func createExerciseDatabase() -> [ExerciseItem] {
        return [
            // CHEST EXERCISES
            ExerciseItem(name: "Flat Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Incline Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Decline Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .barbell),
            ExerciseItem(name: "Flat Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Incline Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Decline Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Flat Smith Machine Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .smithMachine),
            ExerciseItem(name: "Incline Smith Machine Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .smithMachine),
            ExerciseItem(name: "Dumbbell Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .dumbbell),
            ExerciseItem(name: "Incline Dumbbell Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .dumbbell),
            ExerciseItem(name: "Cable Crossover", category: .chest, muscleGroups: [.pectorals], equipment: .cable),
            ExerciseItem(name: "Cable Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .cable),
            ExerciseItem(name: "Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/push-up"),
            ExerciseItem(name: "Incline Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/incline-push-up"),
            ExerciseItem(name: "Decline Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/decline-push-up"),
            ExerciseItem(name: "Diamond Push-ups", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/diamond-push-up"),
            ExerciseItem(name: "Wide Grip Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids], equipment: .bodyweight),
            ExerciseItem(name: "Pec Deck Machine", category: .chest, muscleGroups: [.pectorals], equipment: .machine),
            ExerciseItem(name: "Chest Press Machine", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine),
            ExerciseItem(name: "Dips", category: .chest, muscleGroups: [.pectorals, .triceps, .anteriorDeltoids], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Dips", category: .chest, muscleGroups: [.pectorals, .triceps, .anteriorDeltoids], equipment: .bodyweight),
            
            // BACK EXERCISES
            ExerciseItem(name: "Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/pull-up"),
            ExerciseItem(name: "Chin-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/chin-up"),
            ExerciseItem(name: "Wide Grip Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .bodyweight),
            ExerciseItem(name: "Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .machine),
            ExerciseItem(name: "Wide Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .machine),
            ExerciseItem(name: "Close Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .machine),
            ExerciseItem(name: "Reverse Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .machine),
            ExerciseItem(name: "Cable Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable),
            ExerciseItem(name: "Barbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell),
            ExerciseItem(name: "Bent Over Barbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell),
            ExerciseItem(name: "T-Bar Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell),
            ExerciseItem(name: "One-Arm Dumbbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell),
            ExerciseItem(name: "Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .cable),
            ExerciseItem(name: "Seated Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .cable),
            ExerciseItem(name: "Wide Grip Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .cable),
            ExerciseItem(name: "Close Grip Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable),
            ExerciseItem(name: "Cable Pullover", category: .back, muscleGroups: [.latissimusDorsi], equipment: .cable),
            ExerciseItem(name: "Dumbbell Pullover", category: .back, muscleGroups: [.latissimusDorsi, .pectorals], equipment: .dumbbell),
            ExerciseItem(name: "Hyperextensions", category: .back, muscleGroups: [.erectorSpinae, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Hyperextensions", category: .back, muscleGroups: [.erectorSpinae, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Good Mornings", category: .back, muscleGroups: [.erectorSpinae, .hamstrings], equipment: .barbell),
            ExerciseItem(name: "Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings, .trapezius], equipment: .barbell),
            ExerciseItem(name: "Romanian Deadlift", category: .back, muscleGroups: [.erectorSpinae, .hamstrings, .glutes], equipment: .barbell),
            ExerciseItem(name: "Sumo Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings], equipment: .dumbbell),
            ExerciseItem(name: "Shrugs", category: .back, muscleGroups: [.trapezius], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Shrugs", category: .back, muscleGroups: [.trapezius], equipment: .dumbbell),
            ExerciseItem(name: "Face Pulls", category: .back, muscleGroups: [.posteriorDeltoids, .rhomboids], equipment: .cable),
            
            // SHOULDER EXERCISES
            ExerciseItem(name: "Overhead Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Military Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Seated Overhead Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Shoulder Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Seated Dumbbell Shoulder Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Arnold Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Lateral Raises", category: .shoulders, muscleGroups: [.lateralDeltoids], equipment: .dumbbell),
            ExerciseItem(name: "Cable Lateral Raises", category: .shoulders, muscleGroups: [.lateralDeltoids], equipment: .cable),
            ExerciseItem(name: "Front Raises", category: .shoulders, muscleGroups: [.anteriorDeltoids], equipment: .dumbbell),
            ExerciseItem(name: "Cable Front Raises", category: .shoulders, muscleGroups: [.anteriorDeltoids], equipment: .cable),
            ExerciseItem(name: "Rear Delt Flyes", category: .shoulders, muscleGroups: [.posteriorDeltoids], equipment: .dumbbell),
            ExerciseItem(name: "Cable Rear Delt Flyes", category: .shoulders, muscleGroups: [.posteriorDeltoids], equipment: .cable),
            ExerciseItem(name: "Bent Over Lateral Raises", category: .shoulders, muscleGroups: [.posteriorDeltoids], equipment: .dumbbell),
            ExerciseItem(name: "Upright Row", category: .shoulders, muscleGroups: [.lateralDeltoids, .trapezius], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Upright Row", category: .shoulders, muscleGroups: [.lateralDeltoids, .trapezius], equipment: .dumbbell),
            ExerciseItem(name: "Cable Upright Row", category: .shoulders, muscleGroups: [.lateralDeltoids, .trapezius], equipment: .cable),
            ExerciseItem(name: "Pike Push-ups", category: .shoulders, muscleGroups: [.anteriorDeltoids, .triceps], equipment: .bodyweight),
            ExerciseItem(name: "Handstand Push-ups", category: .shoulders, muscleGroups: [.anteriorDeltoids, .triceps], equipment: .bodyweight),
            ExerciseItem(name: "Shoulder Press Machine", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .machine),
            
            // ARM EXERCISES - BICEPS
            ExerciseItem(name: "Barbell Curl", category: .arms, muscleGroups: [.biceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Curl", category: .arms, muscleGroups: [.biceps], equipment: .dumbbell),
            ExerciseItem(name: "Hammer Curl", category: .arms, muscleGroups: [.biceps, .forearms], equipment: .dumbbell),
            ExerciseItem(name: "Cable Curl", category: .arms, muscleGroups: [.biceps], equipment: .cable),
            ExerciseItem(name: "Preacher Curl", category: .arms, muscleGroups: [.biceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Preacher Curl", category: .arms, muscleGroups: [.biceps], equipment: .dumbbell),
            ExerciseItem(name: "Concentration Curl", category: .arms, muscleGroups: [.biceps], equipment: .dumbbell),
            ExerciseItem(name: "Incline Dumbbell Curl", category: .arms, muscleGroups: [.biceps], equipment: .dumbbell),
            ExerciseItem(name: "Cable Hammer Curl", category: .arms, muscleGroups: [.biceps, .forearms], equipment: .cable),
            ExerciseItem(name: "21s", category: .arms, muscleGroups: [.biceps], equipment: .barbell),
            ExerciseItem(name: "Spider Curl", category: .arms, muscleGroups: [.biceps], equipment: .barbell),
            ExerciseItem(name: "Cable Rope Curl", category: .arms, muscleGroups: [.biceps], equipment: .cable),
            
            // ARM EXERCISES - TRICEPS
            ExerciseItem(name: "Close Grip Bench Press", category: .arms, muscleGroups: [.triceps, .pectorals], equipment: .barbell),
            ExerciseItem(name: "Overhead Tricep Extension", category: .arms, muscleGroups: [.triceps], equipment: .dumbbell),
            ExerciseItem(name: "Cable Overhead Tricep Extension", category: .arms, muscleGroups: [.triceps], equipment: .cable),
            ExerciseItem(name: "Tricep Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable),
            ExerciseItem(name: "Cable Rope Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable),
            ExerciseItem(name: "Overhead Cable Extension", category: .arms, muscleGroups: [.triceps], equipment: .cable),
            ExerciseItem(name: "Tricep Dips", category: .arms, muscleGroups: [.triceps, .anteriorDeltoids], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Tricep Dips", category: .arms, muscleGroups: [.triceps, .anteriorDeltoids], equipment: .bodyweight),
            ExerciseItem(name: "Diamond Push-ups", category: .arms, muscleGroups: [.triceps, .pectorals], equipment: .bodyweight),
            ExerciseItem(name: "Tricep Kickback", category: .arms, muscleGroups: [.triceps], equipment: .dumbbell),
            ExerciseItem(name: "Cable Tricep Kickback", category: .arms, muscleGroups: [.triceps], equipment: .cable),
            ExerciseItem(name: "Skull Crushers", category: .arms, muscleGroups: [.triceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Skull Crushers", category: .arms, muscleGroups: [.triceps], equipment: .dumbbell),
            ExerciseItem(name: "French Press", category: .arms, muscleGroups: [.triceps], equipment: .barbell),
            
            // ARM EXERCISES - FOREARMS
            ExerciseItem(name: "Wrist Curl", category: .arms, muscleGroups: [.forearms], equipment: .barbell),
            ExerciseItem(name: "Reverse Wrist Curl", category: .arms, muscleGroups: [.forearms], equipment: .barbell),
            ExerciseItem(name: "Farmer's Walk", category: .arms, muscleGroups: [.forearms, .trapezius], equipment: .dumbbell),
            ExerciseItem(name: "Hammer Curl", category: .arms, muscleGroups: [.forearms, .biceps], equipment: .dumbbell),
            
            // LEG EXERCISES - QUADRICEPS
            ExerciseItem(name: "Barbell Squat", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .barbell, gifURL: "https://api.exercisedb.io/image/barbell-squat"),
            ExerciseItem(name: "Front Squat", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .barbell, gifURL: "https://api.exercisedb.io/image/front-squat"),
            ExerciseItem(name: "Smith Machine Squat", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .smithMachine),
            ExerciseItem(name: "Goblet Squat", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Bulgarian Split Squat", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Leg Press", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .machine),
            ExerciseItem(name: "Leg Extension", category: .legs, muscleGroups: [.quadriceps], equipment: .machine),
            ExerciseItem(name: "Walking Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Walking Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Reverse Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Reverse Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Lateral Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Jump Squats", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Pistol Squat", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .bodyweight),
            ExerciseItem(name: "Wall Sit", category: .legs, muscleGroups: [.quadriceps], equipment: .bodyweight),
            
            // LEG EXERCISES - HAMSTRINGS
            ExerciseItem(name: "Romanian Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes, .erectorSpinae], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Romanian Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Leg Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .machine),
            ExerciseItem(name: "Lying Leg Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .machine),
            ExerciseItem(name: "Seated Leg Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .machine),
            ExerciseItem(name: "Stiff Leg Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes, .erectorSpinae], equipment: .barbell),
            ExerciseItem(name: "Good Mornings", category: .legs, muscleGroups: [.hamstrings, .glutes, .erectorSpinae], equipment: .barbell),
            ExerciseItem(name: "Nordic Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .bodyweight),
            
            // LEG EXERCISES - GLUTES
            ExerciseItem(name: "Hip Thrust", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .barbell),
            ExerciseItem(name: "Barbell Hip Thrust", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .barbell),
            ExerciseItem(name: "Glute Bridge", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Glute Bridge", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .barbell),
            ExerciseItem(name: "Single Leg Glute Bridge", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .bodyweight),
            ExerciseItem(name: "Cable Hip Abduction", category: .legs, muscleGroups: [.glutes], equipment: .cable),
            ExerciseItem(name: "Clamshells", category: .legs, muscleGroups: [.glutes], equipment: .bodyweight),
            
            // LEG EXERCISES - CALVES
            ExerciseItem(name: "Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .bodyweight),
            ExerciseItem(name: "Standing Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .machine),
            ExerciseItem(name: "Seated Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .machine),
            ExerciseItem(name: "Dumbbell Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .dumbbell),
            ExerciseItem(name: "Barbell Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .barbell),
            ExerciseItem(name: "Single Leg Calf Raise", category: .legs, muscleGroups: [.calves], equipment: .bodyweight),
            
            // CORE EXERCISES
            ExerciseItem(name: "Crunches", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Sit-ups", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Plank", category: .core, muscleGroups: [.abdominals, .obliques], equipment: .bodyweight),
            ExerciseItem(name: "Side Plank", category: .core, muscleGroups: [.obliques], equipment: .bodyweight),
            ExerciseItem(name: "Russian Twist", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Weighted Russian Twist", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .dumbbell),
            ExerciseItem(name: "Leg Raises", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Hanging Leg Raises", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Bicycle Crunches", category: .core, muscleGroups: [.abdominals, .obliques], equipment: .bodyweight),
            ExerciseItem(name: "Mountain Climbers", category: .core, muscleGroups: [.abdominals, .obliques], equipment: .bodyweight),
            ExerciseItem(name: "Dead Bug", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Bird Dog", category: .core, muscleGroups: [.abdominals, .erectorSpinae], equipment: .bodyweight),
            ExerciseItem(name: "Ab Wheel Rollout", category: .core, muscleGroups: [.abdominals], equipment: .other),
            ExerciseItem(name: "Cable Crunch", category: .core, muscleGroups: [.abdominals], equipment: .cable),
            ExerciseItem(name: "Woodchoppers", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .cable),
            ExerciseItem(name: "Reverse Crunch", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "V-Ups", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "Flutter Kicks", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            ExerciseItem(name: "L-Sit", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight),
            
            // CARDIO EXERCISES
            ExerciseItem(name: "Running", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .calves], equipment: .bodyweight),
            ExerciseItem(name: "Treadmill Running", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .calves], equipment: .machine),
            ExerciseItem(name: "Sprinting", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .calves], equipment: .bodyweight),
            ExerciseItem(name: "Cycling", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .calves], equipment: .machine),
            ExerciseItem(name: "Rowing", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .latissimusDorsi], equipment: .machine),
            ExerciseItem(name: "Elliptical", category: .cardio, muscleGroups: [.quadriceps, .hamstrings, .glutes], equipment: .machine),
            ExerciseItem(name: "Stair Climber", category: .cardio, muscleGroups: [.quadriceps, .glutes, .calves], equipment: .machine),
            ExerciseItem(name: "Jump Rope", category: .cardio, muscleGroups: [.calves, .quadriceps], equipment: .other),
            ExerciseItem(name: "Burpees", category: .cardio, muscleGroups: [.quadriceps, .glutes, .pectorals], equipment: .bodyweight),
            ExerciseItem(name: "High Knees", category: .cardio, muscleGroups: [.quadriceps, .calves], equipment: .bodyweight),
            ExerciseItem(name: "Jumping Jacks", category: .cardio, muscleGroups: [.quadriceps, .calves], equipment: .bodyweight),
            ExerciseItem(name: "Box Jumps", category: .cardio, muscleGroups: [.quadriceps, .glutes, .calves], equipment: .bodyweight),
            
            // FULL BODY EXERCISES
            ExerciseItem(name: "Thruster", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .anteriorDeltoids, .triceps], equipment: .barbell),
            ExerciseItem(name: "Dumbbell Thruster", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .anteriorDeltoids, .triceps], equipment: .dumbbell),
            ExerciseItem(name: "Clean and Press", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .anteriorDeltoids, .trapezius], equipment: .barbell),
            ExerciseItem(name: "Snatch", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .anteriorDeltoids, .trapezius], equipment: .barbell),
            ExerciseItem(name: "Kettlebell Swing", category: .fullBody, muscleGroups: [.glutes, .hamstrings, .quadriceps, .anteriorDeltoids], equipment: .kettlebell),
            ExerciseItem(name: "Turkish Get-Up", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .anteriorDeltoids, .abdominals], equipment: .kettlebell),
            ExerciseItem(name: "Man Makers", category: .fullBody, muscleGroups: [.pectorals, .triceps, .quadriceps, .glutes], equipment: .dumbbell),
            ExerciseItem(name: "Bear Crawl", category: .fullBody, muscleGroups: [.quadriceps, .anteriorDeltoids, .abdominals], equipment: .bodyweight),
        ]
    }
    
    func searchExercises(query: String) -> [ExerciseItem] {
        let lowercasedQuery = query.lowercased()
        return exercises.filter { exercise in
            exercise.name.lowercased().contains(lowercasedQuery) ||
            exercise.category.rawValue.lowercased().contains(lowercasedQuery) ||
            exercise.muscleGroups.contains { $0.rawValue.lowercased().contains(lowercasedQuery) } ||
            exercise.equipment.rawValue.lowercased().contains(lowercasedQuery)
        }
    }
    
    func exercisesByCategory(_ category: ExerciseCategory) -> [ExerciseItem] {
        return exercises.filter { $0.category == category }
    }
    
    func exercisesByMuscleGroup(_ muscleGroup: MuscleGroup) -> [ExerciseItem] {
        return exercises.filter { $0.muscleGroups.contains(muscleGroup) }
    }
}

