# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_synthesis/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-synthesis'
  spec.version       = Legion::Extensions::CognitiveSynthesis::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Synthesis'
  spec.description   = 'Cognitive binding engine — combines disparate cognitive streams ' \
                       '(emotional, perceptual, memorial, predictive) into unified coherent ' \
                       'representations for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-synthesis'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']      = spec.homepage
  spec.metadata['source_code_uri']   = 'https://github.com/LegionIO/lex-cognitive-synthesis'
  spec.metadata['documentation_uri'] = 'https://github.com/LegionIO/lex-cognitive-synthesis'
  spec.metadata['changelog_uri']     = 'https://github.com/LegionIO/lex-cognitive-synthesis'
  spec.metadata['bug_tracker_uri']   = 'https://github.com/LegionIO/lex-cognitive-synthesis/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-synthesis.gemspec Gemfile]
  end
  spec.require_paths = ['lib']
end
