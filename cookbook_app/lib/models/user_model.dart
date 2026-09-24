class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profileImage;
  final String token;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'],
      name: json['name'],
      email: json['email'],
      profileImage: json['profileImage'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'token': token,
    };
  }
}

