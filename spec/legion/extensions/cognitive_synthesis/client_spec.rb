# frozen_string_literal: true

require 'legion/extensions/cognitive_synthesis/client'

RSpec.describe Legion::Extensions::CognitiveSynthesis::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    %i[add_stream remove_stream synthesize decay_streams check_conflict
       dominant_stream synthesis_history average_coherence status].each do |method|
      expect(client).to respond_to(method)
    end
  end

  it 'accepts an injected engine' do
    engine = Legion::Extensions::CognitiveSynthesis::Helpers::SynthesisEngine.new
    client = described_class.new(engine: engine)
    client.add_stream(stream_type: :emotional, content: {})
    expect(engine.streams.size).to eq(1)
  end

  it 'creates its own engine when none injected' do
    client = described_class.new
    result = client.add_stream(stream_type: :emotional, content: {})
    expect(result[:success]).to be true
  end
end
