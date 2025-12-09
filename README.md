# AI Aggregator Platform for Saudi Market

A comprehensive AI chat aggregator platform built with Flutter and Supabase, supporting multiple AI providers, subscription tiers, and bilingual support (Arabic/English).

## 🏗️ Architecture

```
├── flutter_app/          # Flutter application (iOS, Android, Web)
├── supabase/            # Supabase backend
│   ├── functions/       # Edge Functions (API logic)
│   ├── migrations/      # Database migrations
│   └── config.toml      # Supabase configuration
├── docs/                # Documentation
└── scripts/             # Utility scripts
```

## 🚀 Tech Stack

### Frontend/Mobile
- **Flutter** - Single codebase for iOS, Android, and Web
- **Dart** - Programming language
- **flutter_riverpod** - State management
- **go_router** - Navigation
- **flutter_localizations** - i18n support

### Backend
- **Supabase** - Backend as a Service
- **PostgreSQL** - Primary database
- **TypeScript/Node.js** - Edge Functions
- **Supabase Auth** - Authentication

### AI Providers
- OpenAI (GPT models)
- Anthropic (Claude models)
- OpenRouter (Multiple models)

### Payment Providers
- Stripe
- HyperPay

## ✨ Features

### Authentication
- Email/Password
- Social login: Google, Apple, Facebook, X (Twitter), Instagram, Snapchat

### Subscription Tiers
- **Free**: 10 messages/hour
- **Premium Tier 1**: 50 messages/2 hours
- **Premium Tier 2**: 100 messages/2 hours

*Note: Limits are configurable via database*

### Chat Features
- Multi-provider AI integration
- Model switching during conversation
- Conversation memory with smart summarization
- Bilingual support (Arabic/English)
- RTL support for Arabic

### Usage Tracking
- Sliding window counters
- Per-tier limit enforcement
- Real-time usage monitoring

## 📁 Project Structure

### Flutter App
```
flutter_app/
├── lib/
│   ├── core/
│   │   ├── config/          # Environment & app config
│   │   ├── constants/       # App constants
│   │   ├── theme/           # App theming
│   │   ├── localization/    # i18n files
│   │   └── router/          # Navigation
│   ├── features/
│   │   ├── auth/           # Authentication
│   │   ├── chat/           # Chat interface
│   │   ├── subscription/   # Subscription management
│   │   ├── settings/       # User settings
│   │   └── home/           # Home screen
│   ├── shared/
│   │   ├── models/         # Data models
│   │   ├── providers/      # Riverpod providers
│   │   ├── services/       # Business logic services
│   │   ├── repositories/   # Data repositories
│   │   └── widgets/        # Reusable widgets
│   └── main.dart
```

### Supabase Backend
```
supabase/
├── functions/
│   ├── ai-chat/            # AI provider integration
│   ├── subscriptions/      # Subscription management
│   ├── usage-tracking/     # Usage limit enforcement
│   └── message-summarizer/ # Message summarization
├── migrations/
│   └── [timestamp]_*.sql   # Database migrations
```

## 🗄️ Database Schema

### Core Tables
- `profiles` - Extended user profile data
- `subscription_tiers` - Configurable subscription tiers
- `user_subscriptions` - User subscription status
- `ai_providers` - AI provider configurations
- `conversations` - Chat conversations
- `messages` - Individual messages
- `message_summaries` - Summarized old messages
- `usage_tracking` - Usage counter tracking

## 🔧 Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- Node.js (18+)
- Supabase CLI
- Git

### 1. Clone Repository
```bash
git clone <repository-url>
cd flutterEmAll
```

### 2. Supabase Setup
See [docs/SUPABASE_SETUP.md](docs/SUPABASE_SETUP.md) for detailed instructions.

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link project
supabase link --project-ref <your-project-ref>

# Push migrations
supabase db push

# Deploy functions
supabase functions deploy
```

### 3. Environment Configuration

#### Backend (.env in supabase/functions)
```env
OPENAI_API_KEY=your_openai_key
ANTHROPIC_API_KEY=your_anthropic_key
OPENROUTER_API_KEY=your_openrouter_key
STRIPE_SECRET_KEY=your_stripe_key
HYPERPAY_API_KEY=your_hyperpay_key
```

#### Flutter (.env in flutter_app)
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
```

### 4. Flutter Setup
```bash
cd flutter_app

# Get dependencies
flutter pub get

# Run on desired platform
flutter run -d chrome        # Web
flutter run -d ios          # iOS
flutter run -d android      # Android
```

## 🌐 Localization

The app supports Arabic and English:
- Auto-detects device language
- Manual language switching in settings
- Full RTL support for Arabic

## 🔐 Security

- Row Level Security (RLS) enabled on all tables
- API keys stored in environment variables
- Secure payment processing
- Rate limiting on API endpoints

## 📝 Development Guidelines

### Code Style
- Follow Dart style guide
- Use dependency injection (Riverpod)
- Keep functions pure and testable
- Write descriptive commit messages

### Architecture Patterns
- Clean Architecture
- Repository Pattern
- Provider Pattern (for AI/Payment providers)
- SOLID Principles

## 🚀 Deployment

### Flutter Web
```bash
flutter build web
# Deploy to hosting (Vercel, Netlify, etc.)
```

### Flutter Mobile
```bash
flutter build ios --release
flutter build apk --release
```

### Supabase Functions
```bash
supabase functions deploy <function-name>
```

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## 📄 License

[Your License Here]

## 🤝 Contributing

[Contribution guidelines]

## 📧 Support

[Support contact]
