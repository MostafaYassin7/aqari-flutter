class ApiEndpoints {
  // Auth
  static const sendOtp           = '/auth/send-otp';
  static const verifyOtp         = '/auth/verify-otp';
  static const completeProfile   = '/auth/complete-profile';
  static const me                = '/auth/me';

  // Listings
  static const listings          = '/listings';
  static const listingCategories = '/listing-categories';
  static const myListings        = '/listings/my';
  static const goldenListings    = '/listings/golden';

  // Search (Algolia)
  static const search            = '/search';
  static const geoSearch         = '/search/geo';
  static const searchByReference = '/search/by-reference';
  static const savedSearches     = '/search/saved';
  static const projectsGeoSearch = '/search/projects/geo';

  // Projects
  static const projects          = '/projects';

  // Bookings
  static const bookings          = '/bookings';

  // Wallet
  static const wallet            = '/wallet';
  static const walletTopUp       = '/wallet/top-up';
  static const walletTransactions = '/wallet/transactions';
  static const walletInvoices    = '/wallet/invoices';

  // Chat
  static const chats             = '/chats';

  // Notifications
  static const notifications            = '/notifications';
  static const notificationsUnreadCount = '/notifications/unread-count';

  // Engagement
  static const favorites        = '/engagement/favorites';
  static const engagementStatus = '/engagement/status';

  // Users
  static const users          = '/users';
  static const updateProfile  = '/users/profile';
  static const establishment  = '/users/establishment';
  static const ratings        = '/users/ratings';

  // Promotions
  static const promotionTypes = '/promotions/types';
  static const promotions     = '/promotions';

  // Subscriptions
  static const bundles             = '/subscriptions/bundles';
  static const mySubscription      = '/subscriptions/my';
  static const subscriptions       = '/subscriptions';
  static const subscriptionSpaces  = '/subscriptions/spaces';

  // CRM
  static const crmClients           = '/crm/clients';
  static const crmReminders         = '/crm/reminders';
  static const crmDeals             = '/crm/deals';
  static const crmRemindersUpcoming = '/crm/reminders/upcoming';

  // Media
  static const mediaUpload       = '/media/upload';
  static const mediaUploadSingle = '/media/upload-single';

  // Marketing
  static const marketingRequests = '/marketing/requests';

  // Blog
  static const blog = '/blog';
}
