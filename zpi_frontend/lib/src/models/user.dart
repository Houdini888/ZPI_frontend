class User {
  final int userID;
  final String username;
  final String password;

  User({required this.userID, required this.username, required this.password});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      username: json['username'],
      password: json['password'],
    );
  }
}
