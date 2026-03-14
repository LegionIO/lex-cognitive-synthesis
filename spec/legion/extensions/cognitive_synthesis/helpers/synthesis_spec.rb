# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveSynthesis::Helpers::Synthesis do
  subject(:synthesis) do
    described_class.new(
      streams:    %w[abc def],
      coherence:  0.75,
      novelty:    0.8,
      confidence: 0.7,
      content:    { dominant_type: :emotional, stream_count: 2 }
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(synthesis.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'stores stream ids' do
      expect(synthesis.streams).to eq(%w[abc def])
    end

    it 'clamps coherence to 0-1' do
      s = described_class.new(streams: [], coherence: 1.5, novelty: 0.5, confidence: 0.5, content: {})
      expect(s.coherence).to eq(1.0)
    end

    it 'clamps novelty to 0-1' do
      s = described_class.new(streams: [], coherence: 0.5, novelty: -0.5, confidence: 0.5, content: {})
      expect(s.novelty).to eq(0.0)
    end

    it 'clamps confidence to 0-1' do
      s = described_class.new(streams: [], coherence: 0.5, novelty: 0.5, confidence: 2.0, content: {})
      expect(s.confidence).to eq(1.0)
    end

    it 'sets created_at as UTC time' do
      expect(synthesis.created_at).to be_a(Time)
    end
  end

  describe '#fragmented?' do
    it 'returns false when coherence >= COHERENCE_THRESHOLD' do
      expect(synthesis.fragmented?).to be false
    end

    it 'returns true when coherence < COHERENCE_THRESHOLD' do
      s = described_class.new(streams: [], coherence: 0.4, novelty: 0.5, confidence: 0.5, content: {})
      expect(s.fragmented?).to be true
    end
  end

  describe '#novel?' do
    it 'returns true when novelty > NOVELTY_THRESHOLD' do
      expect(synthesis.novel?).to be true
    end

    it 'returns false when novelty <= NOVELTY_THRESHOLD' do
      s = described_class.new(streams: [], coherence: 0.5, novelty: 0.5, confidence: 0.5, content: {})
      expect(s.novel?).to be false
    end
  end

  describe '#coherence_label' do
    it 'returns :coherent for coherence 0.75' do
      expect(synthesis.coherence_label).to eq(:coherent)
    end

    it 'returns :unified for coherence 0.9' do
      s = described_class.new(streams: [], coherence: 0.9, novelty: 0.5, confidence: 0.5, content: {})
      expect(s.coherence_label).to eq(:unified)
    end
  end

  describe '#confidence_label' do
    it 'returns :confident for confidence 0.7' do
      expect(synthesis.confidence_label).to eq(:confident)
    end
  end

  describe '#to_h' do
    let(:hash) { synthesis.to_h }

    it 'includes all expected keys' do
      %i[id streams coherence novelty confidence content fragmented novel
         coherence_label confidence_label created_at].each do |key|
        expect(hash).to have_key(key)
      end
    end

    it 'reflects fragmented state' do
      s = described_class.new(streams: [], coherence: 0.3, novelty: 0.5, confidence: 0.5, content: {})
      expect(s.to_h[:fragmented]).to be true
    end

    it 'reflects novel state' do
      expect(hash[:novel]).to be true
    end
  end
end
