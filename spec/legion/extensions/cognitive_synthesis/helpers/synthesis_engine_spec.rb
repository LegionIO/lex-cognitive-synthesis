# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveSynthesis::Helpers::SynthesisEngine do
  subject(:engine) { described_class.new }

  def add_stream(type: :emotional, content: { value: 1 }, weight: 0.7, confidence: 0.8)
    engine.add_stream(stream_type: type, content: content, weight: weight, confidence: confidence)
  end

  describe '#add_stream' do
    it 'returns success with stream_id' do
      result = add_stream
      expect(result[:success]).to be true
      expect(result[:stream_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores stream in @streams' do
      add_stream
      expect(engine.streams.size).to eq(1)
    end

    it 'rejects invalid stream_type' do
      result = engine.add_stream(stream_type: :invalid, content: {})
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_stream_type)
    end

    it 'accepts all valid stream types' do
      %i[emotional perceptual memorial predictive reasoning social identity motor].each do |type|
        result = engine.add_stream(stream_type: type, content: {})
        expect(result[:success]).to be true
      end
    end

    it 'prunes when exceeding MAX_STREAMS' do
      51.times { add_stream }
      expect(engine.streams.size).to eq(50)
    end
  end

  describe '#remove_stream' do
    it 'removes an existing stream' do
      result = add_stream
      remove = engine.remove_stream(stream_id: result[:stream_id])
      expect(remove[:success]).to be true
      expect(engine.streams).to be_empty
    end

    it 'returns not_found for missing stream' do
      result = engine.remove_stream(stream_id: 'nonexistent')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:not_found)
    end
  end

  describe '#synthesize!' do
    it 'fails with fewer than MIN_STREAMS_FOR_SYNTHESIS active streams' do
      add_stream
      result = engine.synthesize!
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:insufficient_streams)
    end

    it 'succeeds with enough streams' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:success]).to be true
      expect(result[:synthesis]).to have_key(:id)
    end

    it 'stores synthesis in history' do
      2.times { add_stream }
      engine.synthesize!
      expect(engine.syntheses.size).to eq(1)
    end

    it 'includes coherence in result' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:synthesis][:coherence]).to be_between(0.0, 1.0)
    end

    it 'includes novelty in result' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:synthesis][:novelty]).to be_between(0.0, 1.0)
    end

    it 'includes confidence in result' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:synthesis][:confidence]).to be_between(0.0, 1.0)
    end

    it 'marks first synthesis as maximally novel (no prior)' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:synthesis][:novelty]).to eq(1.0)
    end

    it 'caps syntheses at MAX_SYNTHESES' do
      2.times { add_stream }
      201.times { engine.synthesize! }
      expect(engine.syntheses.size).to eq(200)
    end

    it 'returns content with dominant_type' do
      2.times { add_stream }
      result = engine.synthesize!
      expect(result[:synthesis][:content]).to have_key(:dominant_type)
    end
  end

  describe '#decay_all!' do
    it 'returns success' do
      result = engine.decay_all!
      expect(result[:success]).to be true
    end

    it 'reduces freshness on all streams' do
      add_stream
      stream = engine.streams.values.first
      before = stream.freshness
      engine.decay_all!
      expect(stream.freshness).to be < before
    end

    it 'removes stale streams' do
      add_stream
      stream = engine.streams.values.first
      46.times { stream.decay_freshness! }
      engine.decay_all!
      expect(engine.streams).to be_empty
    end

    it 'reports removed and remaining counts' do
      2.times { add_stream }
      result = engine.decay_all!
      expect(result).to have_key(:streams_removed)
      expect(result).to have_key(:streams_remaining)
    end
  end

  describe '#stream_conflict?' do
    let(:id_a) { add_stream(weight: 0.9, content: { signal: :danger })[:stream_id] }
    let(:id_b) { add_stream(weight: 0.1, content: { signal: :safe })[:stream_id] }

    it 'detects weight opposition' do
      result = engine.stream_conflict?(stream_id_a: id_a, stream_id_b: id_b)
      expect(result[:success]).to be true
      expect(result[:weight_opposition]).to be true
    end

    it 'detects content conflict on shared keys' do
      result = engine.stream_conflict?(stream_id_a: id_a, stream_id_b: id_b)
      expect(result[:content_conflict]).to be true
    end

    it 'reports no conflict for compatible streams' do
      a = add_stream(weight: 0.6, content: { value: 1 })[:stream_id]
      b = add_stream(weight: 0.7, content: { value: 1 })[:stream_id]
      result = engine.stream_conflict?(stream_id_a: a, stream_id_b: b)
      expect(result[:conflict]).to be false
    end

    it 'returns not_found for missing stream' do
      result = engine.stream_conflict?(stream_id_a: 'x', stream_id_b: 'y')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:stream_not_found)
    end
  end

  describe '#dominant_stream' do
    it 'returns no_streams error when empty' do
      result = engine.dominant_stream
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:no_streams)
    end

    it 'returns the stream with highest effective_weight' do
      add_stream(weight: 0.3, confidence: 0.3)
      id = add_stream(weight: 0.9, confidence: 0.95)[:stream_id]
      result = engine.dominant_stream
      expect(result[:success]).to be true
      expect(result[:stream][:id]).to eq(id)
    end
  end

  describe '#synthesis_history' do
    it 'returns empty list when no syntheses' do
      result = engine.synthesis_history
      expect(result[:syntheses]).to be_empty
      expect(result[:count]).to eq(0)
    end

    it 'returns last N syntheses' do
      2.times { add_stream }
      5.times { engine.synthesize! }
      result = engine.synthesis_history(limit: 3)
      expect(result[:count]).to eq(3)
    end
  end

  describe '#average_coherence' do
    it 'returns 0.0 when no syntheses' do
      result = engine.average_coherence
      expect(result[:average_coherence]).to eq(0.0)
      expect(result[:sample_size]).to eq(0)
    end

    it 'computes average coherence over recent syntheses' do
      2.times { add_stream }
      3.times { engine.synthesize! }
      result = engine.average_coherence
      expect(result[:average_coherence]).to be_between(0.0, 1.0)
      expect(result[:sample_size]).to eq(3)
    end
  end

  describe '#to_h' do
    it 'returns summary stats hash' do
      add_stream(type: :emotional)
      result = engine.to_h
      expect(result).to include(:stream_count, :synthesis_count, :active_streams,
                                :stale_streams, :average_coherence)
    end

    it 'reflects current stream count' do
      3.times { add_stream }
      expect(engine.to_h[:stream_count]).to eq(3)
    end
  end
end
