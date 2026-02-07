class AppConfig {
  // Get your FREE Groq API Key at: https://console.groq.com
  // Configure it in .env file (copy from .env.example)
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: 'YOUR_GROQ_API_KEY_HERE',
  );
}
