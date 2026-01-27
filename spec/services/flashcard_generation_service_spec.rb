require 'rails_helper'

RSpec.describe FlashcardGenerationService do
  describe '#generate' do
    context 'when generation is successful' do
      it 'returns flashcards data with metadata' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => 'What is Ruby on Rails?', 'answer' => 'A web application framework' },
            { 'question' => 'What pattern does Rails follow?', 'answer' => 'MVC pattern' }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new
        result = service.generate(source_text)

        expect(result).to be_a(Hash)
        expect(result).to have_key(:flashcards)
        expect(result).to have_key(:metadata)

        flashcards = result[:flashcards]
        expect(flashcards).to be_an(Array)
        expect(flashcards.length).to eq(2)
        expect(flashcards.first).to have_key(:front)
        expect(flashcards.first).to have_key(:back)

        metadata = result[:metadata]
        expect(metadata).to have_key(:model)
        expect(metadata).to have_key(:generation_duration)
        expect(metadata).to have_key(:generated_count)
        expect(metadata[:model]).to eq('openai/gpt-4o-mini')
        expect(metadata[:generated_count]).to eq(2)
        expect(metadata[:generation_duration]).to be >= 0
      end

      it 'strips whitespace from questions and answers' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => '  What is Rails?  ', 'answer' => '  A framework  ' }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new
        result = service.generate(source_text)

        flashcards = result[:flashcards]
        expect(flashcards.first[:front]).to eq('What is Rails?')
        expect(flashcards.first[:back]).to eq('A framework')
      end
    end

    context 'when source text is blank' do
      it 'raises ArgumentError' do
        service = described_class.new

        expect {
          service.generate('')
        }.to raise_error(ArgumentError, 'Source text cannot be blank')
      end
    end

    context 'when response format is invalid' do
      it 'raises ResponseParseError when flashcards key is missing' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = { 'data' => [] }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /Invalid flashcards format/)
      end

      it 'raises ResponseParseError when flashcards array is empty' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = { 'flashcards' => [] }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /Invalid flashcards format|No flashcards generated/)
      end
    end

    context 'when flashcard validation fails' do
      it 'raises error for blank question' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => '', 'answer' => 'Some answer' }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /question cannot be blank/)
      end

      it 'raises error for blank answer' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => 'What is Rails?', 'answer' => '' }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /answer cannot be blank/)
      end

      it 'raises error for question too long' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => 'a' * 201, 'answer' => 'Answer' }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /question too long/)
      end

      it 'raises error for answer too long' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        mock_response = {
          'flashcards' => [
            { 'question' => 'Question?', 'answer' => 'a' * 501 }
          ]
        }

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete).and_return(mock_response)

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::ResponseParseError, /answer too long/)
      end
    end

    context 'when OpenRouter API fails' do
      it 'propagates OpenRouterService errors' do
        source_text = <<~TEXT
          Ruby on Rails is a web application framework written in Ruby.
          It follows the Model-View-Controller (MVC) architectural pattern.
          Rails emphasizes convention over configuration and the DRY principle.
        TEXT

        # Mock OpenRouterService initialization to avoid API key requirement
        mock_openrouter = instance_double(OpenRouterService)
        allow(OpenRouterService).to receive(:new).and_return(mock_openrouter)
        allow(mock_openrouter).to receive(:complete)
          .and_raise(OpenRouterService::RateLimitError, 'Rate limit exceeded')

        service = described_class.new

        expect {
          service.generate(source_text)
        }.to raise_error(OpenRouterService::RateLimitError, 'Rate limit exceeded')
      end
    end
  end

  describe '#initialize' do
    it 'accepts custom model' do
      service = described_class.new(model: 'openai/gpt-4o')
      expect(service.instance_variable_get(:@model)).to eq('openai/gpt-4o')
    end

    it 'accepts custom temperature' do
      service = described_class.new(temperature: 0.5)
      expect(service.instance_variable_get(:@temperature)).to eq(0.5)
    end

    it 'uses default model when not specified' do
      service = described_class.new
      expect(service.instance_variable_get(:@model)).to eq('openai/gpt-4o-mini')
    end
  end
end
