/// One bottle picture. The image is already colored.
/// Letters are assigned per round, from the opening order.
class BottleFace {
  const BottleFace({required this.label, required this.asset});

  final String label;
  final String asset;
}

const bottleFaces = <BottleFace>[
  BottleFace(
    label: 'Pink Heart',
    asset: 'assets/images/bottles/01 Pink Heart.png',
  ),
  BottleFace(
    label: 'Yellow Star',
    asset: 'assets/images/bottles/02 Yellow Star.png',
  ),
  BottleFace(label: 'Cyan Cat', asset: 'assets/images/bottles/03 Cyan Cat.png'),
  BottleFace(
    label: 'Green Leaf',
    asset: 'assets/images/bottles/04 Green Leaf.png',
  ),
  BottleFace(
    label: 'Purple Moon',
    asset: 'assets/images/bottles/05 Purple Moon.png',
  ),
  BottleFace(
    label: 'Orange Paw',
    asset: 'assets/images/bottles/06 Orange Paw.png',
  ),
  BottleFace(
    label: 'Blue Galaxy',
    asset: 'assets/images/bottles/07 Blue Galaxy.png',
  ),
  BottleFace(
    label: 'Lime Cool',
    asset: 'assets/images/bottles/08 Lime Cool.png',
  ),
  BottleFace(
    label: 'Magenta Bow',
    asset: 'assets/images/bottles/09 Magenta Bow.png',
  ),
  BottleFace(
    label: 'Aqua Bubbles',
    asset: 'assets/images/bottles/10 Aqua Bubbles.png',
  ),
  BottleFace(
    label: 'Violet Crown',
    asset: 'assets/images/bottles/11 Violet Crown.png',
  ),
  BottleFace(
    label: 'Blue Snow',
    asset: 'assets/images/bottles/12 Blue Snow.png',
  ),
  BottleFace(
    label: 'Gold Rainbow',
    asset: 'assets/images/bottles/13 Gold Rainbow.png',
  ),
  BottleFace(
    label: 'Coral Flower',
    asset: 'assets/images/bottles/14 Coral Flower.png',
  ),
  BottleFace(
    label: 'Electric Waves',
    asset: 'assets/images/bottles/15 Electric Waves.png',
  ),
];

BottleFace bottleFaceFor(int bottle) {
  final index = bottle < 0 ? 0 : bottle % bottleFaces.length;
  return bottleFaces[index];
}
