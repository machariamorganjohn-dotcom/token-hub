class LocalizationService {
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'welcome': 'Welcome',
      'buy_token': 'Buy Token',
      'balance': 'Balance',
      'history': 'History',
      'settings': 'Settings',
      'low_balance': 'Low Balance Alert',
      'confirm_purchase': 'Confirm Purchase',
      'success': 'Success',
      'points': 'Points',
    },
    'sw': {
      'welcome': 'Karibu',
      'buy_token': 'Nunua Token',
      'balance': 'Salio',
      'history': 'Historia',
      'settings': 'Mipangilio',
      'low_balance': 'Tahadhari ya Salio la Chini',
      'confirm_purchase': 'Thibitisha Malipo',
      'success': 'Umefanikiwa',
      'points': 'Alama',
    },
  };

  static String getString(String key, String lang) {
    return _localizedValues[lang]?[key] ?? _localizedValues['en']![key]!;
  }
}
