# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveSynthesis
      module Helpers
        class SynthesisStream
          include Constants

          attr_reader :id, :stream_type, :content, :weight, :confidence, :freshness, :created_at

          def initialize(stream_type:, content:, weight: DEFAULT_WEIGHT, confidence: DEFAULT_WEIGHT)
            @id          = SecureRandom.uuid
            @stream_type = stream_type
            @content     = content
            @weight      = weight.clamp(0.0, 1.0)
            @confidence  = confidence.clamp(0.0, 1.0)
            @freshness   = 1.0
            @created_at  = Time.now.utc
          end

          def decay_freshness!
            @freshness = (@freshness - FRESHNESS_DECAY).clamp(0.0, 1.0)
          end

          def stale?
            @freshness < 0.1
          end

          def effective_weight
            (@weight * @freshness * @confidence).round(10)
          end

          def coherence_label
            COHERENCE_LABELS.find { |range, _| range.cover?(@weight) }&.last || :chaotic
          end

          def confidence_label
            CONFIDENCE_LABELS.find { |range, _| range.cover?(@confidence) }&.last || :guessing
          end

          def to_h
            {
              id:               @id,
              stream_type:      @stream_type,
              content:          @content,
              weight:           @weight,
              confidence:       @confidence,
              freshness:        @freshness,
              effective_weight: effective_weight,
              stale:            stale?,
              coherence_label:  coherence_label,
              confidence_label: confidence_label,
              created_at:       @created_at
            }
          end
        end
      end
    end
  end
end
