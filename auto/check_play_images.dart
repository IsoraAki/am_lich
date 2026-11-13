import 'dart:io';
import 'dart:typed_data';

const imageExtensions = {'.png', '.jpg', '.jpeg'};
const mb = 1024 * 1024;

class ImageInfo {
  const ImageInfo({
    required this.format,
    required this.width,
    required this.height,
  });

  final String format;
  final int width;
  final int height;
}

String extensionOf(String path) {
  final index = path.lastIndexOf('.');
  return index == -1 ? '' : path.substring(index).toLowerCase();
}

ImageInfo? detectImage(File file) {
  final bytes = file.readAsBytesSync();

  if (_isPng(bytes)) {
    final data = ByteData.sublistView(bytes);
    return ImageInfo(
      format: 'PNG',
      width: data.getUint32(16),
      height: data.getUint32(20),
    );
  }

  if (_isJpeg(bytes)) {
    return _detectJpeg(bytes);
  }

  return null;
}

bool _isPng(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length < 24) return false;

  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }

  return true;
}

bool _isJpeg(Uint8List bytes) {
  return bytes.length >= 4 && bytes[0] == 0xFF && bytes[1] == 0xD8;
}

ImageInfo? _detectJpeg(Uint8List bytes) {
  var index = 2;

  while (index < bytes.length) {
    while (index < bytes.length && bytes[index] != 0xFF) {
      index++;
    }
    while (index < bytes.length && bytes[index] == 0xFF) {
      index++;
    }
    if (index >= bytes.length) return null;

    final marker = bytes[index++];
    if (marker == 0xD9 || marker == 0xDA) return null;
    if (marker == 0x01 || (marker >= 0xD0 && marker <= 0xD7)) continue;
    if (index + 1 >= bytes.length) return null;

    final length = (bytes[index] << 8) + bytes[index + 1];
    index += 2;

    if (length < 2 || index + length - 2 > bytes.length) return null;

    if (_isStartOfFrame(marker)) {
      if (length < 7) return null;

      final height = (bytes[index + 1] << 8) + bytes[index + 2];
      final width = (bytes[index + 3] << 8) + bytes[index + 4];
      return ImageInfo(format: 'JPEG', width: width, height: height);
    }

    index += length - 2;
  }

  return null;
}

bool _isStartOfFrame(int marker) {
  return const {
    0xC0,
    0xC1,
    0xC2,
    0xC3,
    0xC5,
    0xC6,
    0xC7,
    0xC9,
    0xCA,
    0xCB,
    0xCD,
    0xCE,
    0xCF,
  }.contains(marker);
}

List<File> imageFiles(Directory directory) {
  if (!directory.existsSync()) return [];

  return directory
      .listSync()
      .whereType<File>()
      .where((file) => imageExtensions.contains(extensionOf(file.path)))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}

List<String> unsupportedFiles(Directory directory) {
  if (!directory.existsSync()) return [];

  return directory
      .listSync()
      .whereType<File>()
      .where((file) => !file.uri.pathSegments.last.startsWith('.'))
      .where((file) => !imageExtensions.contains(extensionOf(file.path)))
      .map((file) => file.uri.pathSegments.last)
      .toList()
    ..sort();
}

({ImageInfo? info, List<String> errors}) validateFile(File file, int maxBytes) {
  final errors = <String>[];
  final ext = extensionOf(file.path);
  final info = imageExtensions.contains(ext) ? detectImage(file) : null;

  if (info == null) errors.add('must be PNG or JPEG');
  if (file.lengthSync() > maxBytes) {
    errors.add('must be maximum ${maxBytes ~/ mb} MB');
  }

  return (info: info, errors: errors);
}

