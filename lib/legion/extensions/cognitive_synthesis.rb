# frozen_string_literal: true

require 'legion/extensions/cognitive_synthesis/version'
require 'legion/extensions/cognitive_synthesis/helpers/constants'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis_stream'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis'
require 'legion/extensions/cognitive_synthesis/helpers/synthesis_engine'
require 'legion/extensions/cognitive_synthesis/runners/cognitive_synthesis'

module Legion
  module Extensions
    module CognitiveSynthesis
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
