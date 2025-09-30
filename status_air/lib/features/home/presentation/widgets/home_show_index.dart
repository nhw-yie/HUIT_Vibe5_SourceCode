import 'package:flutter/material.dart';
import 'package:status_air/features/home/presentation/widgets/aqi_line_chart.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  // Hàm chọn màu gradient theo AQI
  LinearGradient _aqiGradient(int aqi) {
    if (aqi <= 50) {
      return const LinearGradient(
        colors: [Color(0xFF4CAF50), Color(0xFF81C784)], // Green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    } else if (aqi <= 100) {
      return const LinearGradient(
        colors: [Color(0xFFFFEB3B), Color(0xFFFFF176)], // Yellow
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    } else if (aqi <= 150) {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFFB74D)], // Orange
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    } else if (aqi <= 200) {
      return const LinearGradient(
        colors: [Color(0xFFE53935), Color(0xFFEF5350)], // Red
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    } else if (aqi <= 300) {
      return const LinearGradient(
        colors: [Color(0xFF8E24AA), Color(0xFFBA68C8)], // Purple
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    } else {
      return const LinearGradient(
        colors: [Color(0xFF6A1B9A), Color(0xFFD32F2F)], // Maroon
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 1.0],
      );
    }
  }

  // Hàm tính màu chữ hợp lý dựa trên độ sáng trung bình của gradient
  Color _textColorForGradient(LinearGradient gradient) {
    final start = gradient.colors.first;
    final end = gradient.colors.last;
    final brightness = (start.computeLuminance() + end.computeLuminance()) / 2;
    return brightness > 0.5 ? Colors.black : Colors.white;
  }

  // Hàm hiển thị cảnh báo theo AQI
  Widget _aqiAlert(int aqi) {
    String message;
    IconData icon;

    if (aqi <= 50) {
      message = "🌿 Không khí tốt. Bạn có thể ra ngoài bình thường.";
      icon = Icons.sentiment_satisfied;
    } else if (aqi <= 100) {
      message = "🙂 Không khí trung bình. Hạn chế nhóm nhạy cảm ra ngoài.";
      icon = Icons.sentiment_neutral;
    } else if (aqi <= 150) {
      message = "⚠️ Không lành mạnh cho nhóm nhạy cảm. Hạn chế ra ngoài.";
      icon = Icons.warning;
    } else if (aqi <= 200) {
      message = "🚨 Không lành mạnh. Nên ở trong nhà và đeo khẩu trang.";
      icon = Icons.dangerous;
    } else if (aqi <= 300) {
      message = "☠️ Rất không lành mạnh. Tránh ra ngoài.";
      icon = Icons.report;
    } else {
      message = "💀 Nguy hại. Ở trong nhà tuyệt đối, không ra ngoài.";
      icon = Icons.warning_amber_rounded;
    }

    final gradient = _aqiGradient(aqi);
    final textColor = _textColorForGradient(gradient);

    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const int currentAQI = 50;
    const String airQuality = "Không lành mạnh cho nhóm nhạy cảm";

    final gradientAQI = _aqiGradient(currentAQI);
    final textColorAQI = _textColorForGradient(gradientAQI);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 📍 Vị trí hiện tại
          Row(
            children: const [
              Icon(Icons.location_on, color: Colors.blue),
              SizedBox(width: 6),
              Text(
                "Phường Trung Mỹ Tây , TP. Hồ Chí Minh",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🌫 AQI hiện tại
          Container(
            decoration: BoxDecoration(
              gradient: gradientAQI,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  "AQI: $currentAQI",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: textColorAQI,
                  ),
                ),
                Text(
                  "Chất lượng không khí: $airQuality",
                  style: TextStyle(
                    color: textColorAQI.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ⚗️ Thông tin chi tiết các chất ô nhiễm
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: const [
              _PollutantCard(
                label: "PM2.5",
                value: "12",
                unit: "µg/m³",
                icon: Icons.blur_on,
              ),
              _PollutantCard(
                label: "PM10",
                value: "25",
                unit: "µg/m³",
                icon: Icons.cloud,
              ),
              _PollutantCard(
                label: "CO",
                value: "0.8",
                unit: "ppm",
                icon: Icons.local_fire_department,
              ),
              _PollutantCard(
                label: "NO₂",
                value: "21",
                unit: "ppb",
                icon: Icons.factory,
              ),
              _PollutantCard(
                label: "O₃",
                value: "30",
                unit: "ppb",
                icon: Icons.waves,
              ),
              _PollutantCard(
                label: "SO₂",
                value: "5",
                unit: "ppb",
                icon: Icons.coronavirus,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 📊 Biểu đồ xu hướng (placeholder)
          SizedBox(
            height: 200,
            child: AQILineChart(
              aqiValues: [45, 60, 90, 120, 80, 100, 130], // dữ liệu ảo 7 ngày
            ),
          ),
          const SizedBox(height: 24),

          // ⚠️ Cảnh báo / gợi ý
          _aqiAlert(currentAQI),
        ],
      ),
    );
  }
}

class _PollutantCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;

  const _PollutantCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.blueAccent),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              "$value $unit",
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
