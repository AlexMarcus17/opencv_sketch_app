import 'package:hive/hive.dart';

part 'enums.g.dart';

@HiveType(typeId: 3)
enum FilterMode {
  @HiveField(0)
  original,
  @HiveField(1)
  pencilSketch,
  @HiveField(2)
  charcoalSketch,
  @HiveField(3)
  inkPen,
  @HiveField(4)
  colorSketch,
  @HiveField(5)
  cartoon,
  @HiveField(6)
  techPen,
  @HiveField(7)
  softPen,
  @HiveField(8)
  noirSketch,
  @HiveField(9)
  cartoon2,
  @HiveField(10)
  storyboard,
  @HiveField(11)
  chalk,
  @HiveField(12)
  feltPen,
  @HiveField(13)
  monochromeSketch,
  @HiveField(14)
  splashSketch,
  @HiveField(15)
  coloringBook,
  @HiveField(16)
  waxSketch,
  @HiveField(17)
  paperSketch,
  @HiveField(18)
  neonSketch,
  @HiveField(19)
  anime,
  @HiveField(20)
  comicBook,
}

@HiveType(typeId: 4)
enum AspectRatioMode {
  @HiveField(0)
  original,
  @HiveField(1)
  custom,
  @HiveField(2)
  square,
  @HiveField(3)
  fourThree,
  @HiveField(4)
  sixteenNine,
  @HiveField(5)
  nineSixteen,
  @HiveField(6)
  threeFour,
  @HiveField(7)
  threeTwo,
  @HiveField(8)
  twoThree,
}
