import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/user.dart';

class CurrencyPickerDialog extends StatefulWidget {
  final Currency currentCurrency;
  final Function(Currency) onCurrencyChanged;

  const CurrencyPickerDialog({
    super.key,
    required this.currentCurrency,
    required this.onCurrencyChanged,
  });

  @override
  State<CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<CurrencyPickerDialog> {
  late Currency _selectedCurrency;

  @override
  void initState() {
    super.initState();
    _selectedCurrency = widget.currentCurrency;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Currency'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: Currency.values.map((currency) {
            return RadioListTile<Currency>(
              title: Text(_getCurrencyName(currency)),
              subtitle: Text(_getCurrencySymbol(currency)),
              value: currency,
              groupValue: _selectedCurrency,
              onChanged: (Currency? value) {
                if (value != null) {
                  setState(() {
                    _selectedCurrency = value;
                  });
                }
              },
              activeColor: theme.colorScheme.primary,
              selected: _selectedCurrency == currency,
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onCurrencyChanged(_selectedCurrency);
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getCurrencyName(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return 'US Dollar (USD)';
      case Currency.eur:
        return 'Euro (EUR)';
      case Currency.gbp:
        return 'British Pound (GBP)';
      case Currency.inr:
        return 'Indian Rupee (INR)';
      case Currency.jpy:
        return 'Japanese Yen (JPY)';
      case Currency.aud:
        return 'Australian Dollar (AUD)';
      case Currency.cad:
        return 'Canadian Dollar (CAD)';
    }
  }

  String _getCurrencySymbol(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return '\$';
      case Currency.eur:
        return '€';
      case Currency.gbp:
        return '£';
      case Currency.inr:
        return '₹';
      case Currency.jpy:
        return '¥';
      case Currency.aud:
        return 'A\$';
      case Currency.cad:
        return 'C\$';
    }
  }
}
