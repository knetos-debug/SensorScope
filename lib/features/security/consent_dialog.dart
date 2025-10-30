import 'package:flutter/material.dart';

Future<bool?> showSecurityConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        title: const Text('Samtycke'),
        content: const Text(
          'SensorScope kan göra aktiva nätverkstester (DNS, captive portal) och '
          'läsa gateway-information för att upptäcka manipulation. Appen snokar '
          'inte i andras trafik och skickar inget externt. All data lagras '
          'lokalt. Fortsätt?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Avbryt'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Fortsätt'),
          ),
        ],
      );
    },
  );
}
