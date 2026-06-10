import '../models/exercise.dart';
import '../models/workout.dart';

final mockWorkouts = [
  // ── Monday — Foundation ────────────────────────────────────────────────────
  Workout(
    id: 'w_mon',
    title: 'Foundation',
    description: 'Build the base. Master your rhythm and footwork before everything else.',
    weekday: 1,
    durationMinutes: 15,
    difficulty: 'beginner',
    focusArea: 'Rhythm & Control',
    exercises: [
      const Exercise(
        id: 'e_mon_1',
        name: 'Basic Bounce Warmup',
        instruction: 'Jump at a comfortable pace. Keep feet together, land softly on the balls of your feet. Focus on consistent wrist rotation.',
        sets: 3,
        reps: 30,
        restSeconds: 30,
      ),
      const Exercise(
        id: 'e_mon_2',
        name: 'Alternating Steps',
        instruction: 'Step side-to-side as you jump, shifting weight with each rotation. Keep hips level.',
        sets: 3,
        reps: 20,
        restSeconds: 30,
      ),
      const Exercise(
        id: 'e_mon_3',
        name: 'Single Leg Hold',
        instruction: 'Balance on one foot for 5 consecutive jumps, then switch. Core tight, gaze forward.',
        sets: 3,
        reps: 10,
        restSeconds: 45,
      ),
    ],
  ),

  // ── Tuesday — Endurance ────────────────────────────────────────────────────
  Workout(
    id: 'w_tue',
    title: 'Endurance',
    description: 'Push your cardio limits. Long sets that build stamina and mental grit.',
    weekday: 2,
    durationMinutes: 20,
    difficulty: 'intermediate',
    focusArea: 'Cardio & Stamina',
    exercises: [
      const Exercise(
        id: 'e_tue_1',
        name: 'Continuous Bounce',
        instruction: 'Jump non-stop at a steady pace. Breathe through your nose, exhale on every 4th jump.',
        sets: 3,
        durationSeconds: 60,
        restSeconds: 45,
      ),
      const Exercise(
        id: 'e_tue_2',
        name: 'High Knees Jump',
        instruction: 'Drive your knees up to hip height with every jump. Faster cadence than normal.',
        sets: 3,
        reps: 30,
        restSeconds: 45,
      ),
      const Exercise(
        id: 'e_tue_3',
        name: 'Sprint Intervals',
        instruction: 'Jump as fast as possible for the full interval. Shake out your wrists during rest.',
        sets: 4,
        durationSeconds: 30,
        restSeconds: 30,
      ),
    ],
  ),

  // ── Wednesday — Technique ──────────────────────────────────────────────────
  Workout(
    id: 'w_wed',
    title: 'Technique',
    description: 'Slow it down to level up. Precision over speed — this is where real skill is built.',
    weekday: 3,
    durationMinutes: 15,
    difficulty: 'beginner',
    focusArea: 'Wrist & Footwork',
    exercises: [
      const Exercise(
        id: 'e_wed_1',
        name: 'Wrist Circles (no rope)',
        instruction: 'Hold rope ends and rotate wrists in small circles for the full set. Keep elbows close to your sides.',
        sets: 3,
        durationSeconds: 30,
        restSeconds: 15,
      ),
      const Exercise(
        id: 'e_wed_2',
        name: 'Side Swing',
        instruction: 'Swing rope at your side without jumping — focus on a consistent oval shape. Switch hands mid-set.',
        sets: 3,
        durationSeconds: 45,
        restSeconds: 20,
      ),
      const Exercise(
        id: 'e_wed_3',
        name: 'Cross Over Attempt',
        instruction: 'Cross arms low and wide on every other jump. Uncross before the rope hits the ground.',
        sets: 3,
        reps: 10,
        restSeconds: 45,
      ),
    ],
  ),

  // ── Thursday — Power ───────────────────────────────────────────────────────
  Workout(
    id: 'w_thu',
    title: 'Power',
    description: 'Go explosive. Double under prep and power jumps to build fast-twitch strength.',
    weekday: 4,
    durationMinutes: 25,
    difficulty: 'advanced',
    focusArea: 'Double Unders & Power',
    exercises: [
      const Exercise(
        id: 'e_thu_1',
        name: 'Double Under Attempts',
        instruction: 'One big jump + two rope passes. Snap wrists fast. Don\'t tuck — just jump higher.',
        sets: 5,
        reps: 10,
        restSeconds: 45,
      ),
      const Exercise(
        id: 'e_thu_2',
        name: 'Speed Bounces',
        instruction: 'Maximum cadence. Stay on balls of feet. Arms locked, only wrists move.',
        sets: 3,
        durationSeconds: 45,
        restSeconds: 30,
      ),
      const Exercise(
        id: 'e_thu_3',
        name: 'Power Jumps',
        instruction: 'Jump as high as possible each rep. Full extension, land soft, absorb with knees.',
        sets: 3,
        reps: 15,
        restSeconds: 60,
      ),
    ],
  ),

  // ── Friday — Flow ──────────────────────────────────────────────────────────
  Workout(
    id: 'w_fri',
    title: 'Flow',
    description: 'String it all together. Move freely and start building your personal style.',
    weekday: 5,
    durationMinutes: 20,
    difficulty: 'intermediate',
    focusArea: 'Combos & Freestyle',
    exercises: [
      const Exercise(
        id: 'e_fri_1',
        name: 'Freestyle Flow',
        instruction: 'Mix any moves you know. Change it up every 10 jumps — no stopping.',
        sets: 4,
        durationSeconds: 60,
        restSeconds: 30,
      ),
      const Exercise(
        id: 'e_fri_2',
        name: 'Cross + Bounce Combo',
        instruction: '3 normal bounces, then 1 cross, then back. Build the pattern slowly, then speed up.',
        sets: 3,
        reps: 20,
        restSeconds: 45,
      ),
      const Exercise(
        id: 'e_fri_3',
        name: 'Trick Attempt (your choice)',
        instruction: 'Pick one skill from your skill tree you\'re working on. Drill it with full focus.',
        sets: 3,
        reps: 8,
        restSeconds: 60,
      ),
    ],
  ),

  // ── Saturday — Challenge ───────────────────────────────────────────────────
  Workout(
    id: 'w_sat',
    title: 'Challenge Day',
    description: 'Test yourself. Max efforts, personal records, and community bragging rights.',
    weekday: 6,
    durationMinutes: 30,
    difficulty: 'advanced',
    focusArea: 'Max Effort & PRs',
    exercises: [
      const Exercise(
        id: 'e_sat_1',
        name: 'Max Rep Double Unders',
        instruction: 'One attempt to go as long as possible. Breathe, stay loose, don\'t overthink it.',
        sets: 3,
        reps: null,
        durationSeconds: 120,
        restSeconds: 90,
      ),
      const Exercise(
        id: 'e_sat_2',
        name: 'Tabata Intervals',
        instruction: '20s max effort / 10s rest. 8 rounds. This is supposed to hurt.',
        sets: 8,
        durationSeconds: 20,
        restSeconds: 10,
      ),
      const Exercise(
        id: 'e_sat_3',
        name: 'Cool Down Bounce',
        instruction: 'Slow, easy jumping. Let your heart rate come down. Reflect on the week.',
        sets: 2,
        durationSeconds: 60,
        restSeconds: 0,
      ),
    ],
  ),

  // ── Sunday — Recovery ─────────────────────────────────────────────────────
  Workout(
    id: 'w_sun',
    title: 'Active Recovery',
    description: 'Rest is part of the program. Light movement to flush the legs and reset for the week.',
    weekday: 7,
    durationMinutes: 10,
    difficulty: 'beginner',
    focusArea: 'Mobility & Recovery',
    exercises: [
      const Exercise(
        id: 'e_sun_1',
        name: 'Slow Bounce',
        instruction: 'Very easy, relaxed jumping. No pressure. Just keep the blood moving.',
        sets: 2,
        durationSeconds: 60,
        restSeconds: 30,
      ),
      const Exercise(
        id: 'e_sun_2',
        name: 'Ankle Circles',
        instruction: 'Put the rope down. Rotate each ankle 10 times each direction. Helps with recovery and injury prevention.',
        sets: 2,
        reps: 10,
        restSeconds: 0,
      ),
      const Exercise(
        id: 'e_sun_3',
        name: 'Calf Stretch Hold',
        instruction: 'Step one foot back, heel flat, lean forward. Hold 30 seconds each side.',
        sets: 2,
        durationSeconds: 30,
        restSeconds: 0,
      ),
    ],
  ),
];

Workout getTodayWorkout() {
  final weekday = DateTime.now().weekday; // 1=Mon, 7=Sun
  return mockWorkouts.firstWhere(
    (w) => w.weekday == weekday,
    orElse: () => mockWorkouts.first,
  );
}
