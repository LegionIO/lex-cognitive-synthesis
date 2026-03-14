# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveSynthesis
      module Runners
        module CognitiveSynthesis
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def add_stream(stream_type:, content:, weight: Helpers::Constants::DEFAULT_WEIGHT,
                         confidence: Helpers::Constants::DEFAULT_WEIGHT, engine: nil, **)
            target = engine || synthesis_engine
            result = target.add_stream(stream_type: stream_type, content: content,
                                       weight: weight, confidence: confidence)
            Legion::Logging.debug "[cognitive_synthesis] runner add_stream type=#{stream_type}"
            result
          end

          def remove_stream(stream_id:, engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug "[cognitive_synthesis] runner remove_stream id=#{stream_id[0..7]}"
            target.remove_stream(stream_id: stream_id)
          end

          def synthesize(engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug '[cognitive_synthesis] runner synthesize'
            target.synthesize!
          end

          def decay_streams(engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug '[cognitive_synthesis] runner decay_streams'
            target.decay_all!
          end

          def check_conflict(stream_id_a:, stream_id_b:, engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug "[cognitive_synthesis] runner check_conflict #{stream_id_a[0..7]}<>#{stream_id_b[0..7]}"
            target.stream_conflict?(stream_id_a: stream_id_a, stream_id_b: stream_id_b)
          end

          def dominant_stream(engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug '[cognitive_synthesis] runner dominant_stream'
            target.dominant_stream
          end

          def synthesis_history(limit: 10, engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug "[cognitive_synthesis] runner synthesis_history limit=#{limit}"
            target.synthesis_history(limit: limit)
          end

          def average_coherence(window: 10, engine: nil, **)
            target = engine || synthesis_engine
            Legion::Logging.debug "[cognitive_synthesis] runner average_coherence window=#{window}"
            target.average_coherence(window: window)
          end

          def status(engine: nil, **)
            target = engine || synthesis_engine
            stats  = target.to_h
            Legion::Logging.debug "[cognitive_synthesis] runner status streams=#{stats[:stream_count]}"
            { success: true }.merge(stats)
          end

          private

          def synthesis_engine
            @synthesis_engine ||= Helpers::SynthesisEngine.new
          end
        end
      end
    end
  end
end
