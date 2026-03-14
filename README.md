# lex-cognitive-synthesis

A LegionIO cognitive architecture extension that models the integration of multiple cognitive streams into a unified percept. Streams from different processing channels are combined into a synthesis result with measured coherence, novelty, and confidence.

## What It Does

Manages a set of **streams** (active cognitive inputs) across eight types:

`emotional`, `perceptual`, `memorial`, `predictive`, `reasoning`, `social`, `identity`, `motor`

Each stream has a weight, confidence, and freshness that decays over time. When `synthesize` is called, the engine integrates all non-stale streams and produces a `Synthesis` result with:

- **Coherence**: how aligned the streams are (low std-dev of effective weights = high coherence)
- **Novelty**: how different these inputs are from the previous synthesis (Jaccard distance on stream IDs)
- **Confidence**: weighted mean of stream confidences

## Usage

```ruby
require 'lex-cognitive-synthesis'

client = Legion::Extensions::CognitiveSynthesis::Client.new

# Add streams from different cognitive channels
a = client.add_stream(stream_type: :emotional, content: { valence: 0.7, arousal: 0.6 }, weight: 0.8, confidence: 0.9)
# => { success: true, stream_id: "uuid...", stream_type: :emotional }

b = client.add_stream(stream_type: :memorial, content: { key: 'summer', strength: 0.5 }, weight: 0.6, confidence: 0.7)
# => { success: true, stream_id: "uuid...", stream_type: :memorial }

client.add_stream(stream_type: :predictive, content: { outcome: :positive, probability: 0.8 }, weight: 0.7)

# Synthesize all active streams
result = client.synthesize
# => { success: true, synthesis: { coherence: 0.87, novelty: 1.0, confidence: 0.78, coherence_label: :unified, ... } }

# Check if two streams conflict
client.check_conflict(stream_id_a: a[:stream_id], stream_id_b: b[:stream_id])
# => { success: true, conflict: false, weight_opposition: false, content_conflict: false }

# Which stream is currently dominant?
client.dominant_stream
# => { success: true, stream: { stream_type: :emotional, effective_weight: 0.72, ... } }

# Decay all streams (remove stale ones)
client.decay_streams
# => { success: true, streams_removed: 0, streams_remaining: 3 }

# Synthesis history
client.synthesis_history(limit: 5)
# => { success: true, syntheses: [...], count: 1 }

# Average coherence over recent syntheses
client.average_coherence(window: 10)
# => { success: true, average_coherence: 0.87, sample_size: 1 }

# Current status
client.status
# => { success: true, stream_count: 3, synthesis_count: 1, active_streams: 3, stale_streams: 0, average_coherence: 0.87 }
```

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
