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
            ExerciseItem(name: "Flat Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .barbell, instructions: "Lie on bench, grip bar slightly wider than shoulders. Lower bar to chest with control, press up explosively. Keep feet flat, core tight, and maintain arch in back."),
            ExerciseItem(name: "Incline Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .barbell, instructions: "Set bench to 30-45° incline. Grip bar slightly wider than shoulders. Lower to upper chest, press up. Focus on upper pec contraction."),
            ExerciseItem(name: "Decline Barbell Bench Press", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .barbell, instructions: "Set bench to decline position. Secure feet in straps. Lower bar to lower chest, press up. Targets lower pecs."),
            ExerciseItem(name: "Flat Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell, instructions: "Lie on flat bench, hold dumbbells at chest level. Press up until arms extended, lower with control. Allows greater range of motion than barbell."),
            ExerciseItem(name: "Incline Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell, instructions: "Set bench to 30-45° incline. Press dumbbells up and slightly together at top. Lower to upper chest level."),
            ExerciseItem(name: "Decline Dumbbell Bench Press", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .dumbbell, instructions: "Set bench to decline. Secure feet. Press dumbbells from lower chest position upward."),
            ExerciseItem(name: "Flat Smith Machine Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .smithMachine, instructions: "Use Smith machine for guided movement. Lower bar to chest, press up. Safer for solo training."),
            ExerciseItem(name: "Incline Smith Machine Bench Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .smithMachine, instructions: "Set bench to incline in Smith machine. Press bar from upper chest position."),
            ExerciseItem(name: "Dumbbell Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .dumbbell, instructions: "Lie on bench, arms extended with slight bend. Lower dumbbells in wide arc until chest stretch. Bring together in hugging motion."),
            ExerciseItem(name: "Incline Dumbbell Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .dumbbell, instructions: "Set bench to incline. Perform flyes focusing on upper chest stretch and contraction."),
            ExerciseItem(name: "Cable Crossover", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cables to high position. Step forward, pull handles together in front of chest. Squeeze pecs at bottom."),
            ExerciseItem(name: "Cable Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cables at chest height. Stand between, pull handles together in front. Constant tension throughout movement."),
            ExerciseItem(name: "Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/push-up", instructions: "Start in plank position, hands slightly wider than shoulders. Lower body until chest nearly touches ground. Push up explosively. Keep core tight, body straight."),
            ExerciseItem(name: "Incline Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/incline-push-up", instructions: "Place hands on elevated surface (bench/box). Easier variation, great for beginners. Focus on full range of motion."),
            ExerciseItem(name: "Decline Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/decline-push-up", instructions: "Place feet on elevated surface. More challenging, targets upper chest. Keep body straight throughout."),
            ExerciseItem(name: "Diamond Push-ups", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/diamond-push-up", instructions: "Form diamond with hands under chest. Targets triceps and inner chest. Keep elbows close to body."),
            ExerciseItem(name: "Wide Grip Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids], equipment: .bodyweight, instructions: "Hands wider than shoulder width. Emphasizes chest over triceps. Lower until chest stretch."),
            ExerciseItem(name: "Pec Deck Machine", category: .chest, muscleGroups: [.pectorals], equipment: .machine, instructions: "Sit in machine, adjust seat height. Push handles together. Isolates chest muscles effectively."),
            ExerciseItem(name: "Chest Press Machine", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Sit in machine, adjust seat. Press handles forward until arms extended. Return with control."),
            ExerciseItem(name: "Dips", category: .chest, muscleGroups: [.pectorals, .triceps, .anteriorDeltoids], equipment: .bodyweight, instructions: "Grip parallel bars, support body weight. Lower by bending arms, lean slightly forward for chest emphasis. Push up to start."),
            ExerciseItem(name: "Weighted Dips", category: .chest, muscleGroups: [.pectorals, .triceps, .anteriorDeltoids], equipment: .bodyweight, instructions: "Add weight via dip belt or weighted vest. Same form as bodyweight dips but with added resistance."),
            ExerciseItem(name: "Chest Dips", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .bodyweight, instructions: "Lean forward more than standard dips. Targets chest primarily. Lower until shoulders below elbows."),
            ExerciseItem(name: "Pike Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids], equipment: .bodyweight, instructions: "Start in downward dog position. Lower head toward ground, push back up. Targets shoulders and upper chest."),
            ExerciseItem(name: "Archer Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids], equipment: .bodyweight, instructions: "Wide hand placement. Shift weight to one side, lower that side more. Alternate sides. Advanced variation."),
            ExerciseItem(name: "Hindu Push-ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, instructions: "Start in downward dog, lower into upward dog position, push back. Dynamic movement pattern."),
            ExerciseItem(name: "Resistance Band Chest Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .resistanceBand, instructions: "Anchor band behind you at chest height. Hold handles, press forward. Great for home workouts."),
            ExerciseItem(name: "Resistance Band Flyes", category: .chest, muscleGroups: [.pectorals], equipment: .resistanceBand, instructions: "Anchor band behind you. Hold handles, perform flye motion. Constant tension throughout."),
            
            // CHEST - ADDITIONAL MACHINES
            ExerciseItem(name: "Incline Chest Press Machine", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Sit in incline chest press machine. Adjust seat to 30-45° incline. Press handles forward until arms extended. Targets upper chest."),
            ExerciseItem(name: "Decline Chest Press Machine", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .machine, instructions: "Sit in decline chest press machine. Press handles forward. Targets lower pecs effectively."),
            ExerciseItem(name: "Seated Chest Fly Machine", category: .chest, muscleGroups: [.pectorals], equipment: .machine, instructions: "Sit in chest fly machine. Adjust seat height. Bring handles together in front of chest. Squeeze pecs at peak contraction."),
            ExerciseItem(name: "Plate-Loaded Chest Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Use plate-loaded chest press machine. Load plates, sit and press handles forward. Allows for heavy loading."),
            ExerciseItem(name: "Iso-Lateral Chest Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Use iso-lateral chest press machine. Each arm works independently. Press handles forward one at a time or together."),
            ExerciseItem(name: "Machine Incline Fly", category: .chest, muscleGroups: [.pectorals], equipment: .machine, instructions: "Use incline fly machine. Set to 30-45° incline. Bring handles together focusing on upper chest."),
            ExerciseItem(name: "Cable Fly Machine with Handles", category: .chest, muscleGroups: [.pectorals], equipment: .machine, instructions: "Use cable fly machine with handles. Adjust cable height. Pull handles together in front of chest."),
            ExerciseItem(name: "Chest Press Hammer Strength", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Use Hammer Strength chest press. Plate-loaded, unilateral movement. Press handles forward with controlled motion."),
            ExerciseItem(name: "Vertical Chest Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .machine, instructions: "Use vertical chest press machine. Press handles forward in vertical plane. Unique angle for chest development."),
            
            // CHEST - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Chest Fly (High → Low)", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cables to high position. Step forward, pull handles down and together in front of lower chest. Targets lower pecs."),
            ExerciseItem(name: "Cable Chest Fly (Low → High)", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cables to low position. Pull handles up and together in front of upper chest. Targets upper pecs."),
            ExerciseItem(name: "Cable Chest Fly (Mid-level)", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cables at chest height. Stand between, pull handles together in front. Constant tension throughout movement."),
            ExerciseItem(name: "Cable Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .cable, instructions: "Set cables at chest height. Press handles forward. Constant tension provides unique stimulus."),
            ExerciseItem(name: "Single-Arm Cable Crossover", category: .chest, muscleGroups: [.pectorals], equipment: .cable, instructions: "Set cable to high position. Use one arm at a time. Pull handle across body. Allows for unilateral focus."),
            ExerciseItem(name: "Cable Decline Press", category: .chest, muscleGroups: [.pectorals, .triceps], equipment: .cable, instructions: "Set cables low, lie on decline bench. Press handles up and together. Targets lower chest."),
            ExerciseItem(name: "Cable Incline Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .cable, instructions: "Set cables low, lie on incline bench. Press handles up and together. Targets upper chest."),
            ExerciseItem(name: "Cable Pullover", category: .chest, muscleGroups: [.pectorals, .latissimusDorsi], equipment: .cable, instructions: "Set cable high. Kneel or stand, pull handle down and forward in arc. Targets chest and lats."),
            
            // CHEST - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "Dumbbell Chest Press", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell, instructions: "Lie on bench, hold dumbbells at chest level. Press up until arms extended, lower with control. Allows greater range of motion."),
            ExerciseItem(name: "Iso-Dumbbell Press (Alternating)", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .dumbbell, instructions: "Lie on bench, press one dumbbell at a time. Alternate arms. Unilateral focus improves muscle imbalances."),
            ExerciseItem(name: "Single-Arm Dumbbell Fly", category: .chest, muscleGroups: [.pectorals], equipment: .dumbbell, instructions: "Lie on bench, perform flye with one arm at a time. Unilateral movement for muscle balance."),
            ExerciseItem(name: "Weighted Push-Ups", category: .chest, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .bodyweight, instructions: "Perform push-ups with weight plate on back or weighted vest. Increases resistance for progressive overload."),
            
            // BACK EXERCISES
            ExerciseItem(name: "Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/pull-up", instructions: "Hang from bar with overhand grip, hands wider than shoulders. Pull body up until chin clears bar. Lower with control. Keep core tight, avoid swinging."),
            ExerciseItem(name: "Chin-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .bodyweight, gifURL: "https://api.exercisedb.io/image/chin-up", instructions: "Hang from bar with underhand grip, hands shoulder-width. Pull up until chin over bar. Emphasizes biceps more than pull-ups."),
            ExerciseItem(name: "Wide Grip Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .bodyweight, instructions: "Grip bar wider than shoulder width. Pull up focusing on lats. Wider grip targets upper lats and rhomboids."),
            ExerciseItem(name: "Weighted Pull-ups", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .bodyweight, instructions: "Add weight via dip belt or weighted vest. Same form as bodyweight pull-ups but with added resistance."),
            ExerciseItem(name: "Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .machine, instructions: "Sit at lat pulldown machine, grip bar wider than shoulders. Pull bar to upper chest, squeeze lats. Return with control."),
            ExerciseItem(name: "Wide Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .machine, instructions: "Wider grip on lat pulldown. Pull to upper chest, focus on lat contraction. Targets upper lats."),
            ExerciseItem(name: "Close Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .machine, instructions: "Close grip on lat pulldown. Pull to lower chest. Emphasizes lower lats and biceps."),
            ExerciseItem(name: "Reverse Grip Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .machine, instructions: "Underhand grip on lat pulldown. Pull to lower chest. Targets lower lats and biceps effectively."),
            ExerciseItem(name: "Cable Lat Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable, instructions: "Use cable machine with high pulley. Pull handle down to chest level. Constant tension throughout."),
            ExerciseItem(name: "Barbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "Bend over, grip bar slightly wider than shoulders. Pull bar to lower chest/upper abs. Keep back straight, core engaged."),
            ExerciseItem(name: "Bent Over Barbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "Bend knees slightly, hinge at hips. Pull bar to lower chest. Maintain neutral spine throughout movement."),
            ExerciseItem(name: "T-Bar Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "Straddle T-bar, grip handles. Pull weight to chest. Great for mid-back development."),
            ExerciseItem(name: "Dumbbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell, instructions: "Bend over, support on bench. Pull dumbbell to hip/ribs. Squeeze back muscles at top."),
            ExerciseItem(name: "One-Arm Dumbbell Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell, instructions: "Support on bench with one hand/knee. Row dumbbell with other arm. Allows greater range of motion."),
            ExerciseItem(name: "Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .cable, instructions: "Sit at cable row machine. Pull handles to lower chest. Squeeze shoulder blades together."),
            ExerciseItem(name: "Seated Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .cable, instructions: "Sit with feet on platform. Pull cable handle to lower chest. Keep torso upright, squeeze lats."),
            ExerciseItem(name: "Wide Grip Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .cable, instructions: "Wide grip on cable row. Pull to upper chest. Targets upper back and rhomboids."),
            ExerciseItem(name: "Close Grip Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable, instructions: "Close grip on cable row. Pull to lower chest. Emphasizes lower lats and biceps."),
            ExerciseItem(name: "Cable Pullover", category: .back, muscleGroups: [.latissimusDorsi], equipment: .cable, instructions: "Set cable high. Pull handle down and forward in arc motion. Isolates lats effectively."),
            ExerciseItem(name: "Dumbbell Pullover", category: .back, muscleGroups: [.latissimusDorsi, .pectorals], equipment: .dumbbell, instructions: "Lie on bench, hold dumbbell over chest. Lower behind head, pull back up. Targets lats and serratus."),
            ExerciseItem(name: "Hyperextensions", category: .back, muscleGroups: [.erectorSpinae, .glutes], equipment: .bodyweight, instructions: "Lie face down on hyperextension bench. Lower torso, raise back up. Strengthens lower back."),
            ExerciseItem(name: "Weighted Hyperextensions", category: .back, muscleGroups: [.erectorSpinae, .glutes], equipment: .bodyweight, instructions: "Add weight plate to chest. Perform hyperextensions with added resistance."),
            ExerciseItem(name: "Good Mornings", category: .back, muscleGroups: [.erectorSpinae, .hamstrings], equipment: .barbell, instructions: "Bar on upper back. Hinge at hips, lower torso forward. Keep back straight. Return to start."),
            ExerciseItem(name: "Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings, .trapezius], equipment: .barbell, instructions: "Stand with feet hip-width, bar over mid-foot. Hinge at hips, grip bar. Drive through heels, stand up. Keep back straight, bar close to body."),
            ExerciseItem(name: "Romanian Deadlift", category: .back, muscleGroups: [.erectorSpinae, .hamstrings, .glutes], equipment: .barbell, instructions: "Start standing, bar at hip level. Hinge at hips, lower bar while keeping legs mostly straight. Feel hamstring stretch. Return to start."),
            ExerciseItem(name: "Sumo Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings], equipment: .barbell, instructions: "Wide stance, toes pointed out. Grip bar inside legs. Lift with emphasis on quads and glutes. Shorter range of motion."),
            ExerciseItem(name: "Dumbbell Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings], equipment: .dumbbell, instructions: "Hold dumbbells at sides. Hinge at hips, lower dumbbells. Stand up. Great for beginners."),
            ExerciseItem(name: "Shrugs", category: .back, muscleGroups: [.trapezius], equipment: .barbell, instructions: "Hold bar at waist level. Lift shoulders straight up. Hold briefly, lower. Isolates upper traps."),
            ExerciseItem(name: "Dumbbell Shrugs", category: .back, muscleGroups: [.trapezius], equipment: .dumbbell, instructions: "Hold dumbbells at sides. Shrug shoulders up. Allows greater range of motion than barbell."),
            ExerciseItem(name: "Face Pulls", category: .back, muscleGroups: [.posteriorDeltoids, .rhomboids], equipment: .cable, instructions: "Set cable at face height. Pull rope to face, separate handles. Targets rear delts and upper back. Essential for shoulder health."),
            ExerciseItem(name: "Inverted Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .bodyweight, instructions: "Lie under bar set at waist height. Pull body up to bar. Great bodyweight back exercise."),
            ExerciseItem(name: "Resistance Band Pull-Apart", category: .back, muscleGroups: [.rhomboids, .posteriorDeltoids], equipment: .resistanceBand, instructions: "Hold band with arms extended. Pull apart, squeeze shoulder blades. Excellent for posture."),
            ExerciseItem(name: "Chest Supported Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell, instructions: "Lie face down on incline bench. Row dumbbells to sides. Eliminates lower back stress."),
            ExerciseItem(name: "Landmine Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "One end of bar in corner. Row other end. Unique angle targets back effectively."),
            
            // BACK - ADDITIONAL MACHINES
            ExerciseItem(name: "Seated Row Machine", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .machine, instructions: "Sit at seated row machine. Pull handles to lower chest. Squeeze shoulder blades together at peak contraction."),
            ExerciseItem(name: "Iso-Lateral Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .machine, instructions: "Use iso-lateral row machine. Each arm works independently. Row handles one at a time or together."),
            ExerciseItem(name: "Hammer Strength High Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .machine, instructions: "Use Hammer Strength high row machine. Pull handles to upper chest. Targets upper back and rhomboids."),
            ExerciseItem(name: "Hammer Strength Low Row", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .machine, instructions: "Use Hammer Strength low row machine. Pull handles to lower chest. Targets lower lats and biceps."),
            ExerciseItem(name: "Plate-Loaded Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .machine, instructions: "Use plate-loaded row machine. Load plates, sit and pull handles. Allows for heavy loading."),
            ExerciseItem(name: "Machine Pullover", category: .back, muscleGroups: [.latissimusDorsi], equipment: .machine, instructions: "Use machine pullover. Sit in machine, pull handles down and forward. Isolates lats effectively."),
            ExerciseItem(name: "Assisted Pull-Up Machine", category: .back, muscleGroups: [.latissimusDorsi, .biceps, .rhomboids], equipment: .machine, instructions: "Use assisted pull-up machine. Set assistance weight. Perform pull-ups with reduced bodyweight. Great for beginners."),
            ExerciseItem(name: "Back Extension Machine", category: .back, muscleGroups: [.erectorSpinae, .glutes], equipment: .machine, instructions: "Use back extension machine. Secure legs, lower torso forward, raise back up. Strengthens lower back."),
            ExerciseItem(name: "Lever Row Machine", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .machine, instructions: "Use lever row machine. Pull lever handles to chest. Provides consistent resistance throughout movement."),
            
            // BACK - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Straight-Arm Pulldown", category: .back, muscleGroups: [.latissimusDorsi], equipment: .cable, instructions: "Set cable high. Keep arms straight, pull handle down in arc motion. Isolates lats without bicep involvement."),
            ExerciseItem(name: "Single-Arm Cable Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .cable, instructions: "Set cable at chest height. Row with one arm at a time. Unilateral focus improves muscle balance."),
            ExerciseItem(name: "Kneeling Cable Pulldown", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable, instructions: "Set cable high. Kneel on one knee, pull handle down to chest. Unique angle for lat development."),
            ExerciseItem(name: "Cable High Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids], equipment: .cable, instructions: "Set cable at chest height. Pull handles to upper chest. Targets upper back and rhomboids."),
            ExerciseItem(name: "Cable Low Row", category: .back, muscleGroups: [.latissimusDorsi, .biceps], equipment: .cable, instructions: "Set cable low. Pull handles to lower chest. Targets lower lats and biceps."),
            ExerciseItem(name: "Cable Reverse Fly", category: .back, muscleGroups: [.posteriorDeltoids, .rhomboids], equipment: .cable, instructions: "Set cables at chest height. Pull handles apart and back. Targets rear delts and upper back."),
            ExerciseItem(name: "Cable Shrug", category: .back, muscleGroups: [.trapezius], equipment: .cable, instructions: "Set cables low. Hold handles, shrug shoulders straight up. Constant tension on traps."),
            
            // BACK - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "Pendlay Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "Bend over with bar on ground. Explosively pull bar to lower chest. Return bar to ground between reps. Power movement."),
            ExerciseItem(name: "Meadows Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "One end of bar in corner. Row other end with one arm. Unique angle targets lats effectively."),
            ExerciseItem(name: "Kroc Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .dumbbell, instructions: "Bend over, support on bench. Row heavy dumbbell for high reps. Endurance and strength builder."),
            ExerciseItem(name: "Yates Row", category: .back, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "Bend over with more upright torso. Pull bar to lower chest with underhand grip. Targets lower lats and biceps."),
            ExerciseItem(name: "Conventional Deadlift", category: .back, muscleGroups: [.erectorSpinae, .glutes, .hamstrings, .trapezius], equipment: .barbell, instructions: "Standard deadlift stance. Feet hip-width, grip bar. Drive through heels, stand up. Full body strength builder."),
            
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
            
            // SHOULDERS - ADDITIONAL MACHINES
            ExerciseItem(name: "Iso-Lateral Shoulder Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .machine, instructions: "Use iso-lateral shoulder press machine. Each arm works independently. Press handles up one at a time or together."),
            ExerciseItem(name: "Plate-Loaded Shoulder Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .machine, instructions: "Use plate-loaded shoulder press machine. Load plates, sit and press handles up. Allows for heavy loading."),
            ExerciseItem(name: "Lateral Raise Machine", category: .shoulders, muscleGroups: [.lateralDeltoids], equipment: .machine, instructions: "Use lateral raise machine. Sit in machine, raise handles out to sides. Isolates lateral deltoids effectively."),
            ExerciseItem(name: "Rear Delt Fly Machine", category: .shoulders, muscleGroups: [.posteriorDeltoids], equipment: .machine, instructions: "Use rear delt fly machine. Sit facing machine, pull handles back and apart. Targets rear deltoids."),
            ExerciseItem(name: "Smith Machine Overhead Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .smithMachine, instructions: "Use Smith machine for overhead press. Press bar up from shoulder level. Safer for solo training."),
            
            // SHOULDERS - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Shoulder Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .cable, instructions: "Set cables at shoulder height. Press handles up. Constant tension throughout movement."),
            ExerciseItem(name: "Single-Arm Cable High Raise", category: .shoulders, muscleGroups: [.lateralDeltoids], equipment: .cable, instructions: "Set cable low. Raise handle up and out to side with one arm. Unilateral lateral delt focus."),
            
            // SHOULDERS - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "Barbell Overhead Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .barbell, instructions: "Stand with bar at shoulder level. Press bar overhead until arms extended. Keep core tight throughout."),
            ExerciseItem(name: "Iso-Lateral Dumbbell Press", category: .shoulders, muscleGroups: [.anteriorDeltoids, .lateralDeltoids, .triceps], equipment: .dumbbell, instructions: "Press one dumbbell at a time overhead. Alternate arms. Unilateral focus improves muscle balance."),
            
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
            
            // BICEPS - ADDITIONAL MACHINES
            ExerciseItem(name: "Bicep Curl Machine", category: .arms, muscleGroups: [.biceps], equipment: .machine, instructions: "Sit in bicep curl machine. Adjust seat height. Curl handles up. Isolates biceps effectively."),
            ExerciseItem(name: "Preacher Curl Machine", category: .arms, muscleGroups: [.biceps], equipment: .machine, instructions: "Use preacher curl machine. Rest arms on pad, curl handles up. Eliminates momentum for strict bicep work."),
            ExerciseItem(name: "Hammer Strength Curl Machine", category: .arms, muscleGroups: [.biceps], equipment: .machine, instructions: "Use Hammer Strength curl machine. Plate-loaded, unilateral movement. Curl handles one at a time or together."),
            
            // BICEPS - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Curl (straight bar)", category: .arms, muscleGroups: [.biceps], equipment: .cable, instructions: "Set cable low. Attach straight bar, curl up. Constant tension throughout movement."),
            ExerciseItem(name: "Rope Hammer Curl", category: .arms, muscleGroups: [.biceps, .forearms], equipment: .cable, instructions: "Set cable low. Attach rope, curl up with neutral grip. Targets biceps and forearms."),
            ExerciseItem(name: "Single-Arm Cable Curl", category: .arms, muscleGroups: [.biceps], equipment: .cable, instructions: "Set cable low. Curl with one arm at a time. Unilateral focus improves muscle balance."),
            ExerciseItem(name: "Cable Preacher Curl", category: .arms, muscleGroups: [.biceps], equipment: .cable, instructions: "Set cable low. Use preacher bench, curl handle up. Constant tension with strict form."),
            ExerciseItem(name: "Reverse Cable Curl", category: .arms, muscleGroups: [.forearms, .biceps], equipment: .cable, instructions: "Set cable low. Use overhand grip, curl up. Targets forearms primarily."),
            ExerciseItem(name: "High Cable Curl (biceps peak)", category: .arms, muscleGroups: [.biceps], equipment: .cable, instructions: "Set cables high. Pull handles down and together. Unique angle targets bicep peak."),
            
            // BICEPS - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "EZ-Bar Curl", category: .arms, muscleGroups: [.biceps], equipment: .barbell, instructions: "Use EZ-bar for curls. More wrist-friendly than straight bar. Curl bar up to chest level."),
            ExerciseItem(name: "Cross-Body Hammer Curl", category: .arms, muscleGroups: [.biceps, .forearms], equipment: .dumbbell, instructions: "Curl dumbbell across body with neutral grip. Targets biceps and forearms from unique angle."),
            
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
            
            // TRICEPS - ADDITIONAL MACHINES
            ExerciseItem(name: "Tricep Extension Machine", category: .arms, muscleGroups: [.triceps], equipment: .machine, instructions: "Sit in tricep extension machine. Press handles down until arms extended. Isolates triceps effectively."),
            ExerciseItem(name: "Dip Machine", category: .arms, muscleGroups: [.triceps, .anteriorDeltoids], equipment: .machine, instructions: "Use assisted dip machine. Set assistance weight. Perform dips with reduced bodyweight. Great for building up to bodyweight dips."),
            ExerciseItem(name: "Iso-Lateral Tricep Press Machine", category: .arms, muscleGroups: [.triceps], equipment: .machine, instructions: "Use iso-lateral tricep press machine. Each arm works independently. Press handles down one at a time or together."),
            
            // TRICEPS - ADDITIONAL CABLES
            ExerciseItem(name: "Rope Tricep Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable high. Attach rope, push down until arms extended. Separate rope at bottom for peak contraction."),
            ExerciseItem(name: "Straight Bar Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable high. Attach straight bar, push down. Targets all three tricep heads."),
            ExerciseItem(name: "Reverse Grip Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable high. Use underhand grip, push down. Targets different tricep head."),
            ExerciseItem(name: "Single-Arm Cable Pushdown", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable high. Push down with one arm at a time. Unilateral focus improves muscle balance."),
            ExerciseItem(name: "Cable Skullcrusher", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable high. Lie on bench, extend arms down. Constant tension throughout movement."),
            ExerciseItem(name: "Cable Kickback", category: .arms, muscleGroups: [.triceps], equipment: .cable, instructions: "Set cable low. Bend over, extend arm back. Isolates triceps effectively."),
            
            // TRICEPS - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "Bench Dips", category: .arms, muscleGroups: [.triceps, .anteriorDeltoids], equipment: .bodyweight, instructions: "Sit on bench edge, hands gripping edge. Lower body by bending arms, push back up. Targets triceps."),
            ExerciseItem(name: "Single-Arm Dumbbell Kickback", category: .arms, muscleGroups: [.triceps], equipment: .dumbbell, instructions: "Bend over, support on bench. Extend one arm back with dumbbell. Unilateral tricep isolation."),
            
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
            
            // LEGS - ADDITIONAL MACHINES
            ExerciseItem(name: "Hack Squat Machine", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .machine, instructions: "Use hack squat machine. Load plates, position shoulders under pads. Squat down and up. Targets quads primarily."),
            ExerciseItem(name: "Standing Leg Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .machine, instructions: "Use standing leg curl machine. Stand on one leg, curl other leg back. Unilateral hamstring isolation."),
            ExerciseItem(name: "Hip Abductor Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Sit in hip abductor machine. Push legs out against resistance. Targets glute medius and outer thighs."),
            ExerciseItem(name: "Hip Adductor Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Sit in hip adductor machine. Bring legs together against resistance. Targets inner thighs."),
            ExerciseItem(name: "Glute Kickback Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Use glute kickback machine. Position leg, kick back against resistance. Isolates glutes effectively."),
            ExerciseItem(name: "Vertical Leg Press", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .machine, instructions: "Use vertical leg press machine. Load plates, press platform up. Unique angle for leg development."),
            ExerciseItem(name: "Iso-Lateral Leg Press", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .machine, instructions: "Use iso-lateral leg press. Each leg works independently. Press platform one leg at a time or together."),
            ExerciseItem(name: "Sled Push", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .other, instructions: "Push weighted sled across turf or floor. Full body strength and conditioning exercise."),
            ExerciseItem(name: "Donkey Calf Machine", category: .legs, muscleGroups: [.calves], equipment: .machine, instructions: "Use donkey calf machine. Bend over, position feet on platform. Raise up on toes. Targets calves effectively."),
            
            // LEGS - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Kickback", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach ankle strap, kick leg back. Isolates glutes effectively."),
            ExerciseItem(name: "Cable Hip Abduction", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach ankle strap, lift leg out to side. Targets glute medius."),
            ExerciseItem(name: "Cable Hip Adduction", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach ankle strap, bring leg across body. Targets inner thighs."),
            ExerciseItem(name: "Cable Leg Extension (ankle strap)", category: .legs, muscleGroups: [.quadriceps], equipment: .cable, instructions: "Set cable low. Attach ankle strap, extend leg forward. Constant tension on quads."),
            ExerciseItem(name: "Cable Hamstring Curl", category: .legs, muscleGroups: [.hamstrings], equipment: .cable, instructions: "Set cable low. Attach ankle strap, curl leg back. Constant tension on hamstrings."),
            ExerciseItem(name: "Cable Pull-Through (glutes)", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .cable, instructions: "Set cable low. Stand facing away, pull cable through legs. Targets glutes and hamstrings."),
            ExerciseItem(name: "Cable Glute Drive", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach to hip, drive hip forward. Isolates glutes effectively."),
            ExerciseItem(name: "Cable Squat", category: .legs, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .cable, instructions: "Set cable low. Hold handle, perform squats. Constant tension throughout movement."),
            ExerciseItem(name: "Cable Step-Ups", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .cable, instructions: "Set cable low. Hold handle, step up onto box. Constant tension adds resistance."),
            
            // LEGS - ADDITIONAL FREE WEIGHT / ISO
            ExerciseItem(name: "Barbell Lunges", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .barbell, instructions: "Bar on upper back. Step forward into lunge position. Return to start. Alternate legs."),
            ExerciseItem(name: "Weighted Step-Ups", category: .legs, muscleGroups: [.quadriceps, .glutes], equipment: .dumbbell, instructions: "Hold dumbbells, step up onto box. Step down. Alternate legs. Targets quads and glutes."),
            ExerciseItem(name: "Stiff-Leg Deadlift", category: .legs, muscleGroups: [.hamstrings, .glutes, .erectorSpinae], equipment: .barbell, instructions: "Hold bar, keep legs mostly straight. Hinge at hips, lower bar. Feel hamstring stretch. Return to start."),
            ExerciseItem(name: "Calf Raises (standing/dumbbell)", category: .legs, muscleGroups: [.calves], equipment: .dumbbell, instructions: "Hold dumbbells, stand on toes. Raise up, lower down. Targets calves effectively."),
            
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
            
            // GLUTES - ADDITIONAL MACHINES
            ExerciseItem(name: "Glute Drive Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Use glute drive machine. Position shoulders under pads, drive hips up. Isolates glutes effectively."),
            ExerciseItem(name: "Booty Builder Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Use booty builder machine. Unique angle for glute development. Follow machine-specific instructions."),
            ExerciseItem(name: "Hip Thrust Machine", category: .legs, muscleGroups: [.glutes], equipment: .machine, instructions: "Use hip thrust machine. Position shoulders on pad, drive hips up. Targets glutes primarily."),
            ExerciseItem(name: "Smith Machine Hip Thrust", category: .legs, muscleGroups: [.glutes], equipment: .smithMachine, instructions: "Use Smith machine for hip thrusts. Position bar on hips, drive up. Safer for solo training."),
            
            // GLUTES - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Kickbacks", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach ankle strap, kick leg back. Isolates glutes effectively."),
            ExerciseItem(name: "Cable Hip Extensions", category: .legs, muscleGroups: [.glutes], equipment: .cable, instructions: "Set cable low. Attach to ankle, extend leg back. Targets glutes and hamstrings."),
            ExerciseItem(name: "Cable Pull-Throughs", category: .legs, muscleGroups: [.glutes, .hamstrings], equipment: .cable, instructions: "Set cable low. Stand facing away, pull cable through legs. Targets glutes and hamstrings."),
            
            // GLUTES - ADDITIONAL FREE WEIGHT
            ExerciseItem(name: "Banded Lateral Walks", category: .legs, muscleGroups: [.glutes], equipment: .resistanceBand, instructions: "Place band around legs. Step sideways maintaining tension. Targets glute medius."),
            ExerciseItem(name: "Banded Hip Abductions", category: .legs, muscleGroups: [.glutes], equipment: .resistanceBand, instructions: "Place band around legs. Lift leg out to side. Targets glute medius effectively."),
            ExerciseItem(name: "Banded Glute Thrusters", category: .legs, muscleGroups: [.glutes], equipment: .resistanceBand, instructions: "Place band around hips. Perform hip thrusts. Adds resistance to glute bridge movement."),
            
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
            
            // ABS / CORE - ADDITIONAL MACHINES
            ExerciseItem(name: "Ab Crunch Machine", category: .core, muscleGroups: [.abdominals], equipment: .machine, instructions: "Sit in ab crunch machine. Adjust seat height. Crunch forward. Isolates abs effectively."),
            ExerciseItem(name: "Rotary Torso Machine", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .machine, instructions: "Use rotary torso machine. Rotate torso against resistance. Targets obliques and core rotation."),
            ExerciseItem(name: "Decline Crunch Bench", category: .core, muscleGroups: [.abdominals], equipment: .machine, instructions: "Set bench to decline. Secure feet, perform crunches. Increases resistance on abs."),
            ExerciseItem(name: "Ab Coaster", category: .core, muscleGroups: [.abdominals], equipment: .machine, instructions: "Use ab coaster machine. Kneel on pad, pull knees to chest. Unique angle for ab development."),
            
            // ABS / CORE - ADDITIONAL CABLES
            ExerciseItem(name: "Cable Woodchopper", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .cable, instructions: "Set cable high. Pull handle down and across body. Targets obliques and core rotation."),
            ExerciseItem(name: "Low → High Woodchopper", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .cable, instructions: "Set cable low. Pull handle up and across body. Targets obliques from different angle."),
            ExerciseItem(name: "High → Low Woodchopper", category: .core, muscleGroups: [.obliques, .abdominals], equipment: .cable, instructions: "Set cable high. Pull handle down and across body. Targets obliques effectively."),
            ExerciseItem(name: "Cable Side Bends", category: .core, muscleGroups: [.obliques], equipment: .cable, instructions: "Set cable at side. Hold handle, bend to side. Isolates obliques effectively."),
            
            // ABS / CORE - ADDITIONAL FREE WEIGHT / BODYWEIGHT
            ExerciseItem(name: "Hanging Knee Raises", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight, instructions: "Hang from bar. Raise knees to chest. Targets lower abs effectively."),
            ExerciseItem(name: "Weighted Sit-Ups", category: .core, muscleGroups: [.abdominals], equipment: .dumbbell, instructions: "Hold weight plate or dumbbell. Perform sit-ups with added resistance. Increases difficulty."),
            ExerciseItem(name: "Decline Bench Leg Raise", category: .core, muscleGroups: [.abdominals], equipment: .bodyweight, instructions: "Set bench to decline. Secure upper body, raise legs. Targets lower abs effectively."),
            
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
            
            // FULL BODY / MISC - ADDITIONAL
            ExerciseItem(name: "Sled Pull", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .hamstrings, .latissimusDorsi], equipment: .other, instructions: "Pull weighted sled across turf or floor. Full body strength and conditioning exercise."),
            ExerciseItem(name: "Farmer's Carry", category: .fullBody, muscleGroups: [.forearms, .trapezius, .quadriceps, .glutes], equipment: .dumbbell, instructions: "Hold heavy dumbbells at sides. Walk forward maintaining posture. Full body strength and grip builder."),
            ExerciseItem(name: "Landmine Squat", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .hamstrings], equipment: .barbell, instructions: "One end of bar in corner. Hold other end, perform squats. Unique angle for leg development."),
            ExerciseItem(name: "Landmine Press", category: .fullBody, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .barbell, instructions: "One end of bar in corner. Press other end forward. Unique angle for chest and shoulders."),
            ExerciseItem(name: "Landmine Row", category: .fullBody, muscleGroups: [.latissimusDorsi, .rhomboids, .biceps], equipment: .barbell, instructions: "One end of bar in corner. Row other end. Unique angle targets back effectively."),
            ExerciseItem(name: "Landmine Twist", category: .fullBody, muscleGroups: [.obliques, .abdominals], equipment: .barbell, instructions: "One end of bar in corner. Hold other end, rotate torso. Targets obliques and core rotation."),
            ExerciseItem(name: "Battle Ropes", category: .fullBody, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps, .abdominals], equipment: .other, instructions: "Hold heavy ropes. Create waves by slamming ropes up and down. Full body conditioning exercise."),
            ExerciseItem(name: "Tire Flip", category: .fullBody, muscleGroups: [.quadriceps, .glutes, .hamstrings, .anteriorDeltoids], equipment: .other, instructions: "Bend down, grip tire. Drive through legs, flip tire over. Full body power exercise."),
            ExerciseItem(name: "Medicine Ball Slams", category: .fullBody, muscleGroups: [.abdominals, .obliques, .anteriorDeltoids], equipment: .other, instructions: "Hold medicine ball overhead. Slam down to ground. Full body power and conditioning exercise."),
            ExerciseItem(name: "Medicine Ball Chest Throw", category: .fullBody, muscleGroups: [.pectorals, .anteriorDeltoids, .triceps], equipment: .other, instructions: "Hold medicine ball at chest. Throw explosively against wall. Power exercise for chest and shoulders."),
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

