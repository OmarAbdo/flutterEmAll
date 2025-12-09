// Subscriptions Management Edge Function
// Handles subscription creation, upgrades, and webhook processing

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, getUserFromRequest, createServiceClient } from '../_shared/supabase.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

// Payment provider abstraction
interface PaymentProvider {
  createSubscription(userId: string, tierId: string, priceId: string): Promise<{ subscription_id: string; checkout_url?: string }>;
  cancelSubscription(subscriptionId: string): Promise<void>;
  handleWebhook(payload: unknown, signature: string): Promise<WebhookResult>;
}

interface WebhookResult {
  type: 'subscription_created' | 'subscription_updated' | 'subscription_canceled' | 'payment_succeeded' | 'payment_failed';
  subscription_id: string;
  user_id?: string;
  status?: string;
}

// Stripe Provider Implementation
class StripeProvider implements PaymentProvider {
  private apiKey: string;

  constructor() {
    this.apiKey = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
  }

  async createSubscription(userId: string, tierId: string, priceId: string) {
    // Implementation would call Stripe API
    // This is a placeholder that shows the structure
    const response = await fetch('https://api.stripe.com/v1/checkout/sessions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        'payment_method_types[]': 'card',
        'line_items[0][price]': priceId,
        'line_items[0][quantity]': '1',
        mode: 'subscription',
        success_url: 'https://yourapp.com/success',
        cancel_url: 'https://yourapp.com/cancel',
        client_reference_id: userId,
        metadata: JSON.stringify({ user_id: userId, tier_id: tierId }),
      }),
    });

    const data = await response.json();
    return {
      subscription_id: data.id,
      checkout_url: data.url,
    };
  }

  async cancelSubscription(subscriptionId: string) {
    await fetch(`https://api.stripe.com/v1/subscriptions/${subscriptionId}`, {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
      },
    });
  }

  async handleWebhook(payload: unknown, signature: string): Promise<WebhookResult> {
    // Verify webhook signature
    const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SECRET') ?? '';

    // In production, verify the signature using Stripe's library
    // For now, this is a simplified version

    const event = payload as any;

    switch (event.type) {
      case 'checkout.session.completed':
        return {
          type: 'subscription_created',
          subscription_id: event.data.object.subscription,
          user_id: event.data.object.client_reference_id,
        };

      case 'customer.subscription.updated':
        return {
          type: 'subscription_updated',
          subscription_id: event.data.object.id,
          status: event.data.object.status,
        };

      case 'customer.subscription.deleted':
        return {
          type: 'subscription_canceled',
          subscription_id: event.data.object.id,
        };

      default:
        throw new Error(`Unhandled event type: ${event.type}`);
    }
  }
}

// HyperPay Provider Implementation
class HyperPayProvider implements PaymentProvider {
  private apiKey: string;
  private entityId: string;

  constructor() {
    this.apiKey = Deno.env.get('HYPERPAY_API_KEY') ?? '';
    this.entityId = Deno.env.get('HYPERPAY_ENTITY_ID') ?? '';
  }

  async createSubscription(userId: string, tierId: string, amount: string) {
    // HyperPay checkout creation
    const response = await fetch('https://eu-prod.oppwa.com/v1/checkouts', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        entityId: this.entityId,
        amount: amount,
        currency: 'SAR',
        paymentType: 'DB',
        'recurringType': 'REPEATED',
        'merchantTransactionId': `sub_${userId}_${Date.now()}`,
        'customer.email': userId,
      }),
    });

    const data = await response.json();
    return {
      subscription_id: data.id,
      checkout_url: `https://yourapp.com/payment?checkoutId=${data.id}`,
    };
  }

  async cancelSubscription(subscriptionId: string) {
    // HyperPay doesn't have direct subscription cancellation
    // Would need to be handled through their dashboard or API
    throw new Error('HyperPay subscription cancellation requires manual process');
  }

  async handleWebhook(payload: unknown, signature: string): Promise<WebhookResult> {
    // HyperPay webhook handling
    // This is simplified - actual implementation would parse HyperPay's webhook format
    const event = payload as any;

    return {
      type: 'payment_succeeded',
      subscription_id: event.id,
    };
  }
}

