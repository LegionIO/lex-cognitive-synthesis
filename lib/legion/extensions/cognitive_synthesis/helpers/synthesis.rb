# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveSynthesis
      module Helpers
        class Synthesis
          include Constants

          attr_reader :id, :streams, :coherence, :novelty, :confidence, :content, :created_at

          def initialize(streams:, coherence:, novelty:, confidence:, content:)
            @id         = SecureRandom.uuid
            @streams    = streams
            @coherence  = coherence.clamp(0.0, 1.0)
            @novelty    = novelty.clamp(0.0, 1.0)
            @confidence = confidence.clamp(0.0, 1.0)
            @content    = content
            @created_at = Time.now.utc
          end

          def fragmented?
            @coherence < COHERENCE_THRESHOLD
          end

          def novel?
            @novelty > NOVELTY_THRESHOLD
          end

          def coherence_label
            COHERENCE_LABELS.find { |range, _| range.cover?(@coherence) }&.last || :chaotic
          end

          def confidence_label
            CONFIDENCE_LABELS.find { |range, _| range.cover?(@confidence) }&.last || :guessing
          end

          def to_h
            {
              id:               @id,
              streams:          @streams,
              coherence:        @coherence,
              novelty:          @novelty,
              confidence:       @confidence,
              content:          @content,
              fragmented:       fragmented?,
              novel:            novel?,
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