List<String> validateNamedImage({
  required Directory imagesDir,
  required String label,
  required String baseName,
  String? folderName,
  required int maxBytes,
  required int requiredWidth,
  required int requiredHeight,
}) {
  final rootMatches = imageExtensions
      .map(
        (ext) =>
            File('${imagesDir.path}${Platform.pathSeparator}$baseName$ext'),
      )
      .where((file) => file.existsSync())
      .toList();
  final folder = folderName == null
      ? null
      : Directory('${imagesDir.path}${Platform.pathSeparator}$folderName');
  final folderMatches = folder == null ? <File>[] : imageFiles(folder);
  final matches = folderMatches.isNotEmpty ? folderMatches : rootMatches;
  final errors = <String>[];

  if (folder != null) {
    errors.addAll(
      unsupportedFiles(
        folder,
      ).map((name) => '$label: $folderName/$name must be PNG or JPEG'),
    );
  }

  if (matches.isEmpty) {
    final folderHint = folderName == null ? '' : ' or $folderName/';
    errors.add('$label: missing $baseName.png/.jpg/.jpeg$folderHint');
    return errors;
  }

  if (matches.length > 1) {
    errors.add('$label: keep only one $baseName image');
  }

  for (final file in matches) {
    final result = validateFile(file, maxBytes);
    final name = file.uri.pathSegments.last;
    errors.addAll(result.errors.map((message) => '$label: $name $message'));

    final info = result.info;
    if (info == null) continue;

    if (info.width != requiredWidth || info.height != requiredHeight) {
      errors.add(
        '$label: $name must be ${requiredWidth}x${requiredHeight}px, got ${info.width}x${info.height}px',
      );
    }
  }

  return errors;
}

List<String> validateScreenshots({
  required Directory imagesDir,
  required String label,
  required String folderName,
  required int minCount,
  required int maxCount,
}) {
  final folder = Directory(
    '${imagesDir.path}${Platform.pathSeparator}$folderName',
  );
  final files = imageFiles(folder);
  final errors = <String>[];

  errors.addAll(
    unsupportedFiles(folder).map((name) => '$label: $name must be PNG or JPEG'),
  );

  if (files.length < minCount) {
    errors.add(
      '$label: needs at least $minCount screenshot(s), found ${files.length}',
    );
  }

  if (files.length > maxCount) {
    errors.add(
      '$label: allows at most $maxCount screenshots, found ${files.length}',
    );
  }

  for (final file in files) {
    final result = validateFile(file, 8 * mb);
    final name = file.uri.pathSegments.last;
    errors.addAll(result.errors.map((message) => '$label: $name $message'));

    final info = result.info;
    if (info == null) continue;

    if ([info.width, info.height].any((side) => side < 320 || side > 3840)) {
      errors.add(
        '$label: $name sides must be between 320px and 3840px, got ${info.width}x${info.height}px',
      );
    }
  }

  return errors;
}

void main() {
  final scriptDir = File.fromUri(Platform.script).parent;
  final rootDir = scriptDir.parent;
  final imagesDir = Directory(
    '${rootDir.path}${Platform.pathSeparator}android'
    '${Platform.pathSeparator}fastlane'
    '${Platform.pathSeparator}metadata'
    '${Platform.pathSeparator}android'
    '${Platform.pathSeparator}vi'
    '${Platform.pathSeparator}images',
  );

  final errors = <String>[
    ...validateNamedImage(
      imagesDir: imagesDir,
      label: 'Logo app',
      baseName: 'icon',
      folderName: 'icon',
      maxBytes: 1 * mb,
      requiredWidth: 512,
      requiredHeight: 512,
    ),
    ...validateNamedImage(
      imagesDir: imagesDir,
      label: 'Ảnh nổi bật',
      baseName: 'featureGraphic',
      folderName: 'featureGraphic',
      maxBytes: 15 * mb,
      requiredWidth: 1024,
      requiredHeight: 500,
    ),
    ...validateScreenshots(
      imagesDir: imagesDir,
      label: 'Ảnh chụp màn hình điện thoại',
      folderName: 'phoneScreenshots',
      minCount: 2,
      maxCount: 8,
    ),
    ...validateScreenshots(
      imagesDir: imagesDir,
      label: '7-inch tablet screenshots',
      folderName: 'sevenInchScreenshots',
      minCount: 0,
      maxCount: 8,
    ),
  ];

  if (errors.isEmpty) {
    stdout.writeln('Bộ ảnh cho Google Play ổn.');
    exitCode = 0;
    return;
  }

  stderr.writeln('Kiểm tra ảnh Google Play không đạt:');
  for (final error in errors) {
    stderr.writeln('- $error');
  }
  exitCode = 1;
}
