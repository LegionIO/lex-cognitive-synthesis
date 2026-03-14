# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveSynthesis
      module Helpers
        class SynthesisEngine
          include Constants

          attr_reader :streams, :syntheses

          def initialize
            @streams    = {}
            @syntheses  = []
          end

          def add_stream(stream_type:, content:, weight: DEFAULT_WEIGHT, confidence: DEFAULT_WEIGHT, **)
            return { success: false, error: :invalid_stream_type, valid_types: STREAM_TYPES } unless STREAM_TYPES.include?(stream_type)

            stream = SynthesisStream.new(
              stream_type: stream_type,
              content:     content,
              weight:      weight,
              confidence:  confidence
            )

            @streams[stream.id] = stream
            prune_streams! if @streams.size > MAX_STREAMS

            Legion::Logging.debug "[cognitive_synthesis] stream added id=#{stream.id[0..7]} " \
                                  "type=#{stream_type} weight=#{weight.round(2)}"

            { success: true, stream_id: stream.id, stream_type: stream_type }
          end

          def remove_stream(stream_id:, **)
            removed = @streams.delete(stream_id)
            if removed
              Legion::Logging.debug "[cognitive_synthesis] stream removed id=#{stream_id[0..7]}"
              { success: true, stream_id: stream_id }
            else
              { success: false, error: :not_found }
            end
          end

          def synthesize!(**)
            active = @streams.values.reject(&:stale?)

            if active.size < MIN_STREAMS_FOR_SYNTHESIS
              Legion::Logging.debug "[cognitive_synthesis] synthesize! skipped: only #{active.size} active streams"
              return { success: false, error: :insufficient_streams, active_count: active.size, required: MIN_STREAMS_FOR_SYNTHESIS }
            end

            coherence   = compute_coherence(active)
            novelty     = compute_novelty(active)
            confidence  = compute_weighted_confidence(active)
            content     = merge_content(active)

            synthesis = Synthesis.new(
              streams:    active.map(&:id),
              coherence:  coherence,
              novelty:    novelty,
              confidence: confidence,
              content:    content
            )

            @syntheses << synthesis
            @syntheses.shift while @syntheses.size > MAX_SYNTHESES

            Legion::Logging.info "[cognitive_synthesis] synthesis id=#{synthesis.id[0..7]} " \
                                 "coherence=#{coherence.round(2)} novelty=#{novelty.round(2)} " \
                                 "streams=#{active.size} label=#{synthesis.coherence_label}"

            { success: true, synthesis: synthesis.to_h }
          end

          def decay_all!(**)
            before = @streams.size
            @streams.each_value(&:decay_freshness!)
            @streams.reject! { |_, s| s.stale? }
            removed = before - @streams.size

            Legion::Logging.debug "[cognitive_synthesis] decay_all! removed=#{removed} remaining=#{@streams.size}"
            { success: true, streams_removed: removed, streams_remaining: @streams.size }
          end

          def stream_conflict?(stream_id_a:, stream_id_b:, **)
            a = @streams[stream_id_a]
            b = @streams[stream_id_b]

            return { success: false, error: :stream_not_found } unless a && b

            weight_opposition = opposing_weights?(a, b)
            content_conflict  = conflicting_content?(a, b)
            conflict          = weight_opposition || content_conflict

            Legion::Logging.debug "[cognitive_synthesis] conflict check #{stream_id_a[0..7]}<>#{stream_id_b[0..7]} " \
                                  "result=#{conflict}"

            {
              success:           true,
              conflict:          conflict,
              weight_opposition: weight_opposition,
              content_conflict:  content_conflict
            }
          end

          def dominant_stream(**)
            return { success: false, error: :no_streams } if @streams.empty?

            stream = @streams.values.max_by(&:effective_weight)
            Legion::Logging.debug "[cognitive_synthesis] dominant stream id=#{stream.id[0..7]} " \
                                  "effective_weight=#{stream.effective_weight.round(4)}"
            { success: true, stream: stream.to_h }
          end

          def synthesis_history(limit: 10, **)
            recent = @syntheses.last(limit)
            { success: true, syntheses: recent.map(&:to_h), count: recent.size }
          end

          def average_coherence(window: 10, **)
            recent = @syntheses.last(window)
            return { success: true, average_coherence: 0.0, sample_size: 0 } if recent.empty?

            avg = recent.sum(&:coherence).round(10) / recent.size
            { success: true, average_coherence: avg.round(10), sample_size: recent.size }
          end

          def to_h
            {
              stream_count:      @streams.size,
              synthesis_count:   @syntheses.size,
              active_streams:    @streams.values.reject(&:stale?).size,
              stale_streams:     @streams.values.count(&:stale?),
              average_coherence: @syntheses.empty? ? 0.0 : (@syntheses.sum(&:coherence).round(10) / @syntheses.size).round(6)
            }
          end

          private

          def prune_streams!
            overflow = @streams.size - MAX_STREAMS
            return if overflow <= 0

            ids_to_prune = @streams.min_by(overflow) { |_, s| s.effective_weight }.map(&:first)
            ids_to_prune.each { |id| @streams.delete(id) }
          end

          def compute_coherence(active)
            return 1.0 if active.size == 1

            weights = active.map(&:effective_weight)
            mean    = weights.sum.round(10) / weights.size
            variance = weights.sum { |w| ((w - mean)**2).round(10) }.round(10) / weights.size
            std_dev  = Math.sqrt(variance)

            (1.0 - [std_dev, 1.0].min).round(10)
          end

          def compute_novelty(active)
            return 1.0 if @syntheses.empty?

            last_syn = @syntheses.last
            last_ids = Set.new(last_syn.streams)
            current_ids = Set.new(active.map(&:id))

            overlap = (last_ids & current_ids).size.to_f
            union   = (last_ids | current_ids).size.to_f

            return 1.0 if union.zero?

            jaccard_similarity = overlap / union
            (1.0 - jaccard_similarity).round(10)
          end

          def compute_weighted_confidence(active)
            total_weight = active.sum(&:effective_weight).round(10)
            return 0.0 if total_weight.zero?

            weighted_sum = active.sum { |s| (s.confidence * s.effective_weight).round(10) }.round(10)
            (weighted_sum / total_weight).round(10)
          end

          def merge_content(active)
            dominant = active.max_by(&:effective_weight)
            {
              dominant_type:    dominant.stream_type,
              dominant_weight:  dominant.effective_weight.round(6),
              stream_types:     active.map(&:stream_type).uniq,
              stream_count:     active.size,
              payload_snapshot: dominant.content
            }
          end

          def opposing_weights?(str_a, str_b)
            (str_a.weight - str_b.weight).abs > 0.5
          end

          def conflicting_content?(str_a, str_b)
            keys_a = str_a.content.is_a?(Hash) ? str_a.content.keys : []
            keys_b = str_b.content.is_a?(Hash) ? str_b.content.keys : []
            (keys_a & keys_b).any? { |k| str_a.content[k] != str_b.content[k] }
          end
        end
      end
    end
  end
end
