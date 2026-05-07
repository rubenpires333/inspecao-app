import 'dart:io';

const _tileProbeHost = 'tile.openstreetmap.org';

Future<bool> lookupOpenStreetMapTileHost() async {
  try {
    final list = await InternetAddress.lookup(_tileProbeHost)
        .timeout(const Duration(seconds: 3));
    return list.isNotEmpty && list.first.rawAddress.isNotEmpty;
  } catch (_) {
    return false;
  }
}
