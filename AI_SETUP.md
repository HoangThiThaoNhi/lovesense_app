# Lovesense AI Chatbot Setup

## API Configuration

This app uses **Groq API** for the AI chatbot feature.

### Setup Instructions

1. **Get a FREE Groq API Key**
   - Go to https://console.groq.com
   - Sign up for free account
   - Create an API key

2. **Configure the App**
   - Copy `.env.example` to `.env`:
     ```bash
     cp .env.example .env
     ```
   - Open `.env` and replace `your_groq_api_key_here` with your actual Groq API key
   
3. **Run the App**
   ```bash
   flutter run --dart-define-from-file=.env
   ```

## Security Notes

- **NEVER commit `.env` to git** - it contains your private API key
- The `.env` file is already in `.gitignore`
- Share `.env.example` with your team, not `.env`

## Groq API Benefits

- Free tier: 14,400+ requests/day
- Fast inference
- Excellent Vietnamese language support
- No credit card required

## Troubleshooting

If you see "YOUR_GROQ_API_KEY_HERE" error:
1. Make sure you created `.env` file from `.env.example`
2. Added your real API key to `.env` (e.g. `gsk_...sftJ`)
3. Ensure `flutter_dotenv` is correctly loading the file.
4. Running with `--dart-define-from-file=.env` flag
