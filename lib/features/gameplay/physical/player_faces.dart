import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

import '../../../design_system/tokens/colors.dart';

/// Avatar choices. Color belongs to the player, not the icon.
class PlayerFace {
  const PlayerFace({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

/// One group in the icon panel, like a chat emoticon category.
class PlayerIconCategory {
  const PlayerIconCategory({
    required this.label,
    required this.icon,
    required this.faces,
  });

  final String label;
  final IconData icon;
  final List<PlayerFace> faces;
}

const bottleColors = PieceColors.values;

const playerColors = <Color>[
  PieceColors.crimson,
  PieceColors.tangerine,
  PieceColors.goldenYellow,
  PieceColors.chartreuse,
  PieceColors.forestGreen,
  PieceColors.emerald,
  PieceColors.turquoise,
  PieceColors.deepTeal,
  PieceColors.royalBlue,
  PieceColors.navy,
  PieceColors.violet,
  PieceColors.magenta,
];

Color playerColorFor(int playerIndex) {
  final index = playerIndex < 0 ? 0 : playerIndex % playerColors.length;
  return playerColors[index];
}

Color bottleColorFor(int bottleIndex) {
  final index = bottleIndex < 0 ? 0 : bottleIndex % bottleColors.length;
  return bottleColors[index];
}

const playerIconCategories = <PlayerIconCategory>[
  PlayerIconCategory(
    label: 'Animals',
    icon: FLucideIcons.bird,
    faces: [
      PlayerFace(label: 'Bird', icon: FLucideIcons.bird),
      PlayerFace(label: 'Birdhouse', icon: FLucideIcons.birdhouse),
      PlayerFace(label: 'Bone', icon: FLucideIcons.bone),
      PlayerFace(label: 'Bone Fracture', icon: FLucideIcons.boneFracture),
      PlayerFace(label: 'Bug', icon: FLucideIcons.bug),
      PlayerFace(label: 'Bug Off', icon: FLucideIcons.bugOff),
      PlayerFace(label: 'Bug Play', icon: FLucideIcons.bugPlay),
      PlayerFace(label: 'Cat', icon: FLucideIcons.cat),
      PlayerFace(label: 'Dog', icon: FLucideIcons.dog),
      PlayerFace(label: 'Egg', icon: FLucideIcons.egg),
      PlayerFace(label: 'Feather', icon: FLucideIcons.feather),
      PlayerFace(label: 'Fish', icon: FLucideIcons.fish),
      PlayerFace(label: 'Fish Off', icon: FLucideIcons.fishOff),
      PlayerFace(label: 'Fish Symbol', icon: FLucideIcons.fishSymbol),
      PlayerFace(label: 'Origami', icon: FLucideIcons.origami),
      PlayerFace(label: 'Panda', icon: FLucideIcons.panda),
      PlayerFace(label: 'Paw Print', icon: FLucideIcons.pawPrint),
      PlayerFace(label: 'Rabbit', icon: FLucideIcons.rabbit),
      PlayerFace(label: 'Rat', icon: FLucideIcons.rat),
      PlayerFace(label: 'Shell', icon: FLucideIcons.shell),
      PlayerFace(label: 'Shrimp', icon: FLucideIcons.shrimp),
      PlayerFace(label: 'Snail', icon: FLucideIcons.snail),
      PlayerFace(label: 'Squirrel', icon: FLucideIcons.squirrel),
      PlayerFace(label: 'Turtle', icon: FLucideIcons.turtle),
      PlayerFace(label: 'Worm', icon: FLucideIcons.worm),
    ],
  ),
  PlayerIconCategory(
    label: 'Emoji',
    icon: FLucideIcons.smile,
    faces: [
      PlayerFace(label: 'Angry', icon: FLucideIcons.angry),
      PlayerFace(label: 'Annoyed', icon: FLucideIcons.annoyed),
      PlayerFace(label: 'Frown', icon: FLucideIcons.frown),
      PlayerFace(label: 'Laugh', icon: FLucideIcons.laugh),
      PlayerFace(label: 'Meh', icon: FLucideIcons.meh),
      PlayerFace(label: 'Smile', icon: FLucideIcons.smile),
      PlayerFace(label: 'Smile Plus', icon: FLucideIcons.smilePlus),
    ],
  ),
  PlayerIconCategory(
    label: 'Food',
    icon: FLucideIcons.apple,
    faces: [
      PlayerFace(label: 'Amphora', icon: FLucideIcons.amphora),
      PlayerFace(label: 'Apple', icon: FLucideIcons.apple),
      PlayerFace(label: 'Banana', icon: FLucideIcons.banana),
      PlayerFace(label: 'Barrel', icon: FLucideIcons.barrel),
      PlayerFace(label: 'Bean', icon: FLucideIcons.bean),
      PlayerFace(label: 'Bean Off', icon: FLucideIcons.beanOff),
      PlayerFace(label: 'Beef', icon: FLucideIcons.beef),
      PlayerFace(label: 'Beef Off', icon: FLucideIcons.beefOff),
      PlayerFace(label: 'Beer', icon: FLucideIcons.beer),
      PlayerFace(label: 'Beer Off', icon: FLucideIcons.beerOff),
      PlayerFace(label: 'Blender', icon: FLucideIcons.blender),
      PlayerFace(label: 'Bottle Wine', icon: FLucideIcons.bottleWine),
      PlayerFace(label: 'Broccoli', icon: FLucideIcons.broccoli),
      PlayerFace(label: 'Cake', icon: FLucideIcons.cake),
      PlayerFace(label: 'Cake Slice', icon: FLucideIcons.cakeSlice),
      PlayerFace(label: 'Candy', icon: FLucideIcons.candy),
      PlayerFace(label: 'Candy Cane', icon: FLucideIcons.candyCane),
      PlayerFace(label: 'Candy Off', icon: FLucideIcons.candyOff),
      PlayerFace(label: 'Carrot', icon: FLucideIcons.carrot),
      PlayerFace(label: 'Chef Hat', icon: FLucideIcons.chefHat),
      PlayerFace(label: 'Cherry', icon: FLucideIcons.cherry),
      PlayerFace(label: 'Citrus', icon: FLucideIcons.citrus),
      PlayerFace(label: 'Coffee', icon: FLucideIcons.coffee),
      PlayerFace(label: 'Cookie', icon: FLucideIcons.cookie),
      PlayerFace(label: 'Cooking Pot', icon: FLucideIcons.cookingPot),
      PlayerFace(label: 'Croissant', icon: FLucideIcons.croissant),
      PlayerFace(label: 'Cuboid', icon: FLucideIcons.cuboid),
      PlayerFace(label: 'Cup Soda', icon: FLucideIcons.cupSoda),
      PlayerFace(label: 'Dessert', icon: FLucideIcons.dessert),
      PlayerFace(label: 'Dna Off', icon: FLucideIcons.dnaOff),
      PlayerFace(label: 'Donut', icon: FLucideIcons.donut),
      PlayerFace(label: 'Drumstick', icon: FLucideIcons.drumstick),
      PlayerFace(label: 'Egg', icon: FLucideIcons.egg),
      PlayerFace(label: 'Egg Fried', icon: FLucideIcons.eggFried),
      PlayerFace(label: 'Egg Off', icon: FLucideIcons.eggOff),
      PlayerFace(label: 'Fish', icon: FLucideIcons.fish),
      PlayerFace(label: 'Fish Off', icon: FLucideIcons.fishOff),
      PlayerFace(label: 'Fish Symbol', icon: FLucideIcons.fishSymbol),
      PlayerFace(label: 'Glass Water', icon: FLucideIcons.glassWater),
      PlayerFace(label: 'Grape', icon: FLucideIcons.grape),
      PlayerFace(label: 'Ham', icon: FLucideIcons.ham),
      PlayerFace(label: 'Hamburger', icon: FLucideIcons.hamburger),
      PlayerFace(label: 'Hand Platter', icon: FLucideIcons.handPlatter),
      PlayerFace(label: 'Hop', icon: FLucideIcons.hop),
      PlayerFace(label: 'Hop Off', icon: FLucideIcons.hopOff),
      PlayerFace(label: 'Ice Cream Bowl', icon: FLucideIcons.iceCreamBowl),
      PlayerFace(label: 'Ice Cream Cone', icon: FLucideIcons.iceCreamCone),
      PlayerFace(label: 'Leafy Green', icon: FLucideIcons.leafyGreen),
      PlayerFace(label: 'Lollipop', icon: FLucideIcons.lollipop),
      PlayerFace(label: 'Martini', icon: FLucideIcons.martini),
      PlayerFace(label: 'Microwave', icon: FLucideIcons.microwave),
      PlayerFace(label: 'Milk', icon: FLucideIcons.milk),
      PlayerFace(label: 'Milk Off', icon: FLucideIcons.milkOff),
      PlayerFace(label: 'Nut', icon: FLucideIcons.nut),
      PlayerFace(label: 'Nut Off', icon: FLucideIcons.nutOff),
      PlayerFace(label: 'Paper Bag', icon: FLucideIcons.paperBag),
      PlayerFace(label: 'Pizza', icon: FLucideIcons.pizza),
      PlayerFace(label: 'Popcorn', icon: FLucideIcons.popcorn),
      PlayerFace(label: 'Popsicle', icon: FLucideIcons.popsicle),
      PlayerFace(label: 'Refrigerator', icon: FLucideIcons.refrigerator),
      PlayerFace(label: 'Salad', icon: FLucideIcons.salad),
      PlayerFace(label: 'Sandwich', icon: FLucideIcons.sandwich),
      PlayerFace(label: 'Shell', icon: FLucideIcons.shell),
      PlayerFace(label: 'Shrimp', icon: FLucideIcons.shrimp),
      PlayerFace(label: 'Snail', icon: FLucideIcons.snail),
      PlayerFace(label: 'Soup', icon: FLucideIcons.soup),
      PlayerFace(label: 'Torus', icon: FLucideIcons.torus),
      PlayerFace(label: 'Tractor', icon: FLucideIcons.tractor),
      PlayerFace(label: 'Utensils', icon: FLucideIcons.utensils),
      PlayerFace(label: 'Utensils Crossed', icon: FLucideIcons.utensilsCrossed),
      PlayerFace(label: 'Vegan', icon: FLucideIcons.vegan),
      PlayerFace(label: 'Wheat', icon: FLucideIcons.wheat),
      PlayerFace(label: 'Wheat Off', icon: FLucideIcons.wheatOff),
      PlayerFace(label: 'Wine', icon: FLucideIcons.wine),
      PlayerFace(label: 'Wine Off', icon: FLucideIcons.wineOff),
    ],
  ),
  PlayerIconCategory(
    label: 'Letters',
    icon: FLucideIcons.aLargeSmall,
    faces: [
      PlayerFace(label: 'Badge Info', icon: FLucideIcons.badgeInfo),
      PlayerFace(label: 'Italic', icon: FLucideIcons.italic),
      PlayerFace(label: 'Omega', icon: FLucideIcons.omega),
      PlayerFace(label: 'Phi', icon: FLucideIcons.phi),
      PlayerFace(label: 'Pi', icon: FLucideIcons.pi),
      PlayerFace(label: 'Sigma', icon: FLucideIcons.sigma),
      PlayerFace(label: 'Square Function', icon: FLucideIcons.squareFunction),
      PlayerFace(label: 'Square Pi', icon: FLucideIcons.squarePi),
      PlayerFace(label: 'Square Sigma', icon: FLucideIcons.squareSigma),
      PlayerFace(label: 'Type', icon: FLucideIcons.type),
      PlayerFace(label: 'X', icon: FLucideIcons.x),
    ],
  ),
  PlayerIconCategory(
    label: 'Nature',
    icon: FLucideIcons.leaf,
    faces: [
      PlayerFace(label: 'Binoculars', icon: FLucideIcons.binoculars),
      PlayerFace(label: 'Birdhouse', icon: FLucideIcons.birdhouse),
      PlayerFace(label: 'Cannabis', icon: FLucideIcons.cannabis),
      PlayerFace(label: 'Cannabis Off', icon: FLucideIcons.cannabisOff),
      PlayerFace(label: 'Caravan', icon: FLucideIcons.caravan),
      PlayerFace(label: 'Clover', icon: FLucideIcons.clover),
      PlayerFace(label: 'Feather', icon: FLucideIcons.feather),
      PlayerFace(label: 'Flame Kindling', icon: FLucideIcons.flameKindling),
      PlayerFace(label: 'Flower', icon: FLucideIcons.flower),
      PlayerFace(label: 'Flower 2', icon: FLucideIcons.flower2),
      PlayerFace(label: 'Leaf', icon: FLucideIcons.leaf),
      PlayerFace(label: 'Mountain', icon: FLucideIcons.mountain),
      PlayerFace(label: 'Mountain Snow', icon: FLucideIcons.mountainSnow),
      PlayerFace(label: 'Rose', icon: FLucideIcons.rose),
      PlayerFace(label: 'Shell', icon: FLucideIcons.shell),
      PlayerFace(label: 'Shovel', icon: FLucideIcons.shovel),
      PlayerFace(label: 'Shrub', icon: FLucideIcons.shrub),
      PlayerFace(label: 'Sprout', icon: FLucideIcons.sprout),
      PlayerFace(label: 'Stone', icon: FLucideIcons.stone),
      PlayerFace(label: 'Tent', icon: FLucideIcons.tent),
      PlayerFace(label: 'Tent Tree', icon: FLucideIcons.tentTree),
      PlayerFace(label: 'Tree Deciduous', icon: FLucideIcons.treeDeciduous),
      PlayerFace(label: 'Tree Palm', icon: FLucideIcons.treePalm),
      PlayerFace(label: 'Tree Pine', icon: FLucideIcons.treePine),
      PlayerFace(label: 'Trees', icon: FLucideIcons.trees),
    ],
  ),
  PlayerIconCategory(
    label: 'Shapes',
    icon: FLucideIcons.box,
    faces: [
      PlayerFace(label: 'Astroid', icon: FLucideIcons.astroid),
      PlayerFace(label: 'Badge', icon: FLucideIcons.badge),
      PlayerFace(
        label: 'Badge Question Mark',
        icon: FLucideIcons.badgeQuestionMark,
      ),
      PlayerFace(label: 'Blocks', icon: FLucideIcons.blocks),
      PlayerFace(label: 'Box', icon: FLucideIcons.box),
      PlayerFace(label: 'Boxes', icon: FLucideIcons.boxes),
      PlayerFace(label: 'Circle', icon: FLucideIcons.circle),
      PlayerFace(label: 'Circle Dashed', icon: FLucideIcons.circleDashed),
      PlayerFace(label: 'Circle Dot', icon: FLucideIcons.circleDot),
      PlayerFace(
        label: 'Circle Dot Dashed',
        icon: FLucideIcons.circleDotDashed,
      ),
      PlayerFace(label: 'Circle Off', icon: FLucideIcons.circleOff),
      PlayerFace(label: 'Circle Pile', icon: FLucideIcons.circlePile),
      PlayerFace(label: 'Circle Slash 2', icon: FLucideIcons.circleSlash2),
      PlayerFace(label: 'Circle Small', icon: FLucideIcons.circleSmall),
      PlayerFace(label: 'Club', icon: FLucideIcons.club),
      PlayerFace(label: 'Cone', icon: FLucideIcons.cone),
      PlayerFace(label: 'Cross', icon: FLucideIcons.cross),
      PlayerFace(label: 'Cuboid', icon: FLucideIcons.cuboid),
      PlayerFace(label: 'Cylinder', icon: FLucideIcons.cylinder),
      PlayerFace(label: 'Diameter', icon: FLucideIcons.diameter),
      PlayerFace(label: 'Diamond', icon: FLucideIcons.diamond),
      PlayerFace(label: 'Dot', icon: FLucideIcons.dot),
      PlayerFace(label: 'Ellipse', icon: FLucideIcons.ellipse),
      PlayerFace(label: 'Heart', icon: FLucideIcons.heart),
      PlayerFace(label: 'Heart X', icon: FLucideIcons.heartX),
      PlayerFace(label: 'Hexagon', icon: FLucideIcons.hexagon),
      PlayerFace(label: 'Lens Concave', icon: FLucideIcons.lensConcave),
      PlayerFace(label: 'Lens Convex', icon: FLucideIcons.lensConvex),
      PlayerFace(label: 'Line Squiggle', icon: FLucideIcons.lineSquiggle),
      PlayerFace(label: 'Octagon', icon: FLucideIcons.octagon),
      PlayerFace(label: 'Octagon Alert', icon: FLucideIcons.octagonAlert),
      PlayerFace(label: 'Octagon Pause', icon: FLucideIcons.octagonPause),
      PlayerFace(label: 'Pentagon', icon: FLucideIcons.pentagon),
      PlayerFace(label: 'Pyramid', icon: FLucideIcons.pyramid),
      PlayerFace(label: 'Radius', icon: FLucideIcons.radius),
      PlayerFace(
        label: 'Rectangle Horizontal',
        icon: FLucideIcons.rectangleHorizontal,
      ),
      PlayerFace(
        label: 'Rectangle Vertical',
        icon: FLucideIcons.rectangleVertical,
      ),
      PlayerFace(label: 'Shapes', icon: FLucideIcons.shapes),
      PlayerFace(label: 'Shield', icon: FLucideIcons.shield),
      PlayerFace(label: 'Shield Cog', icon: FLucideIcons.shieldCog),
      PlayerFace(
        label: 'Shield Cog Corner',
        icon: FLucideIcons.shieldCogCorner,
      ),
      PlayerFace(label: 'Spade', icon: FLucideIcons.spade),
      PlayerFace(label: 'Sparkle', icon: FLucideIcons.sparkle),
      PlayerFace(label: 'Square', icon: FLucideIcons.square),
      PlayerFace(
        label: 'Square Arrow Right Enter',
        icon: FLucideIcons.squareArrowRightEnter,
      ),
      PlayerFace(
        label: 'Square Arrow Right Exit',
        icon: FLucideIcons.squareArrowRightExit,
      ),
      PlayerFace(label: 'Square Off', icon: FLucideIcons.squareOff),
      PlayerFace(label: 'Squircle', icon: FLucideIcons.squircle),
      PlayerFace(label: 'Squircle Dashed', icon: FLucideIcons.squircleDashed),
      PlayerFace(label: 'Star', icon: FLucideIcons.star),
      PlayerFace(label: 'Star Check', icon: FLucideIcons.starCheck),
      PlayerFace(label: 'Star Minus', icon: FLucideIcons.starMinus),
      PlayerFace(label: 'Star Plus', icon: FLucideIcons.starPlus),
      PlayerFace(label: 'Star X', icon: FLucideIcons.starX),
      PlayerFace(label: 'Tangent', icon: FLucideIcons.tangent),
      PlayerFace(label: 'Torus', icon: FLucideIcons.torus),
      PlayerFace(label: 'Triangle', icon: FLucideIcons.triangle),
      PlayerFace(label: 'Triangle Alert', icon: FLucideIcons.triangleAlert),
      PlayerFace(label: 'Triangle Dashed', icon: FLucideIcons.triangleDashed),
      PlayerFace(label: 'Triangle Right', icon: FLucideIcons.triangleRight),
      PlayerFace(label: 'Ungroup', icon: FLucideIcons.ungroup),
      PlayerFace(label: 'Vector Square', icon: FLucideIcons.vectorSquare),
    ],
  ),
  PlayerIconCategory(
    label: 'Sports',
    icon: FLucideIcons.volleyball,
    faces: [
      PlayerFace(label: 'Award', icon: FLucideIcons.award),
      PlayerFace(label: 'Biceps Flexed', icon: FLucideIcons.bicepsFlexed),
      PlayerFace(label: 'Bow Arrow', icon: FLucideIcons.bowArrow),
      PlayerFace(label: 'Circle Gauge', icon: FLucideIcons.circleGauge),
      PlayerFace(label: 'Circle Star', icon: FLucideIcons.circleStar),
      PlayerFace(label: 'Dumbbell', icon: FLucideIcons.dumbbell),
      PlayerFace(label: 'Fishing Hook', icon: FLucideIcons.fishingHook),
      PlayerFace(label: 'Fishing Rod', icon: FLucideIcons.fishingRod),
      PlayerFace(label: 'Gauge', icon: FLucideIcons.gauge),
      PlayerFace(label: 'Hand Fist', icon: FLucideIcons.handFist),
      PlayerFace(label: 'Kayak', icon: FLucideIcons.kayak),
      PlayerFace(label: 'Land Plot', icon: FLucideIcons.landPlot),
      PlayerFace(label: 'Medal', icon: FLucideIcons.medal),
      PlayerFace(label: 'Podium', icon: FLucideIcons.podium),
      PlayerFace(label: 'Sport Shoe', icon: FLucideIcons.sportShoe),
      PlayerFace(label: 'Square Star', icon: FLucideIcons.squareStar),
      PlayerFace(label: 'Trophy', icon: FLucideIcons.trophy),
      PlayerFace(label: 'Volleyball', icon: FLucideIcons.volleyball),
      PlayerFace(label: 'Waves Ladder', icon: FLucideIcons.wavesLadder),
    ],
  ),
  PlayerIconCategory(
    label: 'Tools',
    icon: FLucideIcons.hammer,
    faces: [
      PlayerFace(label: 'Anvil', icon: FLucideIcons.anvil),
      PlayerFace(label: 'Axe', icon: FLucideIcons.axe),
      PlayerFace(
        label: 'Between Horizontal End',
        icon: FLucideIcons.betweenHorizontalEnd,
      ),
      PlayerFace(
        label: 'Between Horizontal Start',
        icon: FLucideIcons.betweenHorizontalStart,
      ),
      PlayerFace(
        label: 'Between Vertical End',
        icon: FLucideIcons.betweenVerticalEnd,
      ),
      PlayerFace(
        label: 'Between Vertical Start',
        icon: FLucideIcons.betweenVerticalStart,
      ),
      PlayerFace(label: 'Blend', icon: FLucideIcons.blend),
      PlayerFace(label: 'Bolt', icon: FLucideIcons.bolt),
      PlayerFace(label: 'Bomb', icon: FLucideIcons.bomb),
      PlayerFace(label: 'Bow Arrow', icon: FLucideIcons.bowArrow),
      PlayerFace(label: 'Brush', icon: FLucideIcons.brush),
      PlayerFace(label: 'Brush Cleaning', icon: FLucideIcons.brushCleaning),
      PlayerFace(label: 'Diameter', icon: FLucideIcons.diameter),
      PlayerFace(label: 'Diamond Minus', icon: FLucideIcons.diamondMinus),
      PlayerFace(label: 'Diamond Plus', icon: FLucideIcons.diamondPlus),
      PlayerFace(label: 'Drafting Compass', icon: FLucideIcons.draftingCompass),
      PlayerFace(label: 'Drill', icon: FLucideIcons.drill),
      PlayerFace(
        label: 'Fire Extinguisher',
        icon: FLucideIcons.fireExtinguisher,
      ),
      PlayerFace(label: 'Gavel', icon: FLucideIcons.gavel),
      PlayerFace(label: 'Hammer', icon: FLucideIcons.hammer),
      PlayerFace(label: 'Hard Hat', icon: FLucideIcons.hardHat),
      PlayerFace(label: 'Inspection Panel', icon: FLucideIcons.inspectionPanel),
      PlayerFace(label: 'Land Plot', icon: FLucideIcons.landPlot),
      PlayerFace(label: 'Lens Concave', icon: FLucideIcons.lensConcave),
      PlayerFace(label: 'Lens Convex', icon: FLucideIcons.lensConvex),
      PlayerFace(label: 'Line Style', icon: FLucideIcons.lineStyle),
      PlayerFace(label: 'Minus', icon: FLucideIcons.minus),
      PlayerFace(
        label: 'Mirror Rectangular',
        icon: FLucideIcons.mirrorRectangular,
      ),
      PlayerFace(label: 'Mirror Round', icon: FLucideIcons.mirrorRound),
      PlayerFace(label: 'Paint Bucket', icon: FLucideIcons.paintBucket),
      PlayerFace(label: 'Paint Roller', icon: FLucideIcons.paintRoller),
      PlayerFace(label: 'Paintbrush', icon: FLucideIcons.paintbrush),
      PlayerFace(
        label: 'Paintbrush Vertical',
        icon: FLucideIcons.paintbrushVertical,
      ),
      PlayerFace(label: 'Pen', icon: FLucideIcons.pen),
      PlayerFace(label: 'Pen Line', icon: FLucideIcons.penLine),
      PlayerFace(label: 'Pen Off', icon: FLucideIcons.penOff),
      PlayerFace(label: 'Pencil', icon: FLucideIcons.pencil),
      PlayerFace(label: 'Pencil Line', icon: FLucideIcons.pencilLine),
      PlayerFace(label: 'Pencil Off', icon: FLucideIcons.pencilOff),
      PlayerFace(label: 'Pencil Ruler', icon: FLucideIcons.pencilRuler),
      PlayerFace(label: 'Pencil Sparkles', icon: FLucideIcons.pencilSparkles),
      PlayerFace(label: 'Pickaxe', icon: FLucideIcons.pickaxe),
      PlayerFace(label: 'Plus', icon: FLucideIcons.plus),
      PlayerFace(label: 'Pocket Knife', icon: FLucideIcons.pocketKnife),
      PlayerFace(label: 'Radius', icon: FLucideIcons.radius),
      PlayerFace(
        label: 'Rotate Ccw Square',
        icon: FLucideIcons.rotateCcwSquare,
      ),
      PlayerFace(label: 'Rotate Cw Square', icon: FLucideIcons.rotateCwSquare),
      PlayerFace(label: 'Ruler', icon: FLucideIcons.ruler),
      PlayerFace(
        label: 'Ruler Dimension Line',
        icon: FLucideIcons.rulerDimensionLine,
      ),
      PlayerFace(label: 'Scissors', icon: FLucideIcons.scissors),
      PlayerFace(
        label: 'Scissors Line Dashed',
        icon: FLucideIcons.scissorsLineDashed,
      ),
      PlayerFace(label: 'Shovel', icon: FLucideIcons.shovel),
      PlayerFace(label: 'Spline Pointer', icon: FLucideIcons.splinePointer),
      PlayerFace(label: 'Spool', icon: FLucideIcons.spool),
      PlayerFace(label: 'Spray Can', icon: FLucideIcons.sprayCan),
      PlayerFace(
        label: 'Square Bottom Dashed Scissors',
        icon: FLucideIcons.squareBottomDashedScissors,
      ),
      PlayerFace(
        label: 'Square Dashed Mouse Pointer',
        icon: FLucideIcons.squareDashedMousePointer,
      ),
      PlayerFace(label: 'Square Minus', icon: FLucideIcons.squareMinus),
      PlayerFace(
        label: 'Square Mouse Pointer',
        icon: FLucideIcons.squareMousePointer,
      ),
      PlayerFace(label: 'Square Plus', icon: FLucideIcons.squarePlus),
      PlayerFace(label: 'Square Scissors', icon: FLucideIcons.squareScissors),
      PlayerFace(label: 'Stamp', icon: FLucideIcons.stamp),
      PlayerFace(label: 'Sword', icon: FLucideIcons.sword),
      PlayerFace(label: 'Swords', icon: FLucideIcons.swords),
      PlayerFace(
        label: 'Tablet Smartphone',
        icon: FLucideIcons.tabletSmartphone,
      ),
      PlayerFace(label: 'Tangent', icon: FLucideIcons.tangent),
      PlayerFace(label: 'Telescope', icon: FLucideIcons.telescope),
      PlayerFace(label: 'Tool Case', icon: FLucideIcons.toolCase),
      PlayerFace(label: 'Toolbox', icon: FLucideIcons.toolbox),
      PlayerFace(label: 'Torus', icon: FLucideIcons.torus),
      PlayerFace(label: 'Vector Square', icon: FLucideIcons.vectorSquare),
      PlayerFace(label: 'Wrench', icon: FLucideIcons.wrench),
      PlayerFace(label: 'Wrench Off', icon: FLucideIcons.wrenchOff),
    ],
  ),
  PlayerIconCategory(
    label: 'Transportation',
    icon: FLucideIcons.car,
    faces: [
      PlayerFace(label: 'Ambulance', icon: FLucideIcons.ambulance),
      PlayerFace(label: 'Bike', icon: FLucideIcons.bike),
      PlayerFace(label: 'Bus', icon: FLucideIcons.bus),
      PlayerFace(label: 'Cable Car', icon: FLucideIcons.cableCar),
      PlayerFace(label: 'Car', icon: FLucideIcons.car),
      PlayerFace(label: 'Car Front', icon: FLucideIcons.carFront),
      PlayerFace(label: 'Car Taxi Front', icon: FLucideIcons.carTaxiFront),
      PlayerFace(label: 'Caravan', icon: FLucideIcons.caravan),
      PlayerFace(label: 'Drone', icon: FLucideIcons.drone),
      PlayerFace(label: 'Forklift', icon: FLucideIcons.forklift),
      PlayerFace(label: 'Helicopter', icon: FLucideIcons.helicopter),
      PlayerFace(label: 'Kayak', icon: FLucideIcons.kayak),
      PlayerFace(label: 'Motorbike', icon: FLucideIcons.motorbike),
      PlayerFace(label: 'Plane', icon: FLucideIcons.plane),
      PlayerFace(label: 'Plane Landing', icon: FLucideIcons.planeLanding),
      PlayerFace(label: 'Plane Takeoff', icon: FLucideIcons.planeTakeoff),
      PlayerFace(label: 'Sailboat', icon: FLucideIcons.sailboat),
      PlayerFace(label: 'Scooter', icon: FLucideIcons.scooter),
      PlayerFace(label: 'Ship', icon: FLucideIcons.ship),
      PlayerFace(label: 'Tractor', icon: FLucideIcons.tractor),
      PlayerFace(label: 'Train Front', icon: FLucideIcons.trainFront),
      PlayerFace(
        label: 'Train Front Tunnel',
        icon: FLucideIcons.trainFrontTunnel,
      ),
      PlayerFace(label: 'Tram Front', icon: FLucideIcons.tramFront),
      PlayerFace(label: 'Truck', icon: FLucideIcons.truck),
      PlayerFace(label: 'Truck Electric', icon: FLucideIcons.truckElectric),
      PlayerFace(label: 'Van', icon: FLucideIcons.van),
    ],
  ),
];

List<PlayerFace> get playerFaces => [
  for (final category in playerIconCategories) ...category.faces,
];

int playerIconCategoryIndexFor(int? faceIndex) {
  if (faceIndex == null || faceIndex < 0) {
    return 0;
  }
  var offset = 0;
  for (var index = 0; index < playerIconCategories.length; index++) {
    final count = playerIconCategories[index].faces.length;
    if (faceIndex < offset + count) {
      return index;
    }
    offset += count;
  }
  return 0;
}

PlayerFace playerFaceFor(int index) {
  final faces = playerFaces;
  if (faces.isEmpty) {
    return const PlayerFace(label: 'Bird', icon: FLucideIcons.bird);
  }
  final safe = index < 0 ? 0 : index % faces.length;
  return faces[safe];
}
