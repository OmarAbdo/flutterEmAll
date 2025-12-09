// Shared TypeScript types for Edge Functions

export interface AIProvider {
  id: string;
  name: string;
  provider_type: 'openai' | 'anthropic' | 'openrouter' | 'custom';
  base_url: string;
  config: {
    models?: string[];
  };
}

export interface Message {
  id?: string;
  conversation_id: string;
  role: 'user' | 'assistant' | 'system';
  content: string;
  provider_id?: string;
  model?: string;
  tokens_used?: number;
  metadata?: Record<string, unknown>;
  created_at?: string;
}

export interface Conversation {
  id: string;
  user_id: string;
  title?: string;
  current_provider_id?: string;
  current_model?: string;
  metadata?: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface SubscriptionTier {
  id: string;
  name: 'free' | 'premium_1' | 'premium_2';
  message_limit: number;
  time_window_hours: number;
  features: string[];
}

export interface UserSubscription {
  id: string;
  user_id: string;
  tier_id: string;
  status: 'active' | 'canceled' | 'expired' | 'past_due';
  payment_provider?: 'stripe' | 'hyperpay';
  external_subscription_id?: string;
}

export interface ChatRequest {
  conversation_id?: string;
  message: string;
  provider_id: string;
  model: string;
}

export interface ChatResponse {
  conversation_id: string;
  message_id: string;
  content: string;
  model: string;
  provider: string;
  tokens_used?: number;
}

export interface UsageCheck {
  allowed: boolean;
  current_usage: number;
  limit: number;
  reset_at?: string;
}
