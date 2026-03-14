# frozen_string_literal: true

require 'legion/extensions/cognitive_synthesis/client'

RSpec.describe Legion::Extensions::CognitiveSynthesis::Runners::CognitiveSynthesis do
  let(:client) { Legion::Extensions::CognitiveSynthesis::Client.new }

  def add_two_streams
    client.add_stream(stream_type: :emotional, content: { mood: :alert }, weight: 0.8, confidence: 0.9)
    client.add_stream(stream_type: :perceptual, content: { threat: :detected }, weight: 0.6, confidence: 0.7)
  end

  describe '#add_stream' do
    it 'adds a valid stream and returns success' do
      result = client.add_stream(stream_type: :emotional, content: { mood: :calm })
      expect(result[:success]).to be true
      expect(result[:stream_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'rejects an invalid stream type' do
      result = client.add_stream(stream_type: :bogus, content: {})
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_stream_type)
    end

    it 'accepts all valid stream types' do
      %i[emotional perceptual memorial predictive reasoning social identity motor].each do |type|
        result = client.add_stream(stream_type: type, content: {})
        expect(result[:success]).to be true
      end
    end

    it 'accepts injected engine kwarg' do
      engine = Legion::Extensions::CognitiveSynthesis::Helpers::SynthesisEngine.new
      result = client.add_stream(stream_type: :reasoning, content: {}, engine: engine)
      expect(result[:success]).to be true
      expect(engine.streams.size).to eq(1)
    end
  end

  describe '#remove_stream' do
    it 'removes an existing stream' do
      add_result = client.add_stream(stream_type: :emotional, content: {})
      remove_result = client.remove_stream(stream_id: add_result[:stream_id])
      expect(remove_result[:success]).to be true
    end

    it 'returns not_found for unknown stream' do
      result = client.remove_stream(stream_id: 'nonexistent-id')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#synthesize' do
    it 'returns insufficient_streams when fewer than 2 active streams' do
      client.add_stream(stream_type: :emotional, content: {})
      result = client.synthesize
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:insufficient_streams)
    end

    it 'succeeds with 2+ active streams' do
      add_two_streams
      result = client.synthesize
      expect(result[:success]).to be true
      expect(result[:synthesis]).to have_key(:id)
    end

    it 'returns coherence between 0 and 1' do
      add_two_streams
      result = client.synthesize
      expect(result[:synthesis][:coherence]).to be_between(0.0, 1.0)
    end

    it 'returns novelty = 1.0 for first synthesis' do
      add_two_streams
      result = client.synthesize
      expect(result[:synthesis][:novelty]).to eq(1.0)
    end

    it 'uses injected engine when provided' do
      engine = Legion::Extensions::CognitiveSynthesis::Helpers::SynthesisEngine.new
      2.times { engine.add_stream(stream_type: :emotional, content: {}) }
      result = client.synthesize(engine: engine)
      expect(result[:success]).to be true
    end
  end

  describe '#decay_streams' do
    it 'returns success' do
      result = client.decay_streams
      expect(result[:success]).to be true
    end

    it 'reports removed count' do
      result = client.decay_streams
      expect(result).to have_key(:streams_removed)
    end
  end

  describe '#check_conflict' do
    it 'detects conflict between opposing streams' do
      a = client.add_stream(stream_type: :emotional, content: { signal: :danger }, weight: 0.9)
      b = client.add_stream(stream_type: :perceptual, content: { signal: :safe }, weight: 0.1)
      result = client.check_conflict(stream_id_a: a[:stream_id], stream_id_b: b[:stream_id])
      expect(result[:success]).to be true
      expect(result[:conflict]).to be true
    end

    it 'reports no conflict for similar streams' do
      a = client.add_stream(stream_type: :emotional, content: { value: 1 }, weight: 0.6)
      b = client.add_stream(stream_type: :perceptual, content: { value: 1 }, weight: 0.65)
      result = client.check_conflict(stream_id_a: a[:stream_id], stream_id_b: b[:stream_id])
      expect(result[:conflict]).to be false
    end

    it 'returns error for missing stream ids' do
      result = client.check_conflict(stream_id_a: 'x', stream_id_b: 'y')
      expect(result[:success]).to be false
    end
  end

  describe '#dominant_stream' do
    it 'returns error when no streams present' do
      result = client.dominant_stream
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:no_streams)
    end

    it 'returns stream with highest effective_weight' do
      client.add_stream(stream_type: :emotional, content: {}, weight: 0.2, confidence: 0.2)
      high = client.add_stream(stream_type: :memorial, content: {}, weight: 0.95, confidence: 0.95)
      result = client.dominant_stream
      expect(result[:stream][:id]).to eq(high[:stream_id])
    end
  end

  describe '#synthesis_history' do
    it 'returns empty list initially' do
      result = client.synthesis_history
      expect(result[:syntheses]).to be_empty
    end

    it 'returns syntheses after multiple runs' do
      add_two_streams
      3.times { client.synthesize }
      result = client.synthesis_history(limit: 2)
      expect(result[:count]).to eq(2)
    end
  end

  describe '#average_coherence' do
    it 'returns 0.0 when no syntheses' do
      result = client.average_coherence
      expect(result[:average_coherence]).to eq(0.0)
    end

    it 'returns coherence value after syntheses' do
      add_two_streams
      3.times { client.synthesize }
      result = client.average_coherence
      expect(result[:average_coherence]).to be_between(0.0, 1.0)
    end
  end

  describe '#status' do
    it 'returns success with stats' do
      result = client.status
      expect(result[:success]).to be true
      expect(result).to have_key(:stream_count)
      expect(result).to have_key(:synthesis_count)
    end

    it 'reflects added streams' do
      add_two_streams
      result = client.status
      expect(result[:stream_count]).to eq(2)
    end
  end
end
