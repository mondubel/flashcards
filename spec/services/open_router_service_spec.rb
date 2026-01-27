require 'rails_helper'

RSpec.describe OpenRouterService do
  describe '#initialize' do
    context 'when API key is provided' do
      it 'initializes successfully with api_key parameter' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        service = described_class.new(model: model, api_key: api_key)

        expect(service.model).to eq(model)
        expect(service.temperature).to eq(0.7)
        expect(service.max_tokens).to eq(2000)
      end
    end

    context 'when API key is in environment' do
      it 'uses API key from environment variable' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return(api_key)

        service = described_class.new(model: model)
        expect(service.send(:api_key)).to eq(api_key)
      end
    end

    context 'when API key is in Rails credentials' do
      it 'uses API key from credentials' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:dig)
          .with(:openrouter, :api_key).and_return(api_key)

        service = described_class.new(model: model)
        expect(service.send(:api_key)).to eq(api_key)
      end
    end

    context 'when API key is missing' do
      it 'raises ConfigurationError' do
        model = 'openai/gpt-4o-mini'

        allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return(nil)
        allow(Rails.application.credentials).to receive(:dig)
          .with(:openrouter, :api_key).and_return(nil)

        expect {
          described_class.new(model: model)
        }.to raise_error(
          OpenRouterService::ConfigurationError,
          /API key is missing/
        )
      end
    end

    context 'when model is blank' do
      it 'raises ConfigurationError' do
        api_key = 'sk-or-v1-test-key-1234567890'

        expect {
          described_class.new(model: '', api_key: api_key)
        }.to raise_error(
          OpenRouterService::ConfigurationError,
          'Model name is required.'
        )
      end
    end

    context 'with custom parameters' do
      it 'accepts custom temperature' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        service = described_class.new(
          model: model,
          api_key: api_key,
          temperature: 0.3
        )

        expect(service.temperature).to eq(0.3)
      end

      it 'accepts custom max_tokens' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        service = described_class.new(
          model: model,
          api_key: api_key,
          max_tokens: 4000
        )

        expect(service.max_tokens).to eq(4000)
      end

      it 'accepts skip_ssl_verify parameter' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'

        service = described_class.new(
          model: model,
          api_key: api_key,
          skip_ssl_verify: true
        )

        expect(service.instance_variable_get(:@skip_ssl_verify)).to be true
      end
    end
  end

  describe '#complete' do
    context 'when request is successful' do
      it 'returns parsed response' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .with(
            body: hash_including(
              model: model,
              messages: [
                { role: 'system', content: system_message },
                { role: 'user', content: user_message }
              ]
            ),
            headers: {
              'Content-Type' => 'application/json',
              'Authorization' => "Bearer #{api_key}"
            }
          )
          .to_return(
            status: 200,
            body: {
              choices: [
                { message: { content: 'Hello! How can I help you?' } }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)
        response = service.complete(
          system_message: system_message,
          user_message: user_message
        )

        expect(response).to eq({ 'content' => 'Hello! How can I help you?' })
      end
    end

    context 'when using structured output' do
      it 'returns structured response' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'
        response_format = {
          type: 'json_schema',
          json_schema: {
            name: 'test_schema',
            strict: true,
            schema: {
              type: 'object',
              properties: {
                message: { type: 'string' }
              },
              required: [ 'message' ],
              additionalProperties: false
            }
          }
        }

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 200,
            body: {
              choices: [
                { message: { content: '{"message":"Hello! How can I help you?"}' } }
              ]
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)
        response = service.complete(
          system_message: system_message,
          user_message: user_message,
          response_format: response_format
        )

        expect(response).to eq({ 'message' => 'Hello! How can I help you?' })
      end
    end

    context 'when API returns authentication error' do
      it 'raises AuthenticationError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 401,
            body: { error: { message: 'Invalid API key' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(
          OpenRouterService::AuthenticationError,
          /Invalid API key/
        )
      end
    end

    context 'when API returns rate limit error' do
      it 'raises RateLimitError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 429,
            body: { error: { message: 'Rate limit exceeded' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::RateLimitError, /Rate limit exceeded/)
      end
    end

    context 'when API returns insufficient credits error' do
      it 'raises InsufficientCreditsError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 402,
            body: { error: { message: 'Insufficient credits' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(
          OpenRouterService::InsufficientCreditsError,
          /Insufficient credits/
        )
      end
    end

    context 'when API returns bad request error' do
      it 'raises InvalidRequestError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 400,
            body: { error: { message: 'Invalid request' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::InvalidRequestError, /Invalid request/)
      end
    end

    context 'when API returns server error' do
      it 'raises ServerError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 500,
            body: { error: { message: 'Internal server error' } }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::ServerError, /server error/)
      end
    end

    context 'when response contains error in body (HTTP 200)' do
      it 'raises APIError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 200,
            body: {
              error: {
                code: 'provider_error',
                message: 'Provider returned error'
              }
            }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::APIError, /Provider returned error/)
      end
    end

    context 'when network timeout occurs' do
      it 'raises NetworkError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_timeout

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::NetworkError, /timeout/)
      end
    end

    context 'when response is invalid JSON' do
      it 'raises ResponseParseError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 200,
            body: 'invalid json',
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::ResponseParseError)
      end
    end

    context 'when response is missing content' do
      it 'raises ResponseParseError' do
        api_key = 'sk-or-v1-test-key-1234567890'
        model = 'openai/gpt-4o-mini'
        system_message = 'You are a helpful assistant.'
        user_message = 'Hello, world!'

        stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
          .to_return(
            status: 200,
            body: { choices: [] }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )

        service = described_class.new(model: model, api_key: api_key, skip_ssl_verify: true)

        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::ResponseParseError, /No content/)
      end
    end
  end
end
