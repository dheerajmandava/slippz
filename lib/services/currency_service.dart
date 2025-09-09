import 'package:flutter/material.dart';
import 'package:world_countries/world_countries.dart';
import 'local_data_service.dart';

class CurrencyService {
  static final ValueNotifier<String> _currencyNotifier = ValueNotifier<String>('USD');
  
  static ValueNotifier<String> get currencyNotifier => _currencyNotifier;
  static const String _prefKey = 'currency_code';
  static const String _defaultCode = 'USD';
  static const String _fallbackSymbol = '4';

  static Future<String> getSelectedCode() async {
    final saved = await LocalDataService.instance.getPreference(_prefKey);
    final code = saved ?? _defaultCode;
    if (_currencyNotifier.value != code) {
      _currencyNotifier.value = code;
    }
    return code;
  }
  
  static String getSelectedCodeSync() {
    return _currencyNotifier.value;
  }

  static Future<void> setSelectedCode(String code) async {
    await LocalDataService.instance.setPreference(_prefKey, code);
    _currencyNotifier.value = code; // Notify listeners
  }

  static FiatCurrency? _findFiat(String code) {
    try {
      return FiatCurrency.maybeFromAnyCode(code);
    } catch (_) {
      return null;
    }
  }

  static Future<String> formatAmount(double amount) async {
    final code = await getSelectedCode();
    final fiat = _findFiat(code);
    final symbol = fiat?.symbol ?? _fallbackSymbol;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  static Future<String> formatAmountNoDecimals(double amount) async {
    final code = await getSelectedCode();
    final fiat = _findFiat(code);
    final symbol = fiat?.symbol ?? _fallbackSymbol;
    return '$symbol${amount.toStringAsFixed(0)}';
  }
}


