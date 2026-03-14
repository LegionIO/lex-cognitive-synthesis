# frozen_string_literal: true

require 'legion/extensions/cognitive_synthesis/helpers/constants'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis_stream'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis_engine'
require 'legion/extensions/cognitive_synthesis/runners/cognitive_synthesis'

module Legion
  module Extensions
    module CognitiveSynthesis
      class Client
        include Runners::CognitiveSynthesis

        def initialize(engine: nil, **)
          @synthesis_engine = engine || Helpers::SynthesisEngine.new
        end

        private

        attr_reader :synthesis_engine
      end
    end
  end
end
