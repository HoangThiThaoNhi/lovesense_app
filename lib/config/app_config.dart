import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // Get your FREE Groq API Key at: https://console.groq.com
  // Configure it in .env file (copy from .env.example)
  // Configure it in .env file (copy from .env.example)
  static String get groqApiKey => dotenv.env['GROQ_API_KEY'] ?? '';
}
