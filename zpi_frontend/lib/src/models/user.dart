class User {
  final int userID;
  final String username;
  final String instrument;

  User({required this.userID, required this.username, required this.instrument});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userID: json['userID'],
      username: json['username'],
      instrument: json['instrument'],
    );
  }
}
