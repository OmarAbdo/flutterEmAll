# 🚀 Quick Start Guide

This guide will help you get the AI Aggregator platform up and running in under 30 minutes.

## Prerequisites

Before you begin, ensure you have:

- ✅ Flutter SDK 3.0+ installed ([Install Flutter](https://flutter.dev/docs/get-started/install))
- ✅ Node.js 18+ and npm ([Install Node](https://nodejs.org/))
- ✅ Git installed
- ✅ A code editor (VS Code recommended)
- ✅ A Supabase account ([Sign up free](https://supabase.com))

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd flutterEmAll
```

## Step 2: Set Up Supabase Backend

### 2.1 Install Supabase CLI

```bash
npm install -g supabase
```

### 2.2 Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Click "New Project"
3. Name: `ai-aggregator-saudi`
4. Choose region closest to Saudi Arabia
5. Wait for project provisioning (~2 minutes)

### 2.3 Link Project Locally

```bash
supabase login
supabase link --project-ref <your-project-ref>
```

Find your project ref in Supabase Dashboard > Settings > General > Reference ID

### 2.4 Run Database Migrations

```bash
cd supabase
supabase db push
```

This creates all necessary tables, functions, and policies.

### 2.5 Get API Credentials

From Supabase Dashboard > Settings > API:
- Copy **Project URL**
- Copy **anon/public key**

### 2.6 Configure Environment Variables

Create `supabase/.env`:

```bash
# Supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>

# AI Providers (get these from respective platforms)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
OPENROUTER_API_KEY=sk-or-...

# Payment (optional for now)
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
HYPERPAY_API_KEY=...
HYPERPAY_ENTITY_ID=...
```

### 2.7 Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy ai-chat
supabase functions deploy usage-tracking
supabase functions deploy subscriptions
supabase functions deploy message-summarizer
```

## Step 3: Set Up Flutter App

### 3.1 Navigate to Flutter Directory

```bash
cd ../flutter_app
```

### 3.2 Create Environment File

Create `flutter_app/.env`:

```bash
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

### 3.3 Install Dependencies

```bash
flutter pub get
```

### 3.4 (Optional) Run Code Generation

If you modify the data models, regenerate the code:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Step 4: Configure Authentication Providers

### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials
3. Add redirect URI: `https://<your-project-ref>.supabase.co/auth/v1/callback`
4. In Supabase Dashboard > Authentication > Providers:
   - Enable Google
   - Paste Client ID and Secret

### Apple OAuth

1. Go to [Apple Developer](https://developer.apple.com)
2. Create Services ID
3. Enable Sign in with Apple
4. Add redirect URI
5. Configure in Supabase

### Facebook, Twitter, etc.

Follow similar steps for each provider. See [docs/SUPABASE_SETUP.md](SUPABASE_SETUP.md) for detailed instructions.

## Step 5: Run the Application

### Run on Web

```bash
flutter run -d chrome
```

### Run on iOS Simulator

```bash
flutter run -d ios
```

### Run on Android Emulator

```bash
flutter run -d android
```

## Step 6: Test the Application

### 6.1 Create an Account

1. Open the app
2. Click "Sign Up"
3. Enter email and password
4. You'll be automatically logged in

### 6.2 Start a Chat

1. Click "New Chat" button
2. Select an AI model from the top menu
3. Type a message and send
4. The AI will respond!

### 6.3 Check Usage

- Your usage is displayed on the home screen
- Free tier: 10 messages per hour
- Upgrade to premium for more

## Troubleshooting

### Issue: Supabase functions not working

**Solution**: Ensure you've deployed the functions and set environment variables:
```bash
supabase functions deploy ai-chat --no-verify-jwt
supabase secrets set --env-file supabase/.env
```

### Issue: Flutter build errors

**Solution**: Clean and rebuild:
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: Authentication not working

**Solution**:
1. Check OAuth redirect URIs match exactly
2. Verify provider is enabled in Supabase Dashboard
3. Check browser console for errors

### Issue: AI not responding

**Solution**:
1. Verify AI provider API keys are set in Supabase
2. Check Edge Function logs: `supabase functions logs ai-chat`
3. Ensure you haven't exceeded usage limits

## Next Steps

### Add More AI Models

Edit `supabase/migrations/20250101000000_initial_schema.sql`:
```sql
UPDATE ai_providers
SET config = '{"models": ["gpt-4", "gpt-4-turbo", "gpt-4o", "your-new-model"]}'
WHERE name = 'openai';
```

Then run:
```bash
supabase db reset
```

### Customize Subscription Tiers

Update limits in the database:
```sql
UPDATE subscription_tiers
SET message_limit = 20, time_window_hours = 1
WHERE name = 'free';
```

### Enable Payment Processing

1. Set up Stripe account
2. Add Stripe keys to environment
3. Configure webhooks: `https://<your-project-ref>.supabase.co/functions/v1/subscriptions/webhook`
4. Test subscription flow

### Deploy to Production

#### Flutter Web
```bash
flutter build web
# Deploy to Vercel, Netlify, or Firebase Hosting
```

#### Mobile Apps
```bash
# iOS
flutter build ios --release

# Android
flutter build apk --release
flutter build appbundle --release
```

Then upload to App Store and Google Play.

## Getting Help

- 📖 [Full Documentation](../README.md)
- 🔧 [Supabase Setup Guide](SUPABASE_SETUP.md)
- 💬 [GitHub Issues](https://github.com/your-repo/issues)

## Project Structure Overview

```
flutterEmAll/
├── flutter_app/          # Flutter application
│   ├── lib/
│   │   ├── features/    # Feature modules (auth, chat, etc.)
│   │   ├── shared/      # Shared code (models, services)
│   │   └── core/        # Core utilities (theme, localization)
│   └── assets/          # Images, translations
├── supabase/            # Backend
│   ├── functions/       # Edge Functions (API logic)
│   └── migrations/      # Database schema
└── docs/                # Documentation
```

## Key Features Checklist

- ✅ Multi-platform (iOS, Android, Web)
- ✅ Bilingual (Arabic/English) with RTL support
- ✅ Multiple AI providers (OpenAI, Anthropic, OpenRouter)
- ✅ Model switching during conversation
- ✅ Usage tracking with sliding window
- ✅ Configurable subscription tiers
- ✅ Payment provider abstraction (Stripe, HyperPay)
- ✅ Conversation memory with summarization
- ✅ Social authentication (Google, Apple, Facebook, etc.)
- ✅ Dark mode support
- ✅ Responsive design

## Configuration Tips

### Adjust Message Limits

Edit in Supabase SQL Editor:
```sql
UPDATE subscription_tiers
SET message_limit = 50, time_window_hours = 2
WHERE name = 'premium_1';
```

### Add New Language

1. Create `flutter_app/assets/translations/fr.json`
2. Add French translations
3. Update `main.dart` supported locales

### Change Theme Colors

Edit `flutter_app/lib/core/theme/app_theme.dart`:
```dart
static const Color primaryColor = Color(0xYOURCOLOR);
```

## Performance Optimization

### Enable Caching

Consider adding Redis for caching:
```bash
# Add Upstash Redis
# Configure in Supabase functions
```

### Optimize Images

```bash
cd flutter_app/assets/images
# Use compressed images (WebP format recommended)
```

### Enable Message Summarization

Automatically summarize old messages:
```dart
await SupabaseService.instance.summarizeConversation(conversationId);
```

## Security Best Practices

- ✅ Never commit `.env` files
- ✅ Use Row Level Security (RLS) on all tables
- ✅ Validate input on both client and server
- ✅ Use HTTPS only
- ✅ Implement rate limiting
- ✅ Regularly rotate API keys

## Monitoring

### View Logs

```bash
# Edge Function logs
supabase functions logs ai-chat

# Database logs
supabase db logs
```

### Usage Analytics

Query usage data:
```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) as total_messages
FROM messages
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

## Congratulations! 🎉

You now have a fully functional AI aggregator platform running. Start chatting with AI models and explore the features!

For more advanced configuration and deployment, see the [main README](../README.md).
