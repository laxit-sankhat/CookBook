class CommentModel {
  final String id;
  final String text;
  final String userId;
  final String userName;

  CommentModel({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: json['_id'],
      text: json['text'],
      userId: json['user']['_id'],
      userName: json['user']['name'],
    );
  }
}