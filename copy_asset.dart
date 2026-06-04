import 'dart:io';

void main() {
  const sourcePath =
      r'C:\Users\ACER\.gemini\antigravity\brain\54eb9a30-a55c-4a2b-9516-9a57b050f85f\uploaded_image_1767860929736.png';
  const destPath = r'd:\taptom\assets\images\news_gap.png';

  try {
    final sourceFile = File(sourcePath);
    if (!sourceFile.existsSync()) {
      print('Source file not found: $sourcePath');
      return;
    }

    sourceFile.copySync(destPath);
    print('SUCCESS: Copied to $destPath');
    print('File size: ${File(destPath).lengthSync()} bytes');
  } catch (e) {
    print('ERROR: $e');
  }
}
