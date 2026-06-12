import '../models/skill.dart';

// Real video uploaded to Supabase Storage
const _basicBounceUrl =
    'https://oxhbcqptklsqlvyqnhiz.supabase.co/storage/v1/object/public/public%20ecommerce/videos/Screen%20Recording%202026-06-11%20at%2000.19.04.mov';

// TODO: upload remaining skill videos and replace these placeholders
const _placeholderUrl = _basicBounceUrl;

List<Skill> buildMockSkills() {
  return [
    Skill(
      id: 'basic_bounce',
      title: 'Basic Bounce',
      description:
          'The foundation of every jump rope skill. Master the two-foot bounce before moving on.',
      videoUrl: _basicBounceUrl,
      tips: [
        'Keep elbows close to your body',
        'Jump only 2-3cm off the ground',
        'Land on the balls of your feet',
        'Keep a steady rhythm — speed comes later',
        'Relax your shoulders',
      ],
      unlockIds: ['forward_jump', 'backward_jump', 'alt_steps'],
      xpReward: 50,
      orderIndex: 0,
      isFreeNode: true,
      status: SkillStatus.available,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'forward_jump',
      title: 'Forward Jump',
      description:
          'Jump continuously with the rope swinging forward. Build rhythm and timing.',
      videoUrl: _placeholderUrl,
      tips: [
        'Drive through your wrists, not your arms',
        'Keep your eyes forward, not down',
        'Find a 1:1 rhythm — one rotation per jump',
        'Stay on the balls of your feet',
        "Breathe consistently — don't hold your breath",
      ],
      unlockIds: ['double_unders', 'cross_overs'],
      xpReward: 75,
      orderIndex: 1,
      isFreeNode: true,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'backward_jump',
      title: 'Backward Jump',
      description:
          'Swing the rope backward. Develops spatial awareness and coordination.',
      videoUrl: _placeholderUrl,
      tips: [
        'Same mechanics as forward but reversed',
        'Start slow — control over speed',
        'Keep your chin up',
        'Listen to the rope hitting the ground',
        'Trust your spatial awareness',
      ],
      unlockIds: ['side_swing'],
      xpReward: 75,
      orderIndex: 2,
      isFreeNode: true,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'alt_steps',
      title: 'Alternating Steps',
      description:
          'Alternate feet with each rope pass — like running in place with the rope.',
      videoUrl: _placeholderUrl,
      tips: [
        'Think of it like running in place',
        'Shift weight completely from foot to foot',
        'Keep your core tight',
        'Start slow then increase tempo',
        'Arms stay close to your sides',
      ],
      unlockIds: [],
      xpReward: 100,
      orderIndex: 3,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'double_unders',
      title: 'Double Unders',
      description:
          'Two rope passes per jump. The gateway to advanced speed skills.',
      videoUrl: _placeholderUrl,
      tips: [
        'Jump slightly higher than normal',
        'Accelerate your wrists — not your arms',
        'Stay relaxed in your shoulders',
        'Time the double rotation at peak height',
        'Keep jumps consistent, not explosive',
      ],
      unlockIds: ['triple_unders'],
      xpReward: 150,
      orderIndex: 4,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'cross_overs',
      title: 'Cross Overs',
      description:
          'Cross arms in front of the body as the rope passes under. Coordination at its finest.',
      videoUrl: _placeholderUrl,
      tips: [
        'Cross at your hips, not your chest',
        'Keep elbows in as you cross',
        "Uncross fast — don't linger",
        'Master single crosses before combining',
        'Look straight ahead, not at your hands',
      ],
      unlockIds: ['cross_double'],
      xpReward: 150,
      orderIndex: 5,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'side_swing',
      title: 'Side Swing',
      description:
          'Swing the rope to the side without jumping — essential for transitions and tricks.',
      videoUrl: _placeholderUrl,
      tips: [
        'Keep the rope low to the ground',
        'Use wrist rotation, not arm swing',
        'Practice both sides equally',
        'Stay light on your feet',
        'Use side swing as a reset or transition',
      ],
      unlockIds: ['releases'],
      xpReward: 100,
      orderIndex: 6,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'triple_unders',
      title: 'Triple Unders',
      description:
          'Three rope passes per jump. Explosive power and lightning-fast wrists required.',
      videoUrl: _placeholderUrl,
      tips: [
        'Need explosive vertical jump',
        'Maximize wrist speed — wrists are everything',
        'Time your peak perfectly',
        'This requires months of double under mastery',
        'Stay calm — tension kills triple unders',
      ],
      unlockIds: ['freestyle'],
      xpReward: 200,
      orderIndex: 7,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'cross_double',
      title: 'Cross Double',
      description:
          'Cross arms while performing a double under. Pure coordination and timing.',
      videoUrl: _placeholderUrl,
      tips: [
        'Master double unders and cross overs separately first',
        'Cross at peak height of your double under',
        "Timing is everything — feel don't think",
        'Slow it down in practice, speed comes later',
        'Keep jumps consistent and controlled',
      ],
      unlockIds: ['freestyle'],
      xpReward: 200,
      orderIndex: 8,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'releases',
      title: 'Releases',
      description:
          'Release and catch the rope mid-air. The foundation of freestyle tricks.',
      videoUrl: _placeholderUrl,
      tips: [
        'Loosen your grip before releasing',
        'Release at a consistent point in rotation',
        'Catch firmly — a fumbled catch breaks flow',
        'Start with one hand release only',
        "Control the rope, don't fight it",
      ],
      unlockIds: ['freestyle'],
      xpReward: 175,
      orderIndex: 9,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
    Skill(
      id: 'freestyle',
      title: 'Freestyle',
      description:
          'Chain skills into flowing combinations. This is where you create your own style.',
      videoUrl: _placeholderUrl,
      tips: [
        'Chain 3 different skills back to back',
        'Transitions are as important as tricks',
        'Develop your signature sequence',
        'Film yourself to spot inefficiencies',
        'Style is rhythm — find yours',
      ],
      unlockIds: [],
      xpReward: 500,
      orderIndex: 10,
      isFreeNode: false,
      status: SkillStatus.locked,
      sessionsCompleted: 0,
    ),
  ];
}
