require "asciidoctor"
require "asciidoctor-diagram/blockdiag"
require "asciidoctor-diagram/bytefield"
require "asciidoctor-pdf"

require "./lib/syntax_block_processor"

Asciidoctor::Extensions.register do
  block SyntaxBlock, :syntax
  block_macro SyntaxSummaryMacro if document.basebackend? 'html'
end

Asciidoctor.convert_file './spec/_index.adoc',
  to_file: './build/index.pdf',
  sourcemap: true,
  mkdirs: 'build',
  safe: 'unsafe',
  backend: 'pdf'
