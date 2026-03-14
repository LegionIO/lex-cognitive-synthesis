# lex-cognitive-synthesis

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-cognitive-synthesis`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::CognitiveSynthesis`

## Purpose

Models cognitive synthesis — the integration of multiple concurrent cognitive streams into a unified percept. Each stream has a type (emotional, perceptual, memorial, etc.), weight, confidence, and freshness. When `synthesize!` is called, the engine combines active streams into a `Synthesis` result with three metrics: coherence (agreement between streams), novelty (how different these inputs are from the last synthesis), and confidence (weighted mean of stream confidences). This models how the mind fuses heterogeneous cognitive signals into a single coherent experience.

## Gem Info

- **Gemspec**: `lex-cognitive-synthesis.gemspec`
- **Require**: `lex-cognitive-synthesis`
- **Ruby**: >= 3.4
- **License**: MIT
- **Homepage**: https://github.com/LegionIO/lex-cognitive-synthesis

## File Structure

```
lib/legion/extensions/cognitive_synthesis/
  version.rb
  helpers/
    constants.rb          # Stream types, coherence/confidence label tables, thresholds
    synthesis_stream.rb   # SynthesisStream class — one cognitive input channel
    synthesis.rb          # Synthesis class — one completed integration result
    synthesis_engine.rb   # SynthesisEngine — manages streams and produces syntheses
  runners/
    cognitive_synthesis.rb  # Runner module — public API
  client.rb
```

## Key Constants

| Constant | Value | Meaning |
|---|---|---|
| `MAX_STREAMS` | 50 | Hard cap; lowest effective-weight streams pruned when exceeded |
| `MAX_SYNTHESES` | 200 | Synthesis history ring size |
| `DEFAULT_WEIGHT` | 0.5 | Default weight and confidence for new streams |
| `COHERENCE_THRESHOLD` | 0.6 | Below this = `:fragmented` synthesis |
| `NOVELTY_THRESHOLD` | 0.7 | Above this = `:novel` synthesis |
| `FRESHNESS_DECAY` | 0.02 | Freshness reduction per `decay_freshness!` call |
| `MIN_STREAMS_FOR_SYNTHESIS` | 2 | At least 2 active streams required to synthesize |

`STREAM_TYPES`: `[:emotional, :perceptual, :memorial, :predictive, :reasoning, :social, :identity, :motor]`

Coherence labels: `0.8+` = `:unified`, `0.6..0.8` = `:coherent`, `0.4..0.6` = `:fragmented`, `0.2..0.4` = `:dissonant`, `<0.2` = `:chaotic`

Confidence labels: `0.8+` = `:certain`, `0.6..0.8` = `:confident`, `0.4..0.6` = `:uncertain`, `0.2..0.4` = `:doubtful`, `<0.2` = `:guessing`

## Key Classes

### `Helpers::SynthesisStream`

One cognitive input channel.

- `effective_weight` — `weight * freshness * confidence`; decays as freshness drops
- `decay_freshness!` — reduces freshness by `FRESHNESS_DECAY`
- `stale?` — freshness < 0.1
- `coherence_label` — label for stream's own weight value
- `confidence_label` — label for stream's confidence value
- Fields: `id` (UUID), `stream_type`, `content` (caller-defined), `weight`, `confidence`, `freshness` (starts at 1.0), `created_at`

### `Helpers::Synthesis`

One completed integration result.

- `fragmented?` — coherence < `COHERENCE_THRESHOLD`
- `novel?` — novelty > `NOVELTY_THRESHOLD`
- `coherence_label` / `confidence_label` — label lookups
- `content` — hash with `{ dominant_type:, dominant_weight:, stream_types:, stream_count:, payload_snapshot: }`
- `streams` — array of stream IDs that contributed (used for Jaccard novelty computation)

### `Helpers::SynthesisEngine`

Manages all streams and produces synthesis results.

- `add_stream(stream_type:, content:, weight:, confidence:)` — validates type; prunes lowest effective-weight if over `MAX_STREAMS`
- `remove_stream(stream_id:)` — deletes by ID; returns `{ success: false, error: :not_found }` if missing
- `synthesize!` — requires >= `MIN_STREAMS_FOR_SYNTHESIS` active (non-stale) streams; computes coherence, novelty, confidence, content; appends to history
- `decay_all!` — decays all streams; removes stale ones
- `stream_conflict?(stream_id_a:, stream_id_b:)` — checks weight opposition (diff > 0.5) and content key conflicts (same key, different value)
- `dominant_stream` — stream with highest `effective_weight`
- `synthesis_history(limit:)` — most recent syntheses
- `average_coherence(window:)` — mean coherence over last N syntheses

**Coherence computation**: `1 - min(std_dev(effective_weights), 1.0)` — low variance = high coherence.

**Novelty computation**: `1 - Jaccard(last_synthesis_streams, current_streams)` — measures structural input novelty vs. most recent synthesis.

**Confidence computation**: weighted mean of stream confidences by their effective weights.

## Runners

Module: `Legion::Extensions::CognitiveSynthesis::Runners::CognitiveSynthesis`

| Runner | Key Args | Returns |
|---|---|---|
| `add_stream` | `stream_type:`, `content:`, `weight:`, `confidence:` | `{ success:, stream_id:, stream_type: }` or error |
| `remove_stream` | `stream_id:` | `{ success:, stream_id: }` or not found |
| `synthesize` | — | `{ success:, synthesis: }` or `{ success: false, error: :insufficient_streams }` |
| `decay_streams` | — | `{ success:, streams_removed:, streams_remaining: }` |
| `check_conflict` | `stream_id_a:`, `stream_id_b:` | `{ success:, conflict:, weight_opposition:, content_conflict: }` |
| `dominant_stream` | — | `{ success:, stream: }` |
| `synthesis_history` | `limit:` | `{ success:, syntheses:, count: }` |
| `average_coherence` | `window:` | `{ success:, average_coherence:, sample_size: }` |
| `status` | — | `{ success:, stream_count:, synthesis_count:, active_streams:, stale_streams:, average_coherence: }` |

All runners accept optional `engine:` keyword for test injection.

## Integration Points

- No actors defined; `decay_streams` should be called periodically (e.g., `lex-tick` memory consolidation phase)
- Stream `content` is caller-defined; the engine stores and propagates it without parsing
- Conflict detection is useful for identifying opposing signals before synthesis — can feed into `lex-conflict`
- `synthesize` pairs naturally with `lex-tick`'s `working_memory_integration` phase for each cognitive cycle
- All state is in-memory per `SynthesisEngine` instance

## Development Notes

- Novelty compares against the last synthesis only (not history average); two sequential identical syntheses have novelty 0.0
- `stream_conflict?` content check requires both streams to have Hash content; non-Hash content returns false for content_conflict
- `effective_weight` = `weight * freshness * confidence`; a stream at full weight/confidence but 50% freshness has half influence
- Synthesis `content.payload_snapshot` is the raw content of the dominant stream, not a merge of all streams
- `prune_streams!` uses `min_by(overflow)` — removes exactly enough streams to reach `MAX_STREAMS`, choosing those with lowest effective weight
