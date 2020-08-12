$syntaxes = []

class SyntaxBlock < Asciidoctor::Extensions::BlockProcessor
  enable_dsl
  on_context :listing

  def process(parent, reader, attrs)
    read = reader.readlines()
    $syntaxes << { parent: parent.title, content: read }

    listing = create_listing_block(parent, read, {
      'style' => 'source',
      'language' => 'ebnf',
      'title' => attrs["title"]
    })

    listing
  end
end

class SyntaxSummaryMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl
  named :syntax_summary

  def process(parent, target, attrs)
    content = $syntaxes.map do |hash|
      hash[:content].join("\n")
    end.join("\n\n")

    listing = create_listing_block(parent, content, {
      'style' => 'source',
      'language' => 'ebnf',
      'title' => attrs["title"]
    })

    listing
  end
end
