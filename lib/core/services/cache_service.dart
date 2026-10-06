import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

class CacheService {
  Future<void> clearAllCache() async {
    try {
      // 1. Clear Image Cache (Memory)
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      // 2. Clear Temporary Directory (Disk)
      final tempDir = await getTemporaryDirectory();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (e) {
      // Log error or silently fail (it's cache clearing, not critical)
      debugPrint('Error clearing cache: $e');
    }
  }
}