// Factory function to get payment provider
function getPaymentProvider(providerName: string): PaymentProvider {
  switch (providerName) {
    case 'stripe':
      return new StripeProvider();
    case 'hyperpay':
      return new HyperPayProvider();
    default:
      throw new Error(`Unknown payment provider: ${providerName}`);
  }
}

serve(async (req) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  const url = new URL(req.url);
  const path = url.pathname.split('/').pop();

  try {
    // Route: Create subscription
    if (path === 'create' && req.method === 'POST') {
      const user = await getUserFromRequest(req);
      const supabase = createSupabaseClient(req);

      const { tier_id, payment_provider, price_id } = await req.json();

      if (!tier_id || !payment_provider) {
        return new Response(
          JSON.stringify({ error: 'Missing tier_id or payment_provider' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Get tier details
      const { data: tier, error: tierError } = await supabase
        .from('subscription_tiers')
        .select('*')
        .eq('id', tier_id)
        .single();

      if (tierError || !tier) {
        return new Response(
          JSON.stringify({ error: 'Invalid tier' }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Create subscription with payment provider
      const provider = getPaymentProvider(payment_provider);
      const result = await provider.createSubscription(user.id, tier_id, price_id || tier.price_monthly.toString());

      return new Response(
        JSON.stringify({
          success: true,
          checkout_url: result.checkout_url,
          subscription_id: result.subscription_id,
        }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Route: Cancel subscription
    if (path === 'cancel' && req.method === 'POST') {
      const user = await getUserFromRequest(req);
      const supabase = createSupabaseClient(req);

      // Get user's subscription
      const { data: subscription, error: subError } = await supabase
        .from('user_subscriptions')
        .select('*')
        .eq('user_id', user.id)
        .single();

      if (subError || !subscription) {
        return new Response(
          JSON.stringify({ error: 'No active subscription found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Cancel with payment provider
      if (subscription.external_subscription_id && subscription.payment_provider) {
        const provider = getPaymentProvider(subscription.payment_provider);
        await provider.cancelSubscription(subscription.external_subscription_id);
      }

      // Update subscription status
      await supabase
        .from('user_subscriptions')
        .update({
          cancel_at_period_end: true,
          status: 'canceled',
        })
        .eq('id', subscription.id);

      return new Response(
        JSON.stringify({ success: true, message: 'Subscription canceled' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Route: Webhook handler
    if (path === 'webhook' && req.method === 'POST') {
      const signature = req.headers.get('stripe-signature') || req.headers.get('x-hyperpay-signature') || '';
      const payload = await req.json();

      // Determine provider from headers or payload
      const provider_name = signature.includes('stripe') ? 'stripe' : 'hyperpay';
      const provider = getPaymentProvider(provider_name);

      const result = await provider.handleWebhook(payload, signature);

      // Update subscription in database using service client (bypass RLS)
      const serviceClient = createServiceClient();

      if (result.type === 'subscription_created' && result.user_id) {
        // Get tier from metadata or default to premium_1
        const { data: tier } = await serviceClient
          .from('subscription_tiers')
          .select('id')
          .eq('name', 'premium_1')
          .single();

        await serviceClient.from('user_subscriptions').upsert({
          user_id: result.user_id,
          tier_id: tier?.id,
          status: 'active',
          payment_provider: provider_name,
          external_subscription_id: result.subscription_id,
          current_period_start: new Date().toISOString(),
          current_period_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
        });
      }

      return new Response(
        JSON.stringify({ received: true }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Route: Get current subscription
    if (path === 'current' && req.method === 'GET') {
      const user = await getUserFromRequest(req);
      const supabase = createSupabaseClient(req);

      const { data: subscription, error } = await supabase
        .from('user_subscriptions')
        .select('*, subscription_tiers(*)')
        .eq('user_id', user.id)
        .single();

      if (error) {
        return new Response(
          JSON.stringify({ error: 'No subscription found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(JSON.stringify(subscription), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(
      JSON.stringify({ error: 'Route not found' }),
      { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in subscriptions function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
