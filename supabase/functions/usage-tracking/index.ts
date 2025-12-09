// Usage Tracking Edge Function
// Returns user's current usage and limits

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createSupabaseClient, getUserFromRequest } from '../_shared/supabase.ts';
import { corsHeaders, handleCors } from '../_shared/cors.ts';

serve(async (req) => {
  // Handle CORS
  const corsResponse = handleCors(req);
  if (corsResponse) return corsResponse;

  try {
    // Authenticate user
    const user = await getUserFromRequest(req);
    const supabase = createSupabaseClient(req);

    // Get user's tier limits
    const { data: tierLimits, error: tierError } = await supabase.rpc('get_user_tier_limits', {
      p_user_id: user.id,
    });

    if (tierError) {
      throw new Error(`Failed to get tier limits: ${tierError.message}`);
    }

    if (!tierLimits || tierLimits.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No active subscription found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const limits = tierLimits[0];

    // Calculate window start time
    const windowStart = new Date();
    windowStart.setHours(windowStart.getHours() - limits.time_window_hours);

    // Get current usage
    const { data: usage, error: usageError } = await supabase
      .from('usage_tracking')
      .select('message_count')
      .eq('user_id', user.id)
      .gt('window_end', windowStart.toISOString());

    if (usageError) {
      throw new Error(`Failed to get usage: ${usageError.message}`);
    }

    const currentUsage = usage?.reduce((sum, record) => sum + record.message_count, 0) || 0;

    // Calculate reset time (end of current window)
    const resetAt = new Date();
    resetAt.setHours(resetAt.getHours() + limits.time_window_hours);

    return new Response(
      JSON.stringify({
        current_usage: currentUsage,
        limit: limits.message_limit,
        remaining: Math.max(0, limits.message_limit - currentUsage),
        time_window_hours: limits.time_window_hours,
        tier_name: limits.tier_name,
        reset_at: resetAt.toISOString(),
        allowed: currentUsage < limits.message_limit,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    console.error('Error in usage-tracking function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
