import 'package:latlong2/latlong.dart';

class DanangConstants {
  // Tọa độ trung tâm thành phố Đà Nẵng
  static const LatLng centerDaNang = LatLng(16.0544, 108.2022);

  // Tọa độ các điểm chính
  static const LatLng dragonBridge = LatLng(16.0610, 108.2272);
  static const LatLng sonTraPeninsula = LatLng(16.1000, 108.2778);
  static const LatLng myKheBeach = LatLng(16.0602, 108.2462);
  static const LatLng marbleMountains = LatLng(16.0044, 108.2618);
  static const LatLng nonNuocStoneVillage = LatLng(16.0028, 108.2639);
  static const LatLng chamMuseum = LatLng(16.0601, 108.2235);
  static const LatLng hanMarket = LatLng(16.0684, 108.2241);

  // Zoom levels
  static const double defaultZoom = 13.0;
  static const double cityZoom = 11.5;
  static const double detailZoom = 16.0;

  // OpenStreetMap Tile URL
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
