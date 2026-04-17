import 'package:equatable/equatable.dart';

class ReviewStatus extends Equatable {
  const ReviewStatus({
    required this.businessCount,
    required this.personalCount,
    required this.unreviewedCount,
  });

  final int businessCount;
  final int personalCount;
  final int unreviewedCount;

  int get totalCount => businessCount + personalCount + unreviewedCount;
  int get reviewedCount => businessCount + personalCount;

  int get reviewPercentage {
    if (totalCount == 0) return 0;
    return ((reviewedCount / totalCount) * 100).toInt();
  }

  @override
  List<Object> get props => [businessCount, personalCount, unreviewedCount];
}
