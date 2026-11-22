class ApiEndpoints {
  // Use localhost — works for physical devices via `adb reverse tcp:8000 tcp:8000`
  // and for emulators after `adb reverse tcp:8000 tcp:8000`.
  // If running over Wi-Fi (no USB), replace with your machine's LAN IP, e.g.:
  //   static const String baseUrl = 'http://192.168.0.107:8000/api/v1';
  static const String baseUrl = 'http://localhost:8000/api/v1';

  // Auth
  static const String register = '$baseUrl/auth/register/';
  static const String login = '$baseUrl/auth/login/';
  static const String logout = '$baseUrl/auth/logout/';
  static const String tokenRefresh = '$baseUrl/auth/token/refresh/';
  static const String me = '$baseUrl/auth/me/';
  static const String farmerProfile = '$baseUrl/auth/farmer-profile/';
  static const String vetProfile = '$baseUrl/auth/vet-profile/';
  static const String vets = '$baseUrl/auth/vets/';

  // Farms
  static const String farms = '$baseUrl/farms/';
  static String farmDetail(int id) => '$baseUrl/farms/$id/';

  // Animals
  static const String animals = '$baseUrl/animals/';
  static String animalDetail(int id) => '$baseUrl/animals/$id/';

  // Health
  static const String healthRecords = '$baseUrl/health-records/';
  static String healthRecordDetail(int id) => '$baseUrl/health-records/$id/';

  // Vaccinations
  static const String vaccinationSchedules = '$baseUrl/vaccination-schedules/';
  static const String vaccinationRecords = '$baseUrl/vaccination-records/';
  static const String vaccinationProtocols = '$baseUrl/vaccination-protocols/';

  // Notifications
  static const String notifications = '$baseUrl/notifications/';
  static String markRead(int id) => '$baseUrl/notifications/$id/mark_read/';
  static const String markAllRead = '$baseUrl/notifications/mark_all_read/';

  // Veterinary assistance
  static const String assistanceRequests = '$baseUrl/assistance-requests/';
  static String assistanceRequestDetail(int id) =>
      '$baseUrl/assistance-requests/$id/';
  static String respondToRequest(int id) =>
      '$baseUrl/assistance-requests/$id/respond/';

  // Disease reports
  static const String diseaseReports = '$baseUrl/disease-reports/';
  static String diseaseReportDetail(int id) =>
      '$baseUrl/disease-reports/$id/';

  // Official announcements
  static const String announcements = '$baseUrl/announcements/';
  static String announcementDetail(int id) => '$baseUrl/announcements/$id/';

  // AI Health Assistant
  static const String assistantAsk = '$baseUrl/assistant/ask/';

  // Password reset
  static const String passwordResetRequest = '$baseUrl/auth/password-reset/request/';
  static const String passwordResetConfirm = '$baseUrl/auth/password-reset/confirm/';
}
