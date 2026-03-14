# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveSynthesis
      module Helpers
        module Constants
          MAX_STREAMS             = 50
          MAX_SYNTHESES           = 200
          DEFAULT_WEIGHT          = 0.5
          COHERENCE_THRESHOLD     = 0.6
          NOVELTY_THRESHOLD       = 0.7
          FRESHNESS_DECAY         = 0.02
          MIN_STREAMS_FOR_SYNTHESIS = 2

          STREAM_TYPES = %i[emotional perceptual memorial predictive reasoning social identity motor].freeze

          COHERENCE_LABELS = {
            (0.8..)     => :unified,
            (0.6...0.8) => :coherent,
            (0.4...0.6) => :fragmented,
            (0.2...0.4) => :dissonant,
            (..0.2)     => :chaotic
          }.freeze

          CONFIDENCE_LABELS = {
            (0.8..)     => :certain,
            (0.6...0.8) => :confident,
            (0.4...0.6) => :uncertain,
            (0.2...0.4) => :doubtful,
            (..0.2)     => :guessing
          }.freeze
        end
      end
    end
  end
end
