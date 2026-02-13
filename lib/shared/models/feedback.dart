class FeedbackData {
  final int rating; // 1..5
  final String comment;
  final DateTime createdAt;

  const FeedbackData({
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
}
