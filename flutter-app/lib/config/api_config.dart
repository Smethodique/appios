import 'env_config.dart';

class ApiConfig {
  static const Duration timeout = Duration(seconds: 15);

  static String get baseUrl => EnvConfig.apiBaseUrl;
  static String get pusherAppKey => EnvConfig.pusherAppKey;
  static String get pusherCluster => EnvConfig.pusherCluster;
  static String get pusherAuthEndpoint => EnvConfig.pusherAuthEndpoint;

  static Map<String, String> get baseHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  static const String loginEndpoint = '/login';
  static const String registerEndpoint = '/register';
  static const String logoutEndpoint = '/logout';
  static const String userEndpoint = '/user';
  static const String videosEndpoint = '/videos';
  static const String freeVideosEndpoint = '/videos/free-videos';
  static const String videoCategoriesEndpoint = '/videos/categories';
  static const String childrenEndpoint = '/children';
  static const String allergiesEndpoint = '/allergies';
  static const String growthEndpoint = '/growth-measurements';
  static const String vaccinationsEndpoint = '/vaccinations';
  static const String medicalRecordsEndpoint = '/medical-records';

  static const String consultationsEndpoint = '/medical-records';
  static const String subscriptionsEndpoint = '/subscriptions';
  static const String plansEndpoint = '/subscriptions/plans';
  static const String subscribeEndpoint = '/subscriptions/subscribe';
  static const String cancelSubscriptionEndpoint = '/subscriptions/cancel';
  static const String invoicesEndpoint = '/invoices';
  static const String liveSessionsEndpoint = '/live-sessions';
  static const String workshopsEndpoint = '/workshops';
  static const String callsEndpoint = '/calls';
  static const String callJoinEndpoint = '/calls';
  static const String chatEndpoint = '/chat/messages';
  static const String documentsEndpoint = '/documents';
  static const String guidesEndpoint = '/guides';
  static const String freePdfsEndpoint = '/guides/free-pdfs';
  static const String premiumVideosEndpoint = '/premium-videos';
  static const String premiumGuidesEndpoint = '/premium-guides';
  static const String recordingsEndpoint = '/recordings';
  static const String coachingEndpoint = '/coaching/book';
  static const String appointmentsEndpoint = '/appointments';
  static const String notificationsEndpoint = '/notifications';
  static const String newsletterEndpoint = '/newsletter';
  static const String emailVerify = '/email/verify';
  static const String emailResend = '/email/resend-verification';
  static const String emailVerifyResend = '/email/verify/resend';
  static const String emailVerifyStatus = '/email/verify/status';
  static const String passwordEmailEndpoint = '/password/email';
  static const String passwordResetEndpoint = '/password/reset';
  static const String conversationsEndpoint = '/chat/conversations';
}