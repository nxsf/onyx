# A full numerical index of a target block is unknown at this moment
# (`parent.numeral` is `nil` and its parent's too and so on) if it
# is in the current file. The builder does not know exact structure
# of the file yet. It is possible by iterating through already parsed
# sections manually, though.

class XCiteMacro < Asciidoctor::Extensions::BlockMacroProcessor
  use_dsl

  named :xcite

  def process(parent, target, attrs)
    found = parent.document.catalog[:refs][target]

    raise "Could not find node by ID ##{target}" unless found

    unless found.context == :paragraph || found.context == :dlist
      raise "Can only cite paragraphs or terms (got #{found.context})"
    end

    # The block number processor runs AFTER the macro,
    # so we have to do the numbering chores here.
    index = 0
    raise unless found.parent.blocks.each do |block|
      if block.id != target
        if block.context == :paragraph || block.context == :dlist
          index += 1
        end

        next
      else
        found.numeral = (index + 1).to_s
        break true
      end
    end


    # We don't want duplicate IDs
    dup = found.dup
    dup.id = nil

    render = dup.render
    if render.is_a?(Array)
      render = render.join
    end

    html = <<-HTML
    <div class="quoteblock cite" data-cite-id="#{target}">
      <blockquote>
        #{render}
      </blockquote>
    </div>
    HTML

    # Can not create a paragraph block, because it'd have index built
    # from the context the macro is in, instead of the true context
    # of the cited block.
    create_pass_block(parent, html, attrs, subs: nil)
  end
end
