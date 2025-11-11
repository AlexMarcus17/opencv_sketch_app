// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ImageProjectAdapter extends TypeAdapter<ImageProject> {
  @override
  final int typeId = 1;

  @override
  ImageProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ImageProject(
      id: fields[0] as String,
      name: fields[1] as String,
      originalImage: fields[10] as String,
      processedImage: fields[11] as String,
      filterMode: fields[2] as FilterMode,
      aspectRatioMode: fields[3] as AspectRatioMode,
      cropRect: fields[4] as CropRectData?,
      saturation: fields[12] as int?,
      brightness: fields[13] as int?,
      contrast: fields[14] as int?,
      temperature: fields[15] as int?,
      sharpen: fields[16] as int?,
      blur: fields[17] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ImageProject obj) {
    writer
      ..writeByte(13)
      ..writeByte(10)
      ..write(obj.originalImage)
      ..writeByte(11)
      ..write(obj.processedImage)
      ..writeByte(12)
      ..write(obj.saturation)
      ..writeByte(13)
      ..write(obj.brightness)
      ..writeByte(14)
      ..write(obj.contrast)
      ..writeByte(15)
      ..write(obj.temperature)
      ..writeByte(16)
      ..write(obj.sharpen)
      ..writeByte(17)
      ..write(obj.blur)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filterMode)
      ..writeByte(3)
      ..write(obj.aspectRatioMode)
      ..writeByte(4)
      ..write(obj.cropRect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VideoProjectAdapter extends TypeAdapter<VideoProject> {
  @override
  final int typeId = 2;

  @override
  VideoProject read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VideoProject(
      id: fields[0] as String,
      name: fields[1] as String,
      originalVideo: fields[20] as String,
      processedVideo: fields[21] as String,
      filterMode: fields[2] as FilterMode,
      aspectRatioMode: fields[3] as AspectRatioMode,
      cropRect: fields[4] as CropRectData?,
      saturation: fields[22] as int?,
      brightness: fields[23] as int?,
      contrast: fields[24] as int?,
      blur: fields[25] as int?,
      temperature: fields[26] as int?,
      sharpen: fields[27] as int?,
      speed: fields[28] as double?,
      extractedFramePaths: (fields[29] as List?)?.cast<String>(),
      totalFrameCount: fields[30] as int?,
      originalDuration: fields[31] as double?,
      originalFPS: fields[32] as double?,
      framesDirectory: fields[33] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VideoProject obj) {
    writer
      ..writeByte(19)
      ..writeByte(20)
      ..write(obj.originalVideo)
      ..writeByte(21)
      ..write(obj.processedVideo)
      ..writeByte(22)
      ..write(obj.saturation)
      ..writeByte(23)
      ..write(obj.brightness)
      ..writeByte(24)
      ..write(obj.contrast)
      ..writeByte(25)
      ..write(obj.blur)
      ..writeByte(26)
      ..write(obj.temperature)
      ..writeByte(27)
      ..write(obj.sharpen)
      ..writeByte(28)
      ..write(obj.speed)
      ..writeByte(29)
      ..write(obj.extractedFramePaths)
      ..writeByte(30)
      ..write(obj.totalFrameCount)
      ..writeByte(31)
      ..write(obj.originalDuration)
      ..writeByte(32)
      ..write(obj.originalFPS)
      ..writeByte(33)
      ..write(obj.framesDirectory)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.filterMode)
      ..writeByte(3)
      ..write(obj.aspectRatioMode)
      ..writeByte(4)
      ..write(obj.cropRect);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CropRectDataAdapter extends TypeAdapter<CropRectData> {
  @override
  final int typeId = 0;

  @override
  CropRectData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CropRectData(
      left: fields[0] as double,
      top: fields[1] as double,
      right: fields[2] as double,
      bottom: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, CropRectData obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.left)
      ..writeByte(1)
      ..write(obj.top)
      ..writeByte(2)
      ..write(obj.right)
      ..writeByte(3)
      ..write(obj.bottom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CropRectDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
