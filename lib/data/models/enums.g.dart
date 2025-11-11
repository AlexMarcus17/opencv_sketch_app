// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FilterModeAdapter extends TypeAdapter<FilterMode> {
  @override
  final int typeId = 3;

  @override
  FilterMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FilterMode.original;
      case 1:
        return FilterMode.pencilSketch;
      case 2:
        return FilterMode.charcoalSketch;
      case 3:
        return FilterMode.inkPen;
      case 4:
        return FilterMode.colorSketch;
      case 5:
        return FilterMode.cartoon;
      case 6:
        return FilterMode.techPen;
      case 7:
        return FilterMode.softPen;
      case 8:
        return FilterMode.noirSketch;
      case 9:
        return FilterMode.cartoon2;
      case 10:
        return FilterMode.storyboard;
      case 11:
        return FilterMode.chalk;
      case 12:
        return FilterMode.feltPen;
      case 13:
        return FilterMode.monochromeSketch;
      case 14:
        return FilterMode.splashSketch;
      case 15:
        return FilterMode.coloringBook;
      case 16:
        return FilterMode.waxSketch;
      case 17:
        return FilterMode.paperSketch;
      case 18:
        return FilterMode.neonSketch;
      case 19:
        return FilterMode.anime;
      case 20:
        return FilterMode.comicBook;
      default:
        return FilterMode.original;
    }
  }

  @override
  void write(BinaryWriter writer, FilterMode obj) {
    switch (obj) {
      case FilterMode.original:
        writer.writeByte(0);
        break;
      case FilterMode.pencilSketch:
        writer.writeByte(1);
        break;
      case FilterMode.charcoalSketch:
        writer.writeByte(2);
        break;
      case FilterMode.inkPen:
        writer.writeByte(3);
        break;
      case FilterMode.colorSketch:
        writer.writeByte(4);
        break;
      case FilterMode.cartoon:
        writer.writeByte(5);
        break;
      case FilterMode.techPen:
        writer.writeByte(6);
        break;
      case FilterMode.softPen:
        writer.writeByte(7);
        break;
      case FilterMode.noirSketch:
        writer.writeByte(8);
        break;
      case FilterMode.cartoon2:
        writer.writeByte(9);
        break;
      case FilterMode.storyboard:
        writer.writeByte(10);
        break;
      case FilterMode.chalk:
        writer.writeByte(11);
        break;
      case FilterMode.feltPen:
        writer.writeByte(12);
        break;
      case FilterMode.monochromeSketch:
        writer.writeByte(13);
        break;
      case FilterMode.splashSketch:
        writer.writeByte(14);
        break;
      case FilterMode.coloringBook:
        writer.writeByte(15);
        break;
      case FilterMode.waxSketch:
        writer.writeByte(16);
        break;
      case FilterMode.paperSketch:
        writer.writeByte(17);
        break;
      case FilterMode.neonSketch:
        writer.writeByte(18);
        break;
      case FilterMode.anime:
        writer.writeByte(19);
        break;
      case FilterMode.comicBook:
        writer.writeByte(20);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FilterModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AspectRatioModeAdapter extends TypeAdapter<AspectRatioMode> {
  @override
  final int typeId = 4;

  @override
  AspectRatioMode read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AspectRatioMode.original;
      case 1:
        return AspectRatioMode.custom;
      case 2:
        return AspectRatioMode.square;
      case 3:
        return AspectRatioMode.fourThree;
      case 4:
        return AspectRatioMode.sixteenNine;
      case 5:
        return AspectRatioMode.nineSixteen;
      case 6:
        return AspectRatioMode.threeFour;
      case 7:
        return AspectRatioMode.threeTwo;
      case 8:
        return AspectRatioMode.twoThree;
      default:
        return AspectRatioMode.original;
    }
  }

  @override
  void write(BinaryWriter writer, AspectRatioMode obj) {
    switch (obj) {
      case AspectRatioMode.original:
        writer.writeByte(0);
        break;
      case AspectRatioMode.custom:
        writer.writeByte(1);
        break;
      case AspectRatioMode.square:
        writer.writeByte(2);
        break;
      case AspectRatioMode.fourThree:
        writer.writeByte(3);
        break;
      case AspectRatioMode.sixteenNine:
        writer.writeByte(4);
        break;
      case AspectRatioMode.nineSixteen:
        writer.writeByte(5);
        break;
      case AspectRatioMode.threeFour:
        writer.writeByte(6);
        break;
      case AspectRatioMode.threeTwo:
        writer.writeByte(7);
        break;
      case AspectRatioMode.twoThree:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AspectRatioModeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
