// Message Summarizer Edge Function
// Summarizes old messages in a conversation to save tokens

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, getUserFromRequest } from '../_shared/supabase.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';
import { getAIProvider } from '../_shared/ai-providers.ts';

serve(async (req) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    // Authenticate user
    const user = await getUserFromRequest(req);
    const supabase = createSupabaseClient(req);

    // Parse request
    const { conversation_id } = await req.json();

    if (!conversation_id) {
      return new Response(
        JSON.stringify({ error: 'Missing conversation_id' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Verify conversation belongs to user
    const { data: conversation, error: convError } = await supabase
      .from('conversations')
      .select('*')
      .eq('id', conversation_id)
      .eq('user_id', user.id)
      .single();

    if (convError || !conversation) {
      return new Response(
        JSON.stringify({ error: 'Conversation not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get all messages except the last 10
    const { data: messages, error: messagesError } = await supabase
      .from('messages')
      .select('id, role, content, created_at')
      .eq('conversation_id', conversation_id)
      .order('created_at', { ascending: true });

    if (messagesError) {
      throw new Error(`Failed to fetch messages: ${messagesError.message}`);
    }

    // Only summarize if we have more than 10 messages
    if (messages.length <= 10) {
      return new Response(
        JSON.stringify({ message: 'Not enough messages to summarize' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Get messages to summarize (all except last 10)
    const messagesToSummarize = messages.slice(0, -10);

    // Build conversation text
    const conversationText = messagesToSummarize
      .map((m) => `${m.role}: ${m.content}`)
      .join('\n\n');

    // Use OpenAI to generate summary (cheapest option)
    const openaiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
    const provider = getAIProvider('openai', 'https://api.openai.com/v1');

    const summaryResponse = await provider.chat(
      [
        {
          role: 'system',
          content:
            'You are a helpful assistant that summarizes conversations. Provide a concise summary that captures the key points and context.',
        },
        {
          role: 'user',
          content: `Please summarize this conversation:\n\n${conversationText}`,
        },
      ],
      'gpt-3.5-turbo'
    );

    // Save summary
    const { data: summary, error: summaryError } = await supabase
      .from('message_summaries')
      .insert({
        conversation_id: conversation_id,
        summary: summaryResponse.content,
        message_count: messagesToSummarize.length,
        start_message_id: messagesToSummarize[0].id,
        end_message_id: messagesToSummarize[messagesToSummarize.length - 1].id,
      })
      .select()
      .single();

    if (summaryError) {
      throw new Error(`Failed to save summary: ${summaryError.message}`);
    }

    return new Response(
      JSON.stringify({
        success: true,
        summary_id: summary.id,
        messages_summarized: messagesToSummarize.length,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in message-summarizer function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
