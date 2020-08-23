require "asciidoctor"
require "asciidoctor-diagram/blockdiag"
require "asciidoctor-diagram/bytefield"

require "./lib/syntax_block_processor"

Asciidoctor::Extensions.register do
  block SyntaxBlock, :syntax
  block_macro SyntaxSummaryMacro if document.basebackend? 'html'
end

Asciidoctor.convert_file './spec/_index.adoc',
  to_file: './build/index.html',
  sourcemap: true,
  mkdirs: 'build',
  safe: 'unsafe',
  backend: 'html'
