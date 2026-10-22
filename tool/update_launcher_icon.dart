import 'dart:io';

void main() {
  final logoFile = File('assets/jigsaw.logo.png');
  if (!logoFile.existsSync()) {
    stdout.writeln('Logo file not found!');
    return;
  }

  final logoBytes = logoFile.readAsBytesSync();
  final mipmapDirs = [
    'android/app/src/main/res/mipmap-mdpi',
    'android/app/src/main/res/mipmap-hdpi',
    'android/app/src/main/res/mipmap-xhdpi',
    'android/app/src/main/res/mipmap-xxhdpi',
    'android/app/src/main/res/mipmap-xxxhdpi',
  ];

  for (final dirPath in mipmapDirs) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final iconFile = File('$dirPath/ic_launcher.png');
    iconFile.writeAsBytesSync(logoBytes);
    stdout.writeln('Updated launcher icon at: ${iconFile.path}');
  }

  stdout.writeln('All Android launcher icons successfully updated with jigsaw.logo.png!');
}
