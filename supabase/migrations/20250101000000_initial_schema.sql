-- Initial database schema for AI Aggregator Platform
-- This migration creates all necessary tables and relationships

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable pgcrypto for security functions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PROFILES TABLE
-- Extended user profile information beyond Supabase auth.users
-- ============================================================================

CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT,
    full_name TEXT,
    avatar_url TEXT,
    preferred_language TEXT DEFAULT 'ar' CHECK (preferred_language IN ('ar', 'en')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Policies for profiles
CREATE POLICY "Users can view own profile"
    ON profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON profiles FOR UPDATE
    USING (auth.uid() = id);

-- Auto-create profile on user signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO profiles (id, email, full_name, avatar_url)
    VALUES (
        NEW.id,
        NEW.email,
        NEW.raw_user_meta_data->>'full_name',
        NEW.raw_user_meta_data->>'avatar_url'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- SUBSCRIPTION TIERS TABLE
-- Configurable subscription tiers with limits
-- ============================================================================

CREATE TABLE subscription_tiers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL CHECK (name IN ('free', 'premium_1', 'premium_2')),
    display_name_en TEXT NOT NULL,
    display_name_ar TEXT NOT NULL,
    description_en TEXT,
    description_ar TEXT,
    price_monthly DECIMAL(10,2) NOT NULL DEFAULT 0,
    price_yearly DECIMAL(10,2) NOT NULL DEFAULT 0,
    message_limit INTEGER NOT NULL,
    time_window_hours INTEGER NOT NULL,
    features JSONB DEFAULT '[]'::jsonb,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE subscription_tiers ENABLE ROW LEVEL SECURITY;

-- Anyone can read tiers (for pricing page)
CREATE POLICY "Subscription tiers are viewable by everyone"
    ON subscription_tiers FOR SELECT
    USING (is_active = true);

-- Insert default tiers
INSERT INTO subscription_tiers (name, display_name_en, display_name_ar, description_en, description_ar, price_monthly, price_yearly, message_limit, time_window_hours, features) VALUES
('free', 'Free', 'مجاني', 'Perfect for trying out', 'مثالي للتجربة', 0, 0, 10, 1, '["basic_models"]'::jsonb),
('premium_1', 'Premium', 'بريميوم', 'For regular users', 'للمستخدمين المنتظمين', 29, 290, 50, 2, '["all_models", "priority_support"]'::jsonb),
('premium_2', 'Premium Plus', 'بريميوم بلس', 'For power users', 'للمستخدمين المحترفين', 49, 490, 100, 2, '["all_models", "priority_support", "advanced_features"]'::jsonb);

-- ============================================================================
-- USER SUBSCRIPTIONS TABLE
-- Tracks user subscription status and history
-- ============================================================================

CREATE TABLE user_subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tier_id UUID NOT NULL REFERENCES subscription_tiers(id),
    status TEXT NOT NULL CHECK (status IN ('active', 'canceled', 'expired', 'past_due')) DEFAULT 'active',
    payment_provider TEXT CHECK (payment_provider IN ('stripe', 'hyperpay')),
    external_subscription_id TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    cancel_at_period_end BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Enable RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;

-- Users can view own subscription
CREATE POLICY "Users can view own subscription"
    ON user_subscriptions FOR SELECT
    USING (auth.uid() = user_id);

-- Create index for faster lookups
CREATE INDEX idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX idx_user_subscriptions_status ON user_subscriptions(status);

-- Auto-assign free tier to new users
CREATE OR REPLACE FUNCTION assign_free_tier()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_subscriptions (user_id, tier_id, status)
    SELECT NEW.id, id, 'active'
    FROM subscription_tiers
    WHERE name = 'free'
    LIMIT 1;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_created
    AFTER INSERT ON profiles
    FOR EACH ROW
    EXECUTE FUNCTION assign_free_tier();

-- ============================================================================
-- AI PROVIDERS TABLE
-- Configuration for AI provider integrations
-- ============================================================================

CREATE TABLE ai_providers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    display_name TEXT NOT NULL,
    provider_type TEXT NOT NULL CHECK (provider_type IN ('openai', 'anthropic', 'openrouter', 'custom')),
    base_url TEXT,
    is_active BOOLEAN DEFAULT true,
    config JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE ai_providers ENABLE ROW LEVEL SECURITY;

-- Anyone can read active providers
CREATE POLICY "Active AI providers are viewable by authenticated users"
    ON ai_providers FOR SELECT
    USING (auth.role() = 'authenticated' AND is_active = true);

-- Insert default providers
INSERT INTO ai_providers (name, display_name, provider_type, base_url, config) VALUES
('openai', 'OpenAI', 'openai', 'https://api.openai.com/v1', '{"models": ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo", "gpt-4o", "gpt-4o-mini"]}'::jsonb),
('anthropic', 'Anthropic', 'anthropic', 'https://api.anthropic.com/v1', '{"models": ["claude-3-5-sonnet-20241022", "claude-3-5-haiku-20241022", "claude-3-opus-20240229"]}'::jsonb),
('openrouter', 'OpenRouter', 'openrouter', 'https://openrouter.ai/api/v1', '{"models": []}'::jsonb);

-- ============================================================================
-- CONVERSATIONS TABLE
-- Stores chat conversations
-- ============================================================================

CREATE TABLE conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT,
    current_provider_id UUID REFERENCES ai_providers(id),
    current_model TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- Users can only access their own conversations
CREATE POLICY "Users can view own conversations"
    ON conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own conversations"
    ON conversations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own conversations"
    ON conversations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own conversations"
    ON conversations FOR DELETE
    USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_conversations_user_id ON conversations(user_id);
CREATE INDEX idx_conversations_updated_at ON conversations(updated_at DESC);

-- ============================================================================
-- MESSAGES TABLE
-- Stores individual messages in conversations
-- ============================================================================

CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    provider_id UUID REFERENCES ai_providers(id),
    model TEXT,
    tokens_used INTEGER,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Users can only access messages from their conversations
CREATE POLICY "Users can view messages from own conversations"
    ON messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages to own conversations"
    ON messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- Create indexes
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- ============================================================================
-- MESSAGE SUMMARIES TABLE
-- Stores summaries of old messages to save tokens
-- ============================================================================

CREATE TABLE message_summaries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    summary TEXT NOT NULL,
    message_count INTEGER NOT NULL,
    start_message_id UUID,
    end_message_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE message_summaries ENABLE ROW LEVEL SECURITY;

-- Users can only access summaries from their conversations
CREATE POLICY "Users can view summaries from own conversations"
    ON message_summaries FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM conversations
            WHERE conversations.id = message_summaries.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- Create indexes
CREATE INDEX idx_message_summaries_conversation_id ON message_summaries(conversation_id);

-- ============================================================================
-- USAGE TRACKING TABLE
-- Tracks user usage with sliding window counters
-- ============================================================================

CREATE TABLE usage_tracking (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    window_start TIMESTAMPTZ NOT NULL,
    window_end TIMESTAMPTZ NOT NULL,
    message_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE usage_tracking ENABLE ROW LEVEL SECURITY;

-- Users can view own usage
CREATE POLICY "Users can view own usage"
    ON usage_tracking FOR SELECT
    USING (auth.uid() = user_id);

-- Create indexes for efficient queries
CREATE INDEX idx_usage_tracking_user_id ON usage_tracking(user_id);
CREATE INDEX idx_usage_tracking_window ON usage_tracking(user_id, window_end DESC);

-- ============================================================================
-- PAYMENT TRANSACTIONS TABLE
-- Stores payment transaction history
-- ============================================================================

CREATE TABLE payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    subscription_id UUID REFERENCES user_subscriptions(id),
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    provider TEXT NOT NULL CHECK (provider IN ('stripe', 'hyperpay')),
    external_transaction_id TEXT,
    status TEXT NOT NULL CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Users can view own transactions
CREATE POLICY "Users can view own transactions"
    ON payment_transactions FOR SELECT
    USING (auth.uid() = user_id);

-- Create indexes
CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);

-- ============================================================================
-- FUNCTIONS
-- Helper functions for business logic
-- ============================================================================

-- Function to get user's current tier limits
CREATE OR REPLACE FUNCTION get_user_tier_limits(p_user_id UUID)
RETURNS TABLE (
    message_limit INTEGER,
    time_window_hours INTEGER,
    tier_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        st.message_limit,
        st.time_window_hours,
        st.name
    FROM user_subscriptions us
    JOIN subscription_tiers st ON us.tier_id = st.id
    WHERE us.user_id = p_user_id
    AND us.status = 'active'
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is within usage limits
CREATE OR REPLACE FUNCTION check_usage_limit(p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_limit INTEGER;
    v_window_hours INTEGER;
    v_current_usage INTEGER;
    v_window_start TIMESTAMPTZ;
BEGIN
    -- Get user's tier limits
    SELECT message_limit, time_window_hours
    INTO v_limit, v_window_hours
    FROM get_user_tier_limits(p_user_id);

    IF v_limit IS NULL THEN
        RETURN FALSE;
    END IF;

    -- Calculate window start time
    v_window_start := NOW() - (v_window_hours || ' hours')::INTERVAL;

    -- Count messages in current window
    SELECT COALESCE(SUM(message_count), 0)
    INTO v_current_usage
    FROM usage_tracking
    WHERE user_id = p_user_id
    AND window_end > v_window_start;

    RETURN v_current_usage < v_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment usage counter
CREATE OR REPLACE FUNCTION increment_usage(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_window_hours INTEGER;
    v_window_start TIMESTAMPTZ;
    v_window_end TIMESTAMPTZ;
BEGIN
    -- Get user's time window
    SELECT time_window_hours
    INTO v_window_hours
    FROM get_user_tier_limits(p_user_id);

    IF v_window_hours IS NULL THEN
        RAISE EXCEPTION 'User has no active subscription';
    END IF;

    -- Calculate current window
    v_window_end := NOW() + (v_window_hours || ' hours')::INTERVAL;
    v_window_start := NOW();

    -- Insert or update usage record
    INSERT INTO usage_tracking (user_id, window_start, window_end, message_count)
    VALUES (p_user_id, v_window_start, v_window_end, 1)
    ON CONFLICT (user_id, window_start)
    DO UPDATE SET
        message_count = usage_tracking.message_count + 1,
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_subscription_tiers_updated_at BEFORE UPDATE ON subscription_tiers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_subscriptions_updated_at BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_conversations_updated_at BEFORE UPDATE ON conversations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

-- Additional composite indexes for common queries
CREATE INDEX idx_messages_conversation_created ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_usage_tracking_user_window ON usage_tracking(user_id, window_start, window_end);

-- ============================================================================
-- COMMENTS FOR DOCUMENTATION
-- ============================================================================

COMMENT ON TABLE profiles IS 'Extended user profile information';
COMMENT ON TABLE subscription_tiers IS 'Configurable subscription tier definitions';
COMMENT ON TABLE user_subscriptions IS 'User subscription status and history';
COMMENT ON TABLE ai_providers IS 'AI provider configurations';
COMMENT ON TABLE conversations IS 'Chat conversation metadata';
COMMENT ON TABLE messages IS 'Individual messages in conversations';
COMMENT ON TABLE message_summaries IS 'Summaries of old messages for token optimization';
COMMENT ON TABLE usage_tracking IS 'Sliding window usage counters';
COMMENT ON TABLE payment_transactions IS 'Payment transaction history';

COMMENT ON FUNCTION check_usage_limit IS 'Checks if user is within their tier usage limits';
COMMENT ON FUNCTION increment_usage IS 'Increments user usage counter for sliding window tracking';
COMMENT ON FUNCTION get_user_tier_limits IS 'Retrieves user current tier limits';
