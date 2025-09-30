import 'package:flutter/material.dart';

class AQIGridCell {
  final double latTop;
  final double lngLeft;
  final double latBottom;
  final double lngRight;
  final double aqi;

  AQIGridCell({
    required this.latTop,
    required this.lngLeft,
    required this.latBottom,
    required this.lngRight,
    required this.aqi,
  });

  // Màu theo chỉ số AQI, nhiều mức hơn và màu đậm hơn
  Color get color {
    if (aqi <= 50) return Colors.green.withOpacity(0.5);        // Tốt
    if (aqi <= 100) return Colors.yellow.withOpacity(0.4);      // Trung bình
    if (aqi <= 150) return Colors.orange.withOpacity(0.4);      // Không lành mạnh cho nhóm nhạy cảm
    if (aqi <= 200) return Colors.red.withOpacity(0.5);         // Không lành mạnh
    if (aqi <= 300) return Colors.purple.withOpacity(0.5);      // Rất không lành mạnh
    return Colors.brown.withOpacity(0.5);                       // Nguy hại
  }
}