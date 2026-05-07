import 'map_tile_lookup_stub.dart'
    if (dart.library.io) 'map_tile_lookup_io.dart' as impl;

/// Verifica se o host dos azulejos OSM é resolvível (útil quando há Wi‑Fi sem Internet).
Future<bool> lookupOpenStreetMapTileHost() => impl.lookupOpenStreetMapTileHost();
