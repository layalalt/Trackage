// user_session.dart

class UserSession {
  static String reservationID = '';
  static String lastName = '';
  static List<dynamic>? userRow;

  static void setSession({
    required String resID,
    required String lName,
    required List<dynamic> row,
  }) {
    reservationID = resID;
    lastName = lName;
    userRow = row;
  }

  static void clear() {
    reservationID = '';
    lastName = '';
    userRow = null;
  }
}

