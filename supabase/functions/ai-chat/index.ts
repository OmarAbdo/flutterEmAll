// AI Chat Edge Function
// Handles chat requests, enforces usage limits, and integrates with AI providers

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, getUserFromRequest } from '../_shared/supabase.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAIProvider } from '../_shared/ai-providers.ts';
import type { ChatRequest, ChatResponse, AIMessage } from '../_shared/types.ts';

serve(async (req) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    // Authenticate user
    const user = await getUserFromRequest(req);
    const supabase = createSupabaseClient(req);

    // Parse request
    const { conversation_id, message, provider_id, model }: ChatRequest = await req.json();

    if (!message || !provider_id || !model) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: message, provider_id, model' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Check usage limits
    const { data: usageCheck, error: usageError } = await supabase.rpc('check_usage_limit', {
      p_user_id: user.id,
    });

    if (usageError) {
      throw new Error(`Usage check failed: ${usageError.message}`);
    }

    if (!usageCheck) {
      return new Response(
        JSON.stringify({
          error: 'Usage limit exceeded',
          message: 'You have reached your message limit. Please upgrade your plan or wait for your limit to reset.',
        }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get or create conversation
    let conversationId = conversation_id;

    if (!conversationId) {
      const { data: newConversation, error: convError } = await supabase
        .from('conversations')
        .insert({
          user_id: user.id,
          current_provider_id: provider_id,
          current_model: model,
          title: message.substring(0, 50) + (message.length > 50 ? '...' : ''),
        })
        .select()
        .single();

      if (convError) {
        throw new Error(`Failed to create conversation: ${convError.message}`);
      }

      conversationId = newConversation.id;
    }

    // Get conversation history
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('role, content')
      .eq('conversation_id', conversationId)
      .order('created_at', { ascending: true });

    if (messagesError) {
      throw new Error(`Failed to fetch messages: ${messagesError.message}`);
    }

    // Build message context (latest 10 messages + summary if exists)
    const conversationMessages: AIMessage[] = [];

    // Get summary if conversation has more than 10 messages
    if (messages.length > 10) {
      const { data: summary } = await supabase
        .from('message_summaries')
        .select('summary')
        .eq('conversation_id', conversationId)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      if (summary) {
        conversationMessages.push({
          role: 'system',
          content: `Previous conversation summary: ${summary.summary}`,
        });
      }

      // Add only last 10 messages
      const recentMessages = messages.slice(-10);
      conversationMessages.push(...recentMessages);
    } else {
      conversationMessages.push(...messages);
    }

    // Add current user message
    conversationMessages.push({
      role: 'user',
      content: message,
    });

    // Get provider details
    const { data: provider, error: providerError } = await supabase
      .from('ai_providers')
      .select('*')
      .eq('id', provider_id)
      .single();

    if (providerError || !provider) {
      throw new Error('Invalid AI provider');
    }

    // Call AI provider
    const aiProvider = getAIProvider(provider.provider_type, provider.base_url);
    const aiResponse = await aiProvider.chat(conversationMessages, model);

    // Save user message
    const { data: userMessage, error: userMsgError } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        role: 'user',
        content: message,
      })
      .select()
      .single();

    if (userMsgError) {
      throw new Error(`Failed to save user message: ${userMsgError.message}`);
    }

    // Save assistant message
    const { data: assistantMessage, error: assistantMsgError } = await supabase
      .from('messages')
      .insert({
        conversation_id: conversationId,
        role: 'assistant',
        content: aiResponse.content,
        provider_id: provider_id,
        model: aiResponse.model,
        tokens_used: aiResponse.tokens_used,
      })
      .select()
      .single();

    if (assistantMsgError) {
      throw new Error(`Failed to save assistant message: ${assistantMsgError.message}`);
    }

    // Increment usage counter
    const { error: usageIncError } = await supabase.rpc('increment_usage', {
      p_user_id: user.id,
    });

    if (usageIncError) {
      console.error('Failed to increment usage:', usageIncError);
      // Don't fail the request if usage increment fails
    }

    // Update conversation timestamp
    await supabase
      .from('conversations')
      .update({ updated_at: new Date().toISOString() })
      .eq('id', conversationId);

    // Return response
    const response: ChatResponse = {
      conversation_id: conversationId,
      message_id: assistantMessage.id,
      content: aiResponse.content,
      model: aiResponse.model,
      provider: provider.name,
      tokens_used: aiResponse.tokens_used,
    };

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error) {
    console.error('Error in ai-chat function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
