import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AQILineChart extends StatelessWidget {
  final List<int> aqiValues;

  const AQILineChart({super.key, required this.aqiValues});

  @override
  Widget build(BuildContext context) {
    // Tạo danh sách 7 ngày gần nhất
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
    final dateLabels = last7Days.map((d) => DateFormat('dd/MM').format(d)).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 300,
        gridData: FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40, // tăng khoảng cách
              interval: 1,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < dateLabels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      dateLabels[index],
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 50,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(aqiValues.length,
                (index) => FlSpot(index.toDouble(), aqiValues[index].toDouble())),
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFFE53935)],
            ),
            barWidth: 4,
            dotData: FlDotData(show: true),
          ),
        ],
        borderData: FlBorderData(show: true),
        lineTouchData: LineTouchData(enabled: true),
      ),
    );
  }
}
