import 'package:json_annotation/json_annotation.dart';

part 'chat.g.dart';

@JsonSerializable()
class AIProvider {
  final String id;
  final String name;
  final String displayName;
  final String providerType;
  final String? baseUrl;
  final bool isActive;
  final Map<String, dynamic>? config;

  AIProvider({
    required this.id,
    required this.name,
    required this.displayName,
    required this.providerType,
    this.baseUrl,
    this.isActive = true,
    this.config,
  });

  factory AIProvider.fromJson(Map<String, dynamic> json) =>
      _$AIProviderFromJson(json);

  Map<String, dynamic> toJson() => _$AIProviderToJson(this);

  List<String> get models {
    if (config != null && config!['models'] != null) {
      return List<String>.from(config!['models']);
    }
    return [];
  }
}

@JsonSerializable()
class Conversation {
  final String id;
  final String userId;
  final String? title;
  final String? currentProviderId;
  final String? currentModel;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.userId,
    this.title,
    this.currentProviderId,
    this.currentModel,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);

  Conversation copyWith({
    String? title,
    String? currentProviderId,
    String? currentModel,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id,
      userId: userId,
      title: title ?? this.title,
      currentProviderId: currentProviderId ?? this.currentProviderId,
      currentModel: currentModel ?? this.currentModel,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

@JsonSerializable()
class Message {
  final String? id;
  final String conversationId;
  final String role;
  final String content;
  final String? providerId;
  final String? model;
  final int? tokensUsed;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;

  Message({
    this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.providerId,
    this.model,
    this.tokensUsed,
    this.metadata,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get isSystem => role == 'system';
}

@JsonSerializable()
class ChatRequest {
  final String? conversationId;
  final String message;
  final String providerId;
  final String model;

  ChatRequest({
    this.conversationId,
    required this.message,
    required this.providerId,
    required this.model,
  });

  factory ChatRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ChatRequestToJson(this);
}

@JsonSerializable()
class ChatResponse {
  final String conversationId;
  final String messageId;
  final String content;
  final String model;
  final String provider;
  final int? tokensUsed;

  ChatResponse({
    required this.conversationId,
    required this.messageId,
    required this.content,
    required this.model,
    required this.provider,
    this.tokensUsed,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ChatResponseToJson(this);
}
