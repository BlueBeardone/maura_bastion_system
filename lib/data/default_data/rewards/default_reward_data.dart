import 'package:maura_bastion_system/data/enums/rank.dart';
import 'package:maura_bastion_system/data/models/rewards/reward.dart';

const double _leatherWeight = 5.0;
const double _meatWeight = 2.0;
const double _metalWeight = 5.0;
const double _stoneWeight = 5.0;
const double _woodWeight = 5.0;
const double _weaveWeight = 2.0;
const double _herbWeight = 0.5;

List<Reward> getDefaultRewards() {
  return [
    // ===================== Creature Parts =====================
    // 1 unit of exotic leather weighs 5 lbs.
    Reward(
      id: 'rew_abominable_skin',
      name: 'Abominable Skin',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Psychic] Slimy yet hard as stone, the hides of abberants and truly unnatural beings can be made into disturbing equipment.',
    ),
    Reward(
      id: 'rew_bones',
      name: 'Bones',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Physical, Variable] Found in any creature with bones. Dragon bones have an element equal to the dragon\'s breath weapon damage type.',
    ),
    Reward(
      id: 'rew_chitin',
      name: 'Chitin',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Physical] Flexible shells of chitinous creatures such as giant crabs, insects, or remorhaz.',
    ),
    Reward(
      id: 'rew_ellond_hide',
      name: 'Ellond Hide',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Fire] This brown-orange hide is harvested from desert and steppe creatures.',
    ),
    Reward(
      id: 'rew_thick_hide',
      name: 'Thick Hide',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Cold] Thick furs are excellent for warmth and protection. If a DM gives you a \'Hide\' and doesn\'t specify anything else, they probably meant \'Thick Hide\'.',
    ),
    Reward(
      id: 'rew_monster_feathers',
      name: 'Monster Feathers',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Physical] Hippogriffs, owlbears, rocs, giant eagles, and other flying creatures have beautiful feathers used to show their majesty.',
    ),
    Reward(
      id: 'rew_monster_scales',
      name: 'Monster Scales',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Physical, or Variable] Harvested from scaly creatures. Dragon scales have an element equal to the dragon\'s breath weapon damage type.',
    ),
    Reward(
      id: 'rew_demon_leather',
      name: 'Demon Leather',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Fire] Aubern and harvested from the Infernal Planes and Fire.',
    ),
    Reward(
      id: 'rew_spirit_pelt',
      name: 'Spirit Pelt',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Force] Cyan and overflowing with magic, beasts of the Outlands, Deep Ethereal, and Astral Planes should not be left un-harvested.',
    ),
    Reward(
      id: 'rew_venom_glands',
      name: 'Venom Glands',
      category: RewardCategory.creaturePart,
      weightPerUnit: _leatherWeight,
      description:
          '[Poison] Many creatures have powerful venoms. If harvested properly, they can be crafted into potent poisons.',
    ),

    // ===================== Meat & Blood =====================
    // 1 unit of exotic meat/blood weighs 2 lbs. Rank and value are equal to
    // the adventure they are harvested in (see mainChartMeatBloodValueByRank).
    Reward(
      id: 'rew_meat',
      name: 'Meat',
      category: RewardCategory.meat,
      weightPerUnit: _meatWeight,
      description:
          'Exotic meat harvested from a creature\'s corpse. The rank/rarity of the meat is equal to the adventure it is harvested in.',
    ),
    Reward(
      id: 'rew_blood',
      name: 'Blood',
      category: RewardCategory.blood,
      weightPerUnit: _meatWeight,
      description:
          'Blood from a fresh kill of a healthy Beast can be drunk immediately. A creature yields equal amounts of blood to rations of meat found (the rest having bled out). After 10 minutes, blood spoils and a character must make a DC 15 Con save to avoid vomiting.',
    ),

    // ===================== Exotic Metals =====================
    // 1 unit of exotic metal weighs 5 lbs.
    Reward(
      id: 'rew_adamantine',
      name: 'Adamantine',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Physical] the hardest metal ever forged, this meteoritic iron has the power to blunt even the mightiest of assaults.',
    ),
    Reward(
      id: 'rew_fellsteel',
      name: 'Fellsteel',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Necrotic] blackened by exposure to necrotic forces, this metal is usually mined in the Shadowfell or stripped from the bodies of the denizens of Limbo.',
    ),
    Reward(
      id: 'rew_cold_iron',
      name: 'Cold Iron',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Physical] also known as Wildbane, this frigid metal is found in the coldest reaches of the Feywild and harsh depths of the Abyss.',
    ),
    Reward(
      id: 'rew_moonsteel',
      name: 'Moonsteel',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Lightning] silvery with a purple sheen, this hard star steel is commonly found in Mount Celestia, Bytopia, and Elysium.',
    ),
    Reward(
      id: 'rew_bloodmetal',
      name: 'Bloodmetal',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Fire] crimson and blistering hot to the touch, this infernal steel smells faintly of brimstone, reminiscent of its origins from Gehenna and the Nine Hells of Baator.',
    ),
    Reward(
      id: 'rew_mithril',
      name: 'Mithril',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Physical] platinum-white and nearly as flexible as boiled leather, this substance is a favorite among Elves above all for its lightness.',
    ),
    Reward(
      id: 'rew_orichalcum',
      name: 'Orichalcum',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Force] bronze-gold with the faintest azure sheen, this metal hailing from the Outlands, Ethereal and Astral Planes seems to absorb all the magic it comes into contact with.',
    ),
    Reward(
      id: 'rew_plaguesteel',
      name: 'Plaguesteel',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Poison] ancient, porous, and covered in moss with the scent of mold and spores, the Shadowfell, Carceri, and Hades could not have produced a substance more foul.',
    ),
    Reward(
      id: 'rew_sunsteel',
      name: 'Sunsteel',
      category: RewardCategory.metal,
      weightPerUnit: _metalWeight,
      description:
          '[Radiant] bright yet cool to the touch, this metal is the rarest of the star steels and paradoxically found only in the deepest caves of Mechanus and Arcadia.',
    ),

    // ===================== Stones =====================
    // 1 unit of exotic stone weighs 5 lbs.
    Reward(
      id: 'rew_skyshard',
      name: 'Skyshard',
      category: RewardCategory.stone,
      weightPerUnit: _stoneWeight,
      description:
          '[Stone, Lightning] a glassy substance the colour of the endless heavens is found on islands floating in the Elemental Planes of Air and Chaos.',
    ),
    Reward(
      id: 'rew_coral',
      name: 'Coral',
      category: RewardCategory.stone,
      weightPerUnit: _stoneWeight,
      description:
          '[Stone, Cold] the living organism deep below the sea can produce the hardest of materials under the right conditions. Water elementals deem this to be amongst the most precious of things.',
    ),
    Reward(
      id: 'rew_eternal_ice',
      name: 'Eternal Ice',
      category: RewardCategory.stone,
      weightPerUnit: _stoneWeight,
      description:
          '[Stone, Cold] snowy, pure, and strong, this chunk of polar rock will never melt, not even when exposed to the planes of Positive and Negative Energy, or the madening silence of The Far Realms.',
    ),
    Reward(
      id: 'rew_ignum',
      name: 'Ignum',
      category: RewardCategory.stone,
      weightPerUnit: _stoneWeight,
      description:
          '[Stone, Fire] unearthed from the calderas of volcanos and the Elemental Plane of Fire, this rock needs no introduction.',
    ),
    Reward(
      id: 'rew_obsidian',
      name: 'Obsidian',
      category: RewardCategory.stone,
      weightPerUnit: _stoneWeight,
      description:
          '[Stone, Physical] born in magma, this stone splits down to the sharpest of points, making it an ideal material for Ysgardian spears, and the component-material of many Earth Elementals.',
    ),

    // ===================== Woods =====================
    // 1 unit of exotic wood weighs 5 lbs (Ironwood 25 lbs).
    Reward(
      id: 'rew_darkwood',
      name: 'Darkwood',
      category: RewardCategory.wood,
      weightPerUnit: _woodWeight,
      description:
          '[Wood, Physical] as hard as Ash wood but half the weight, the Feywild, Beastlands, and Arboria could not produce a prouder timber.',
    ),
    Reward(
      id: 'rew_deadwood',
      name: 'Deadwood',
      category: RewardCategory.wood,
      weightPerUnit: _woodWeight,
      description:
          '[Wood, Acid] grey and rotten to the touch, many denizens of the Shadowfell, Arboria, and the Beastlands tell stories of swampwood that resists acid damage.',
    ),
    Reward(
      id: 'rew_ironwood',
      name: 'Ironwood',
      category: RewardCategory.wood,
      weightPerUnit: 25.0,
      description:
          '[Wood, Thunder] as heavy as cast iron, the Beastlands and Arboria are the only places where these trees grow. Weighs 25lbs per unit.',
    ),
    Reward(
      id: 'rew_summitwood',
      name: 'Summitwood',
      category: RewardCategory.wood,
      weightPerUnit: _woodWeight,
      description:
          '[Wood, Cold] Blisteringly cold to the touch, this planar frostwood can be found in any palce where summer is strictly impossible.',
    ),

    // ===================== Weaves =====================
    // 1 unit of exotic weave weighs 2 lbs.
    Reward(
      id: 'rew_heavenweave',
      name: 'Heavenweave',
      category: RewardCategory.weave,
      weightPerUnit: _weaveWeight,
      description:
          '[Weave, Radiant] radiating with the spark of the Positive Plane and the outer planes of Heaven, this light-woven material is a favorite of Angels and divine warriors.',
    ),
    Reward(
      id: 'rew_leafweave',
      name: 'Leafweave',
      category: RewardCategory.weave,
      weightPerUnit: _weaveWeight,
      description:
          '[Weave, Physical] alchemically processed leaves to be hard as leather, armour made from this is legendary among all Sylvans.',
    ),
    Reward(
      id: 'rew_shadowsilk',
      name: 'Shadowsilk',
      category: RewardCategory.weave,
      weightPerUnit: _weaveWeight,
      description:
          '[Weave, Psychic] A black semi-transparent silk carefully made by underground spiders and spider-like creatures common to the Shadowfell.',
    ),
    Reward(
      id: 'rew_spidersilk',
      name: 'Spidersilk',
      category: RewardCategory.weave,
      weightPerUnit: _weaveWeight,
      description:
          '[Weave, Poison] Harvested from spiders or like creatures, this material is both sticky and incredibly strong, useful for armour or exotic ropes!',
    ),

    // ===================== Herbs =====================
    // 1 unit of herbs weighs 1/2 lb.
    // ---- Common Herbs: Rank E, 15g value per unit ----
    Reward(
      id: 'rew_blue_herb',
      name: 'Blue Herb',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'A common medicinal herb that frequently grows near water, especially rivers and lakes.',
    ),
    Reward(
      id: 'rew_blood_herb',
      name: 'Blood Herb',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'The red-leafed cousin of blue herb, but with a potent toxin.',
    ),
    Reward(
      id: 'rew_dried_ephedra',
      name: 'Dried Ephedra',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'Leaves as hard as scales, this plant frequents arid climates, especially dried oases.',
    ),
    Reward(
      id: 'rew_drojos_ivy',
      name: 'Drojos Ivy',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description: 'A purple creeper vine often used as jungle ropes.',
    ),
    Reward(
      id: 'rew_ellond_scrub',
      name: 'Ellond Scrub',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'A woody bush not dissimilar from a tumble weed, few know its healing properties.',
    ),
    Reward(
      id: 'rew_mandrake_root',
      name: 'Mandrake Root',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'The root of this plant shrieks when compressed. For some reason, animals enjoy it.',
    ),
    Reward(
      id: 'rew_white_poppy',
      name: 'White Poppy',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 15,
      weightPerUnit: _herbWeight,
      description:
          'A beautiful alabaster flower with a star-like shape, legend has it this plants makes you grow.',
    ),
    Reward(
      id: 'rew_kreen_paste',
      name: 'Kreen Paste',
      category: RewardCategory.herb,
      rank: Rank.E,
      marketValue: 25,
      weightPerUnit: _herbWeight,
      description:
          'No plant fosters a reputation among shaman for healing greater than this brown fungus.',
    ),

    // ---- Uncommon Herbs: Rank D, 150g value per unit ----
    Reward(
      id: 'rew_ash_chives',
      name: 'Ash Chives',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'The hollow leaves of this grey plant frequently grows best near lava.',
    ),
    Reward(
      id: 'rew_kasuni_juice',
      name: 'Kasuni Juice',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'Milky and opaque, the juice from this spherical flower is immensly slippery.',
    ),
    Reward(
      id: 'rew_frenn_moss',
      name: 'Frenn Moss',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'A moss known to grow in marshes and swamps, nothing else can make you feel luckier.',
    ),
    Reward(
      id: 'rew_spineflower_berries',
      name: 'Spineflower Berries',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'The berries of this bush plant have potent healing properties.',
    ),
    Reward(
      id: 'rew_corpse_flower',
      name: 'Corpse Flower',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'An enourmous flower found in jungles that gives off the scent of a rotting corpse.',
    ),
    Reward(
      id: 'rew_othur_stalk',
      name: 'Othur Stalk',
      category: RewardCategory.herb,
      rank: Rank.D,
      marketValue: 150,
      weightPerUnit: _herbWeight,
      description:
          'An amber stalk that enjoys lakes, rivers, and ponds, and will kill anything that smells it.',
    ),

    // ---- Rare Herbs: Rank C, 300g value per unit ----
    Reward(
      id: 'rew_chromatic_mud',
      name: 'Chromatic Mud',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'Radiating all colours of the spectrum, this mud is highly unusual.',
    ),
    Reward(
      id: 'rew_ghost_blossom',
      name: 'Ghost Blossom',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'Misting in the evenings, this plant should not be picked during the day.',
    ),
    Reward(
      id: 'rew_korins_fang',
      name: "Korin's Fang",
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description: 'This swamp-born mushroom grows at the base of sunken trees.',
    ),
    Reward(
      id: 'rew_lemurma_bell',
      name: 'Lemurma Bell',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'An eflourescent flower with a lotus-like blossom that hums when touched.',
    ),
    Reward(
      id: 'rew_olis_veritus',
      name: 'Olis Veritus',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'A razorvine that slices the hands of any who reach for it in the jungle.',
    ),
    Reward(
      id: 'rew_taggit_blossom',
      name: 'Taggit Blossom',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'A narcotic that resembls a yellow rose, these flowers grow in arctic and polar regions.',
    ),
    Reward(
      id: 'rew_ucre_bramble',
      name: 'Ucre Bramble',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'A meadow bramble that frequents plains and steppes, known for its resilience.',
    ),
    Reward(
      id: 'rew_xeni_leaves',
      name: 'Xeni Leaves',
      category: RewardCategory.herb,
      rank: Rank.C,
      marketValue: 300,
      weightPerUnit: _herbWeight,
      description:
          'Dark spalings with verdant leaves that decay rapidly when shed - leaving a smokey trail in their wake.',
    ),

    // ---- Rare+ Herbs: Rank B, 850g value per unit ----
    Reward(
      id: 'rew_spirit_petals',
      name: 'Spirit Petals',
      category: RewardCategory.herb,
      rank: Rank.B,
      marketValue: 850,
      weightPerUnit: _herbWeight,
      description:
          'A night-born plant, this glowing flower blossoms only in areas where ghosts are active or where the Ethereal Plane touches the material.',
    ),
    Reward(
      id: 'rew_lunar_nectar',
      name: 'Lunar Nectar',
      category: RewardCategory.herb,
      rank: Rank.B,
      marketValue: 850,
      weightPerUnit: _herbWeight,
      description: 'Under moonlight, the sap from this dwarf tree weeps like tears.',
    ),
    Reward(
      id: 'rew_ignant_petals',
      name: 'Ignant Petals',
      category: RewardCategory.herb,
      rank: Rank.B,
      marketValue: 850,
      weightPerUnit: _herbWeight,
      description:
          'Preferring the scorching heat of fire lakes and magma chambers, the Ignant flower should be harvested with care.',
    ),
    Reward(
      id: 'rew_wisp_stems',
      name: 'Wisp Stems',
      category: RewardCategory.herb,
      rank: Rank.B,
      marketValue: 850,
      weightPerUnit: _herbWeight,
      description:
          'A swamp-dwelling plant with a bobbing head similar to a dying dandelion.',
    ),

    // ---- Very Rare Herbs: Rank A, 1,500g value per unit ----
    Reward(
      id: 'rew_devanian_fungus',
      name: 'Devanian Fungus',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description: 'A mushroom that grows wheverever there are angels.',
    ),
    Reward(
      id: 'rew_doomsphere_whiskers',
      name: 'Doomsphere Whiskers',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description:
          'Some say that this plant is the severed hairs of a spectral beholder that grows in spawns and caves. May none of us ever find out.',
    ),
    Reward(
      id: 'rew_silverstem',
      name: 'Silverstem',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description:
          'A plant that never dies, if it is never cut. Elves and Sylvan jealously guard the locations of these herbs in hopes that none shall ever find them.',
    ),
    Reward(
      id: 'rew_galebloom',
      name: 'Galebloom',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description:
          'The windswept mountains of Parsius produced a plant that does not take root. This highly unusual seed falls from its parent tree and rides the winds for the rest of time.',
    ),
    Reward(
      id: 'rew_thunder_leaf',
      name: 'Thunder Leaf',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description: 'Wherever lightning strikes the ground, this bush will grow.',
    ),
    Reward(
      id: 'rew_viping_vitalis',
      name: 'Viping Vitalis',
      category: RewardCategory.herb,
      rank: Rank.A,
      marketValue: 1500,
      weightPerUnit: _herbWeight,
      description:
          'A red-gued ivy thatgrows like a moss favours rock-slides, cliffs, mountains, and fjords.',
    ),

    // ---- Legendary Herbs: Rank S, 5,600g value per unit ----
    Reward(
      id: 'rew_dragontongue',
      name: 'Dragontongue',
      category: RewardCategory.herb,
      rank: Rank.S,
      marketValue: 5600,
      weightPerUnit: _herbWeight,
      description:
          'Also called \'the dragon-queen\'s lover\', it is a plant that grows in the corpses of ancient dragons left to rot.',
    ),
    Reward(
      id: 'rew_voidblossom',
      name: 'Voidblossom',
      category: RewardCategory.herb,
      rank: Rank.S,
      marketValue: 5600,
      weightPerUnit: _herbWeight,
      description:
          'Three-leafed with a stem that seems to fade out of existence, the negative-energy botanical prefers the planes of Limbo and The Far Realms.',
    ),
    Reward(
      id: 'rew_arborian_ivy',
      name: 'Arborian Ivy',
      category: RewardCategory.herb,
      rank: Rank.S,
      marketValue: 5600,
      weightPerUnit: _herbWeight,
      description:
          'The Beastlands, Elysium, and Arboria could not produce a deadlier razorvine. It is said the cuts from its thorns will take your fingers off.',
    ),
    Reward(
      id: 'rew_black_lotus',
      name: 'Black Lotus',
      category: RewardCategory.herb,
      rank: Rank.S,
      marketValue: 5600,
      weightPerUnit: _herbWeight,
      description: '???',
    ),
  ];
}
