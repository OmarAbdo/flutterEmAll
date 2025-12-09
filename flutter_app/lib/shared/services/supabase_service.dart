import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat.dart';
import '../models/subscription.dart';
import '../models/user_profile.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance!;

  final SupabaseClient _client;

  SupabaseService._(this._client);

  static Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _instance = SupabaseService._(Supabase.instance.client);
  }

  SupabaseClient get client => _client;
  User? get currentUser => _client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Auth methods
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<void> signInWithProvider(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(provider);
  }

  // Profile methods
  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();

    return UserProfile.fromJson(response);
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client.from('profiles').update(data).eq('id', userId);
  }

  // Conversation methods
  Future<List<Conversation>> getConversations() async {
    final response = await _client
        .from('conversations')
        .select()
        .order('updated_at', ascending: false);

    return (response as List)
        .map((json) => Conversation.fromJson(json))
        .toList();
  }

  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _client.from('conversations').delete().eq('id', conversationId);
  }

  // AI Providers methods
  Future<List<AIProvider>> getAIProviders() async {
    final response = await _client
        .from('ai_providers')
        .select()
        .eq('is_active', true);

    return (response as List)
        .map((json) => AIProvider.fromJson(json))
        .toList();
  }

  // Subscription methods
  Future<UserSubscription?> getCurrentSubscription() async {
    try {
      final response = await _client
          .from('user_subscriptions')
          .select('*, subscription_tiers(*)')
          .eq('user_id', currentUser!.id)
          .single();

      return UserSubscription.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  Future<List<SubscriptionTier>> getSubscriptionTiers() async {
    final response = await _client
        .from('subscription_tiers')
        .select()
        .eq('is_active', true)
        .order('price_monthly', ascending: true);

    return (response as List)
        .map((json) => SubscriptionTier.fromJson(json))
        .toList();
  }

  // Usage tracking
  Future<UsageInfo?> getUsageInfo() async {
    try {
      final response = await _client.functions.invoke(
        'usage-tracking',
        method: HttpMethod.get,
      );

      if (response.status == 200) {
        return UsageInfo.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Chat
  Future<ChatResponse> sendMessage(ChatRequest request) async {
    final response = await _client.functions.invoke(
      'ai-chat',
      body: request.toJson(),
    );

    if (response.status != 200) {
      throw Exception(response.data['error'] ?? 'Failed to send message');
    }

    return ChatResponse.fromJson(response.data);
  }

  // Summarize messages
  Future<void> summarizeConversation(String conversationId) async {
    await _client.functions.invoke(
      'message-summarizer',
      body: {'conversation_id': conversationId},
    );
  }
}
