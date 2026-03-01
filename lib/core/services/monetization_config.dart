class MonetizationConfig {
  static const String revenueCatPublicSdkKey = String.fromEnvironment(
    'REVENUECAT_PUBLIC_SDK_KEY',
    defaultValue: '',
  );
  static const bool adminPremiumOverride = bool.fromEnvironment(
    'ADMIN_PREMIUM_OVERRIDE',
    defaultValue: false,
  );

  static const String premiumEntitlementId = 'premium';
  static const String lifetimeProductId = 'lifetime_unlock';

  static bool get isConfigured => revenueCatPublicSdkKey.trim().isNotEmpty;
}
