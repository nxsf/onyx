require "asciidoctor"
require "asciidoctor-diagram/blockdiag"
require "asciidoctor-diagram/bytefield"
require "pry"
require "asciidoctor-pdf"

# require "./lib/html5_converter"
require "./lib/block_number_processor"
require "./lib/xcite_macro"
require "./lib/syntax_block_processor"

Asciidoctor::Extensions.register do
  block SyntaxBlock, :syntax
  block_macro SyntaxSummaryMacro if document.basebackend? 'html'
  # treeprocessor BlockNumberProcessor
  # block_macro XCiteMacro if document.basebackend? 'html'
end

# Asciidoctor.convert_file 'test.adoc',

Asciidoctor.convert_file './spec/_index.adoc',
  to_file: './spec/index.html',
  sourcemap: true,
  safe: 'safe',
  backend: 'html'

# Asciidoctor.convert_file './spec/types/fixed.adoc',
#   to_file: './spec/types/fixed.html',
#   sourcemap: true,
#   safe: 'unsafe'
