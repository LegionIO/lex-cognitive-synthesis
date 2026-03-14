# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveSynthesis::Helpers::SynthesisStream do
  subject(:stream) do
    described_class.new(stream_type: :emotional, content: { mood: 'alert' }, weight: 0.8, confidence: 0.9)
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(stream.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets stream_type' do
      expect(stream.stream_type).to eq(:emotional)
    end

    it 'sets content' do
      expect(stream.content).to eq({ mood: 'alert' })
    end

    it 'clamps weight to 0-1' do
      s = described_class.new(stream_type: :perceptual, content: {}, weight: 1.5)
      expect(s.weight).to eq(1.0)
    end

    it 'clamps confidence to 0-1' do
      s = described_class.new(stream_type: :perceptual, content: {}, confidence: -0.1)
      expect(s.confidence).to eq(0.0)
    end

    it 'initializes freshness at 1.0' do
      expect(stream.freshness).to eq(1.0)
    end

    it 'sets created_at as UTC time' do
      expect(stream.created_at).to be_a(Time)
    end
  end

  describe '#decay_freshness!' do
    it 'reduces freshness by FRESHNESS_DECAY' do
      before = stream.freshness
      stream.decay_freshness!
      expect(stream.freshness).to be_within(0.001).of(before - 0.02)
    end

    it 'never drops below 0.0' do
      60.times { stream.decay_freshness! }
      expect(stream.freshness).to eq(0.0)
    end
  end

  describe '#stale?' do
    it 'returns false when freshness is high' do
      expect(stream.stale?).to be false
    end

    it 'returns true when freshness drops below 0.1' do
      46.times { stream.decay_freshness! }
      expect(stream.stale?).to be true
    end
  end

  describe '#effective_weight' do
    it 'equals weight * freshness * confidence' do
      expected = (0.8 * 1.0 * 0.9).round(10)
      expect(stream.effective_weight).to eq(expected)
    end

    it 'decreases after decay' do
      before = stream.effective_weight
      stream.decay_freshness!
      expect(stream.effective_weight).to be < before
    end
  end

  describe '#coherence_label' do
    it 'returns :unified for weight 0.9' do
      s = described_class.new(stream_type: :memorial, content: {}, weight: 0.9)
      expect(s.coherence_label).to eq(:unified)
    end

    it 'returns :chaotic for weight 0.1' do
      s = described_class.new(stream_type: :memorial, content: {}, weight: 0.1)
      expect(s.coherence_label).to eq(:chaotic)
    end
  end

  describe '#confidence_label' do
    it 'returns :certain for confidence 0.95' do
      s = described_class.new(stream_type: :memorial, content: {}, confidence: 0.95)
      expect(s.confidence_label).to eq(:certain)
    end

    it 'returns :guessing for confidence 0.1' do
      s = described_class.new(stream_type: :memorial, content: {}, confidence: 0.1)
      expect(s.confidence_label).to eq(:guessing)
    end
  end

  describe '#to_h' do
    let(:hash) { stream.to_h }

    it 'includes all expected keys' do
      %i[id stream_type content weight confidence freshness effective_weight
         stale coherence_label confidence_label created_at].each do |key|
        expect(hash).to have_key(key)
      end
    end

    it 'reflects current freshness' do
      stream.decay_freshness!
      expect(stream.to_h[:freshness]).to be < 1.0
    end
  end
end
