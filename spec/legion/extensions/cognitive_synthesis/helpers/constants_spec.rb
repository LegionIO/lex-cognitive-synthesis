# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveSynthesis::Helpers::Constants do
  subject(:mod) { described_class }

  describe 'MAX_STREAMS' do
    it 'is 50' do
      expect(mod::MAX_STREAMS).to eq(50)
    end
  end

  describe 'MAX_SYNTHESES' do
    it 'is 200' do
      expect(mod::MAX_SYNTHESES).to eq(200)
    end
  end

  describe 'DEFAULT_WEIGHT' do
    it 'is 0.5' do
      expect(mod::DEFAULT_WEIGHT).to eq(0.5)
    end
  end

  describe 'COHERENCE_THRESHOLD' do
    it 'is 0.6' do
      expect(mod::COHERENCE_THRESHOLD).to eq(0.6)
    end
  end

  describe 'NOVELTY_THRESHOLD' do
    it 'is 0.7' do
      expect(mod::NOVELTY_THRESHOLD).to eq(0.7)
    end
  end

  describe 'FRESHNESS_DECAY' do
    it 'is 0.02' do
      expect(mod::FRESHNESS_DECAY).to eq(0.02)
    end
  end

  describe 'MIN_STREAMS_FOR_SYNTHESIS' do
    it 'is 2' do
      expect(mod::MIN_STREAMS_FOR_SYNTHESIS).to eq(2)
    end
  end

  describe 'STREAM_TYPES' do
    it 'includes all expected types' do
      expect(mod::STREAM_TYPES).to include(:emotional, :perceptual, :memorial, :predictive,
                                           :reasoning, :social, :identity, :motor)
    end

    it 'is frozen' do
      expect(mod::STREAM_TYPES).to be_frozen
    end
  end

  describe 'COHERENCE_LABELS' do
    it 'maps high values to :unified' do
      label = mod::COHERENCE_LABELS.find { |range, _| range.cover?(0.9) }&.last
      expect(label).to eq(:unified)
    end

    it 'maps low values to :chaotic' do
      label = mod::COHERENCE_LABELS.find { |range, _| range.cover?(0.1) }&.last
      expect(label).to eq(:chaotic)
    end

    it 'maps mid values to :coherent' do
      label = mod::COHERENCE_LABELS.find { |range, _| range.cover?(0.7) }&.last
      expect(label).to eq(:coherent)
    end
  end

  describe 'CONFIDENCE_LABELS' do
    it 'maps high values to :certain' do
      label = mod::CONFIDENCE_LABELS.find { |range, _| range.cover?(0.95) }&.last
      expect(label).to eq(:certain)
    end

    it 'maps low values to :guessing' do
      label = mod::CONFIDENCE_LABELS.find { |range, _| range.cover?(0.05) }&.last
      expect(label).to eq(:guessing)
    end
  end
end
