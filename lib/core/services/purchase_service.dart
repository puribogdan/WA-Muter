import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'monetization_config.dart';

class PurchaseService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized || !MonetizationConfig.isConfigured) return;
    final config = PurchasesConfiguration(
      MonetizationConfig.revenueCatPublicSdkKey,
    );
    await Purchases.configure(config);
    _initialized = true;
  }

  static Future<bool?> getIsPremiumEntitled() async {
    if (!MonetizationConfig.isConfigured) return null;
    await initialize();
    final info = await Purchases.getCustomerInfo();
    return _isPremiumActive(info);
  }

  static Future<String?> getLifetimePriceLabel() async {
    if (!MonetizationConfig.isConfigured) return null;
    await initialize();
    final package = await _findLifetimePackage();
    return package?.storeProduct.priceString;
  }

  static Future<bool> purchaseLifetimeUnlock() async {
    if (!MonetizationConfig.isConfigured) return false;
    await initialize();
    final package = await _findLifetimePackage();
    if (package == null) return false;
    try {
      final info = await Purchases.purchasePackage(package);
      return _isPremiumActive(info);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  static Future<bool> restorePurchases() async {
    if (!MonetizationConfig.isConfigured) return false;
    await initialize();
    final info = await Purchases.restorePurchases();
    return _isPremiumActive(info);
  }

  static bool _isPremiumActive(CustomerInfo info) {
    return info.entitlements.all[MonetizationConfig.premiumEntitlementId]
            ?.isActive ==
        true;
  }

  static Future<Package?> _findLifetimePackage() async {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return null;
    for (final package in current.availablePackages) {
      final storeId = package.storeProduct.identifier;
      if (storeId == MonetizationConfig.lifetimeProductId) {
        return package;
      }
    }

    // Fallback for RevenueCat default lifetime package key.
    for (final package in current.availablePackages) {
      if (package.packageType == PackageType.lifetime) {
        return package;
      }
    }
    return null;
  }
}
