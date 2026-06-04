import '../models/tutorial.dart';

// YouTube IDs from @samsjump (Samy Sieber) — replace with verified IDs as needed
final List<Tutorial> mockTutorials = [
  Tutorial(
    id: '1',
    title: 'Jump Rope for Complete Beginners',
    description:
        'Start your jump rope journey here. Samy breaks down the basics — stance, timing, and the single bounce. Perfect if you have never picked up a rope before.',
    youtubeId: 'bTqVqk7FSmY',
    level: 'beginner',
    category: 'fitness',
    durationMinutes: 8,
    thumbnailUrl: 'https://img.youtube.com/vi/bTqVqk7FSmY/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 1, 10),
  ),
  Tutorial(
    id: '2',
    title: 'Double Under Tutorial — Step by Step',
    description:
        'The double under is the gateway trick. Learn the wrist flick, timing, and bounce height needed to land your first consistent double unders.',
    youtubeId: 'xvFZjo5PgG0',
    level: 'intermediate',
    category: 'tricks',
    durationMinutes: 12,
    thumbnailUrl: 'https://img.youtube.com/vi/xvFZjo5PgG0/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 2, 5),
  ),
  Tutorial(
    id: '3',
    title: 'Crossover Basics — Learn the X',
    description:
        'The crossover is one of the most satisfying tricks in jump rope. This tutorial covers the arm position, timing, and common mistakes to avoid.',
    youtubeId: 'RytN_7N4kYE',
    level: 'intermediate',
    category: 'tricks',
    durationMinutes: 10,
    thumbnailUrl: 'https://img.youtube.com/vi/RytN_7N4kYE/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 3, 1),
  ),
  Tutorial(
    id: '4',
    title: '10 Minute Jump Rope HIIT Workout',
    description:
        'No gym needed. This full-body HIIT session uses only a jump rope. Burn calories, build endurance, and level up your cardio in under 10 minutes.',
    youtubeId: 'KQ9i8Oc0JCk',
    level: 'beginner',
    category: 'fitness',
    durationMinutes: 10,
    thumbnailUrl: 'https://img.youtube.com/vi/KQ9i8Oc0JCk/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 3, 20),
  ),
  Tutorial(
    id: '5',
    title: 'Triple Under — The Holy Grail',
    description:
        'Three rotations per jump. Samy walks through the technique that took him years to master — and shows you the fastest path to getting there.',
    youtubeId: 'pRpeEdMmmQ0',
    level: 'advanced',
    category: 'tricks',
    durationMinutes: 15,
    thumbnailUrl: 'https://img.youtube.com/vi/pRpeEdMmmQ0/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 4, 8),
  ),
  Tutorial(
    id: '6',
    title: '30-Day Progression Program — Week 1',
    description:
        'Structured daily workouts designed to take you from zero to consistent double unders in 30 days. Week 1 focuses on building the foundation.',
    youtubeId: 'dJ9fGFGLwsQ',
    level: 'advanced',
    category: 'program',
    durationMinutes: 20,
    thumbnailUrl: 'https://img.youtube.com/vi/dJ9fGFGLwsQ/maxresdefault.jpg',
    isFree: true,
    createdAt: DateTime(2024, 5, 1),
  ),
];
