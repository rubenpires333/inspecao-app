import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

/// Azulejos transparentes para modo offline: o fundo do mapa (cor sólida atrás do [FlutterMap])
/// fica visível; os marcadores continuam por cima.
class OfflineTransparentTileProvider extends TileProvider {
  OfflineTransparentTileProvider() : super();

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(TileProvider.transparentImage);
  }
}
