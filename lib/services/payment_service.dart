import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;

  PaymentService._internal();

  String get merchantUid => dotenv.env['WAAFI_MERCHANT_UID'] ?? '';
  String get apiUserId => dotenv.env['WAAFI_API_USER_ID'] ?? '';
  String get apiKey => dotenv.env['WAAFI_API_KEY'] ?? '';

  Future<String> makePayment(
      String number, double amount, String description) async {
    final url = Uri.parse('https://api.waafipay.net/asm');

    final requestPayLoad = {
      "schemaVersion": "1.0",
      "requestId": DateTime.now().millisecondsSinceEpoch.toString(),
      "timestamp": DateTime.now().toIso8601String(),
      "channelName": "WEB",
      "serviceName": "API_PURCHASE",
      "serviceParams": {
        "merchantUid": merchantUid,
        "apiUserId": apiUserId,
        "apiKey": apiKey,
        "paymentMethod": "MWALLET_ACCOUNT",
        "payerInfo": {
          "accountNo": number,
        },
        "transactionInfo": {
          "referenceId": DateTime.now().millisecondsSinceEpoch.toString(),
          "invoiceId": DateTime.now().millisecondsSinceEpoch.toString(),
          "amount": amount,
          "currency": "USD",
          "description": description,
        }
      }
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode(requestPayLoad),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final responseMsg = responseData['responseMsg'];
        return responseMsg;
      } else {
        throw Exception('Payment failed with status: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Payment failed: $error');
    }
  }
}
