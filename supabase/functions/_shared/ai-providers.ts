// AI Provider abstraction layer

export interface AIMessage {
  role: 'user' | 'assistant' | 'system';
  content: string;
}

export interface AIResponse {
  content: string;
  model: string;
  tokens_used?: number;
}

export abstract class AIProviderBase {
  protected apiKey: string;
  protected baseUrl: string;

  constructor(apiKey: string, baseUrl: string) {
    this.apiKey = apiKey;
    this.baseUrl = baseUrl;
  }

  abstract chat(messages: AIMessage[], model: string): Promise<AIResponse>;
}

export class OpenAIProvider extends AIProviderBase {
  async chat(messages: AIMessage[], model: string): Promise<AIResponse> {
    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenAI API error: ${error}`);
    }

    const data = await response.json();

    return {
      content: data.choices[0].message.content,
      model: data.model,
      tokens_used: data.usage?.total_tokens,
    };
  }
}

export class AnthropicProvider extends AIProviderBase {
  async chat(messages: AIMessage[], model: string): Promise<AIResponse> {
    // Extract system message if present
    const systemMessage = messages.find(m => m.role === 'system');
    const chatMessages = messages.filter(m => m.role !== 'system');

    const response = await fetch(`${this.baseUrl}/messages`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': this.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model,
        max_tokens: 4096,
        system: systemMessage?.content,
        messages: chatMessages,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Anthropic API error: ${error}`);
    }

    const data = await response.json();

    return {
      content: data.content[0].text,
      model: data.model,
      tokens_used: data.usage?.input_tokens + data.usage?.output_tokens,
    };
  }
}

export class OpenRouterProvider extends AIProviderBase {
  async chat(messages: AIMessage[], model: string): Promise<AIResponse> {
    const response = await fetch(`${this.baseUrl}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${this.apiKey}`,
        'HTTP-Referer': 'https://your-app.com',
        'X-Title': 'AI Aggregator',
      },
      body: JSON.stringify({
        model,
        messages,
      }),
    });

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`OpenRouter API error: ${error}`);
    }

    const data = await response.json();

    return {
      content: data.choices[0].message.content,
      model: data.model,
      tokens_used: data.usage?.total_tokens,
    };
  }
}

export function getAIProvider(providerType: string, baseUrl: string): AIProviderBase {
  let apiKey: string;

  switch (providerType) {
    case 'openai':
      apiKey = Deno.env.get('OPENAI_API_KEY') ?? '';
      return new OpenAIProvider(apiKey, baseUrl);

    case 'anthropic':
      apiKey = Deno.env.get('ANTHROPIC_API_KEY') ?? '';
      return new AnthropicProvider(apiKey, baseUrl);

    case 'openrouter':
      apiKey = Deno.env.get('OPENROUTER_API_KEY') ?? '';
      return new OpenRouterProvider(apiKey, baseUrl);

    default:
      throw new Error(`Unknown provider type: ${providerType}`);
  }
}
