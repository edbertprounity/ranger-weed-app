class WeedSpecies {
  const WeedSpecies({
    required this.key,
    required this.name,
    required this.shortName,
    required this.scientific,
    required this.identification,
    required this.color,
  });

  final String key;
  final String name;
  final String shortName;
  final String scientific;
  final String identification;
  final int color;

  static const rubbervine = WeedSpecies(
    key: 'rubbervine',
    name: 'Rubbervine',
    shortName: 'Rubbervine',
    scientific: 'Cryptostegia grandiflora',
    identification: 'Woody vine with milky sap and purple funnel-shaped flowers.',
    color: 0xFF8C3A4B,
  );
  static const sicklepod = WeedSpecies(
    key: 'sicklepod',
    name: 'Sicklepod',
    shortName: 'Sicklepod',
    scientific: 'Senna obtusifolia',
    identification: 'Yellow flowers and long, curved seed pods.',
    color: 0xFFB86E2A,
  );
  static const lantana = WeedSpecies(
    key: 'lantana',
    name: 'Lantana',
    shortName: 'Lantana',
    scientific: 'Lantana camara',
    identification: 'Shrub with rough leaves and mixed-colour flower heads.',
    color: 0xFFC45C8A,
  );
  static const gambaGrass = WeedSpecies(
    key: 'gamba_grass',
    name: 'Gamba grass',
    shortName: 'Gamba',
    scientific: 'Andropogon gayanus',
    identification: 'Tall tussock grass with a fluffy seed head.',
    color: 0xFF6E8B3D,
  );
  static const giantRatsTail = WeedSpecies(
    key: 'giant_rats_tail',
    name: "Giant rat's tail",
    shortName: "Rat's tail",
    scientific: 'Sporobolus pyramidalis',
    identification: 'Tough grass with a narrow, rat-tail seed head.',
    color: 0xFF3E6B8A,
  );
  static const oliveHymenachne = WeedSpecies(
    key: 'olive_hymenachne',
    name: 'Olive hymenachne',
    shortName: 'Olive',
    scientific: 'Hymenachne amplexicaulis',
    identification: 'Floodplain grass with broad leaves clasping the stem.',
    color: 0xFF2F6F5E,
  );

  /// Priority order from the Lama Lama Weeds Action Plan.
  static const all = <WeedSpecies>[
    rubbervine,
    sicklepod,
    lantana,
    gambaGrass,
    giantRatsTail,
    oliveHymenachne,
  ];

  static WeedSpecies? byKey(String key) {
    for (final species in all) {
      if (species.key == key) return species;
    }
    return null;
  }

  static int rank(String key) {
    final index = all.indexWhere((species) => species.key == key);
    return index < 0 ? all.length : index;
  }
}
