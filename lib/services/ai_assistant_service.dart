import 'dart:convert';
import 'package:http/http.dart' as http;

class AiAssistantService {
  // Knowledge Base for "Token Wise" AI
  static const Map<String, String> _knowledgeBase = {
    "kplc token delay": "KPLC tokens can sometimes delay due to high network traffic. If you don't receive your token within 10 minutes, go to the 'Disputes' section in Support and tap 'Expedite'.",
    "mpesa error": "Ensure you have enough balance in your M-Pesa account. If the STK push didn't appear, try restarting your phone or checking your M-Pesa menu under 'Lipa na M-Pesa'.",
    "meter not syncing": "To sync your meter, ensure your physical meter is on and has credit. Then, use the 'Sync' button in the Dashboard to fetch the latest balance.",
    "sos token": "The SOS Emergency Token provides you with 150 KES worth of units instantly. This will be deducted from your next purchase automatically.",
    "commission": "Token Hub is free to use! We don't charge extra fees on KPLC tokens; you get the full value of your money.",
    "buy tokens": "To buy tokens, tap the 'Buy' button, select your meter, enter the amount, and follow the M-Pesa prompts.",
  };

  static Future<String> getResponse(String userQuery) async {
    final query = userQuery.toLowerCase();

    // 1. Search Knowledge Base (Instant Speed)
    for (var entry in _knowledgeBase.entries) {
      if (query.contains(entry.key)) {
        return entry.value;
      }
    }

    // 2. Fallback to a smart default if no direct match
    if (query.contains("hello") || query.contains("hi")) {
      return "Hello! I am Token Wise, your AI energy assistant. How can I help you manage your tokens today?";
    }

    if (query.contains("who are you")) {
      return "I am Token Wise, the AI brain of Token Hub. I know everything about KPLC tokens, payments, and meter management.";
    }

    return "I'm not quite sure about that specific detail, but I'm learning! You can try asking about 'KPLC tokens', 'M-Pesa errors', or 'SOS tokens'.";
  }
}
