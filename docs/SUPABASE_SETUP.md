# Supabase Setup Guide

This guide walks you through setting up Supabase for the AI Aggregator platform.

## 📋 Prerequisites

- Node.js 18+ installed
- npm or yarn package manager
- A Supabase account (free tier works for development)

## 🚀 Step 1: Install Supabase CLI

```bash
npm install -g supabase
```

Verify installation:
```bash
supabase --version
```

## 🔐 Step 2: Create Supabase Project

### Option A: Via Supabase Dashboard (Recommended for beginners)

1. Go to [supabase.com](https://supabase.com)
2. Sign up or log in
3. Click "New Project"
4. Fill in:
   - **Project Name**: `ai-aggregator-saudi` (or your choice)
   - **Database Password**: (save this securely!)
   - **Region**: Choose closest to Saudi Arabia (e.g., `Southeast Asia` or `Middle East` if available)
   - **Pricing Plan**: Free (for development)
5. Click "Create new project"
6. Wait 2-3 minutes for provisioning

### Option B: Via CLI

```bash
supabase login
supabase projects create ai-aggregator-saudi --region southeast-asia
```

## 🔗 Step 3: Link Local Project

In your project root:

```bash
cd flutterEmAll
supabase link --project-ref <your-project-ref>
```

To find your project ref:
- Go to Supabase Dashboard
- Select your project
- Go to Settings > General
- Copy "Reference ID"

## 🗄️ Step 4: Run Database Migrations

```bash
supabase db push
```

This will create all necessary tables, indexes, and RLS policies.

## 🔑 Step 5: Configure Authentication Providers

### Email/Password (Already enabled)

Email auth is enabled by default.

### Social Providers

#### Google OAuth

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create a new project (or select existing)
3. Enable Google+ API
4. Create OAuth 2.0 credentials:
   - Application type: Web application
   - Authorized redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
5. Copy **Client ID** and **Client Secret**
6. In Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Google
   - Paste Client ID and Secret
   - Save

#### Apple OAuth

1. Go to [Apple Developer](https://developer.apple.com)
2. Create a Services ID
3. Configure Sign in with Apple:
   - Return URLs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
4. Copy Service ID and Key ID
5. In Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Apple
   - Paste Service ID, Team ID, Key ID, and Private Key
   - Save

#### Facebook OAuth

1. Go to [Facebook Developers](https://developers.facebook.com)
2. Create an app (Consumer type)
3. Add Facebook Login product
4. Configure OAuth redirect URIs: `https://<your-project-ref>.supabase.co/auth/v1/callback`
5. Copy App ID and App Secret
6. In Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Facebook
   - Paste App ID and Secret
   - Save

#### X (Twitter) OAuth

1. Go to [Twitter Developer Portal](https://developer.twitter.com)
2. Create an app
3. Enable OAuth 2.0
4. Add callback URL: `https://<your-project-ref>.supabase.co/auth/v1/callback`
5. Copy Client ID and Client Secret
6. In Supabase Dashboard:
   - Go to Authentication > Providers
   - Enable Twitter
   - Paste credentials
   - Save

#### Snapchat OAuth

1. Go to [Snapchat Developers](https://kit.snapchat.com)
2. Create an app
3. Add Login Kit
4. Configure redirect URI: `https://<your-project-ref>.supabase.co/auth/v1/callback`
5. Copy OAuth Client ID and Secret
6. **Note**: Snapchat requires manual configuration in Supabase
   - You may need to use a custom OAuth flow
   - See [Supabase custom OAuth docs](https://supabase.com/docs/guides/auth/social-login)

#### Instagram OAuth

Instagram login is done through Facebook:
1. In Facebook Developer Console, add Instagram Basic Display
2. Configure same redirect URI
3. Enable in Supabase under Facebook settings

## 🔧 Step 6: Get API Credentials

In Supabase Dashboard:

1. Go to Settings > API
2. Copy:
   - **Project URL**: `https://<your-project-ref>.supabase.co`
   - **anon/public key**: (for client-side)
   - **service_role key**: (for server-side, keep secret!)

## 📝 Step 7: Configure Environment Variables

### For Supabase Functions

Create `supabase/.env`:

```env
# Supabase
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_KEY=<your-service-role-key>

# AI Providers
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
OPENROUTER_API_KEY=sk-or-...

# Payment Providers
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
HYPERPAY_API_KEY=...
HYPERPAY_ENTITY_ID=...

# App Configuration
NODE_ENV=development
```

### For Flutter App

Create `flutter_app/.env`:

```env
SUPABASE_URL=https://<your-project-ref>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

## 🚀 Step 8: Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy

# Or deploy individually
supabase functions deploy ai-chat
supabase functions deploy subscriptions
supabase functions deploy usage-tracking
supabase functions deploy message-summarizer
```

## 🧪 Step 9: Test Your Setup

### Test Database Connection

```bash
supabase db reset  # Resets to migration state (WARNING: deletes data)
```

### Test Edge Function Locally

```bash
supabase functions serve ai-chat --env-file supabase/.env
```

Then in another terminal:
```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/ai-chat' \
  --header 'Authorization: Bearer <your-anon-key>' \
  --header 'Content-Type: application/json' \
  --data '{"message":"Hello"}'
```

## 🔒 Step 10: Security Checklist

- ✅ Enable Row Level Security (RLS) on all tables
- ✅ Never commit `.env` files
- ✅ Use `service_role` key only in backend
- ✅ Enable email confirmation for production
- ✅ Configure rate limiting
- ✅ Set up database backups
- ✅ Enable SSL (automatic with Supabase)

## 📊 Step 11: Initialize Tier Configuration

Run this SQL in Supabase SQL Editor:

```sql
-- Insert default subscription tiers
INSERT INTO subscription_tiers (name, price_monthly, price_yearly, message_limit, time_window_hours, features) VALUES
('free', 0, 0, 10, 1, '["basic_models"]'),
('premium_1', 29, 290, 50, 2, '["all_models", "priority_support"]'),
('premium_2', 49, 490, 100, 2, '["all_models", "priority_support", "advanced_features"]');
```

## 🆘 Troubleshooting

### Issue: Cannot connect to Supabase

**Solution**: Check your internet connection and verify project ref in `supabase/config.toml`

### Issue: Migration failed

**Solution**: Reset database and try again:
```bash
supabase db reset
supabase db push
```

### Issue: Edge function not deploying

**Solution**: Check function syntax and ensure `deno.json` is properly configured

### Issue: Social auth not working

**Solution**:
1. Verify redirect URIs match exactly
2. Check OAuth app is in production mode (not development)
3. Verify callback URL in provider dashboard

## 📚 Additional Resources

- [Supabase Documentation](https://supabase.com/docs)
- [Supabase Auth Docs](https://supabase.com/docs/guides/auth)
- [Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [Database Migrations](https://supabase.com/docs/guides/cli/local-development#database-migrations)

## 🎉 Next Steps

After completing setup:
1. ✅ Test authentication flows
2. ✅ Configure subscription tiers
3. ✅ Add AI provider API keys
4. ✅ Set up payment webhooks
5. ✅ Run Flutter app and connect to backend
