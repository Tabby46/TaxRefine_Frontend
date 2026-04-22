import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:taxrefine/core/models/review_status.dart';

class ReviewStatusPieChart extends StatelessWidget {
  const ReviewStatusPieChart({super.key, required this.reviewStatus});

  final ReviewStatus reviewStatus;

  static const Color businessColor = Color(0xFF24E62A); // Bright Green
  static const Color personalColor = Color(
    0xFF00D1FF,
  ); // Neon Sky Blue (match NeonColors.personalBlue)
  static const Color unreviewedColor = Color(0xFFF3C324); // Bright Amber

  @override
  Widget build(BuildContext context) {
    if (reviewStatus.totalCount == 0) {
      return const SizedBox(
        height: 100,
        width: 100,
        child: Center(
          child: Text(
            "0%",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ),
      );
    }

    final percentage = reviewStatus.reviewPercentage;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 100,
          width: 100,
          child: PieChart(
            PieChartData(
              sections: _buildPieSections(),
              centerSpaceRadius: 28,
              sectionsSpace: 2,
              startDegreeOffset: -90,
            ),
            duration: const Duration(milliseconds: 750),
          ),
        ),
        // Center text showing percentage reviewed
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$percentage%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Text(
              'Reviewed',
              style: TextStyle(color: Colors.white70, fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    final sections = <PieChartSectionData>[];

    if (reviewStatus.businessCount > 0) {
      sections.add(
        PieChartSectionData(
          color: businessColor,
          value: reviewStatus.businessCount.toDouble(),
          radius: 12,
          showTitle: false,
        ),
      );
    }

    if (reviewStatus.personalCount > 0) {
      sections.add(
        PieChartSectionData(
          color: personalColor,
          value: reviewStatus.personalCount.toDouble(),
          radius: 12,
          showTitle: false,
        ),
      );
    }

    if (reviewStatus.unreviewedCount > 0) {
      sections.add(
        PieChartSectionData(
          color: unreviewedColor,
          value: reviewStatus.unreviewedCount.toDouble(),
          radius: 12,
          showTitle: false,
        ),
      );
    }

    return sections;
  }
}
