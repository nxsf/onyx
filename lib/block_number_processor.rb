# Can not put it into `BlockNumberProcessor`,
# because it's... frozen. Why?
$block_index = 0

class BlockNumberProcessor < Asciidoctor::Extensions::TreeProcessor
  def process(document)
    return unless document.blocks?
    process_blocks(document)
    nil
  end

  def process_blocks(node)
    # previous_level = -1

    node.blocks.each_with_index do |block, i|
      if block.is_a?(Array)
        next
      end

      if block.context == :section
        # previous_level = block.level
        $block_index = 0
      end

      if (block.context == :paragraph) &&
        !block.attributes["noindex-option"]

        block.numeral = ($block_index + 1).to_s
        block.attributes["block_index"] = $block_index + 1
        $block_index += 1
      elsif block.context
        process_blocks(block) if block.blocks?
      end
    end
  end
end
