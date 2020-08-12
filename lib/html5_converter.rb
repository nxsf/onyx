def render_block_numeral(node, trailing_dot = false)
  return unless node.numeral

  render = ""
  block_num_sign = if node.context == :section
    "." # The dot separator is built-in
  else
    node.document.attributes["blocknumsign"] || ":"
  end

  parent = node.parent
  while parent
    if parent.numeral
      if render.empty?
        render = parent.numeral.to_s
      else
        render = parent.numeral + "." + render
      end
    end

    parent = parent.parent
  end

  render += "#{block_num_sign}#{node.numeral}#{'.' if trailing_dot}"
  return render
end

class HTML5Converter < (Asciidoctor::Converter.for 'html5')
  register_for 'html5'

  def convert_paragraph(node)
    if node.role
      attributes = %(#{node.id ? %[ id="#{node.id}"] : ''} class="paragraph #{node.role}")
    elsif node.id
      attributes = %( id="#{node.id}" class="paragraph")
    else
      attributes = ' class="paragraph"'
    end

    attributes += %( data-sourcemap-path="#{node.source_location.path}")
    attributes += %( data-sourcemap-lineno="#{node.source_location.lineno}")

    content = if block_num = render_block_numeral(node)
      id = if node.parent.id
        node.parent.id + ":" + node.numeral
      else
        ":" + node.numeral
      end

      <<-HTML.chomp
      <a href="##{id}" id=#{id} class="block-num">#{block_num}</a> #{node.content}
      HTML
    else
      node.content
    end

    if node.title?
      <<-HTML.chomp
      <div #{attributes}>
        <div class="title">#{node.title}</div>
        <p>#{content}</p>
      </div>
      HTML
    else
      <<-HTML.chomp
      <div #{attributes}>
        <p>#{content}</p>
      </div>
      HTML
    end
  end

  def convert_listing(node)
    nowrap = (node.option? 'nowrap') || !(node.document.attr? 'prewrap')

    if node.style == 'source'
      lang = node.attr 'language'
      if (syntax_hl = node.document.syntax_highlighter)
        opts = syntax_hl.highlight? ? {
          css_mode: ((doc_attrs = node.document.attributes)[%(#{syntax_hl.name}-css)] || :class).to_sym,
          style: doc_attrs[%(#{syntax_hl.name}-style)],
        } : {}
        opts[:nowrap] = nowrap
      else
        pre_open = %(<pre class="highlight#{nowrap ? ' nowrap' : ''}"><code#{lang ? %[ class="language-#{lang}" data-lang="#{lang}"] : ''}>)
        pre_close = '</code></pre>'
      end
    else
      pre_open = %(<pre#{nowrap ? ' class="nowrap"' : ''}>)
      pre_close = '</pre>'
    end

    id_attribute = node.id ? %( id="#{node.id}") : ''

    title_element = if node.title?
      <<-HTML.chomp
      <div class="title">
        <a
          href="#_listing-#{node.number}"
          id="_listing-#{node.number}"
          class="listing-caption-link"
        >#{node.captioned_title}</a>
      </div>
      HTML
    end

    <<-HTML.chomp
    <div #{id_attribute} class="listingblock#{(role = node.role) ? " #{role}" : ''}">
      #{title_element}
      <div class="content">
        #{syntax_hl ? (syntax_hl.format node, lang, opts) : pre_open + (node.content || '') + pre_close}
      </div>
    </div>
    HTML
  end

  def convert_example(node)
    id_attribute = node.id ? %( id="#{node.id}") : ''

    if node.option?('collapsible')
      class_attribute = node.role ? %( class="#{node.role}") : ''
      summary_element = node.title? ? %(<summary class="title">#{node.title}</summary>) : '<summary class="title">Details</summary>'

      <<-HTML.chomp
      <details #{id_attribute}#{class_attribute}#{(node.option? 'open') ? ' open' : ''}>
        #{summary_element}
        <div class="content">
          #{node.content}
        </div>
      </details>
      HTML
    else
      title_element = if node.title?
        <<-HTML
        <div class="title"><a href="#_example-#{node.number}" id="_example-#{node.number}" class="example-title-link">#{node.captioned_title}</a></div>
        HTML
      end

      <<-HTML.chomp
      <div #{id_attribute} class="exampleblock#{(role = node.role) ? " #{role}" : ''}">
        #{title_element}
        <div class="content">
          #{node.content}
        </div>
      </div>
      HTML
    end
  end

  def convert_table(node)
    result = []
    id_attribute = node.id ? %( id="#{node.id}") : ''
    classes = ['tableblock', %(frame-#{node.attr 'frame', 'all', 'table-frame'}), %(grid-#{node.attr 'grid', 'all', 'table-grid'})]

    if (stripes = node.attr 'stripes', nil, 'table-stripes')
      classes << %(stripes-#{stripes})
    end

    styles = []

    if (autowidth = node.option? 'autowidth') && !(node.attr? 'width')
      classes << 'fit-content'
    elsif (tablewidth = node.attr 'tablepcwidth') == 100
      classes << 'stretch'
    else
      styles << %(width: #{tablewidth}%;)
    end

    classes << (node.attr 'float') if node.attr? 'float'

    if (role = node.role)
      classes << role
    end

    class_attribute = %( class="#{classes.join ' '}")
    style_attribute = styles.empty? ? '' : %( style="#{styles.join ' '}")

    result << %(<table#{id_attribute}#{class_attribute}#{style_attribute}>)

    if node.title?
      result << <<-HTML.chomp
      <caption class="title"><a href="#_table-#{node.number}" id="_table-#{node.number}" class="table-caption-link">#{node.captioned_title}</caption>
      HTML
    end


    if (node.attr 'rowcount') > 0
      slash = @void_element_slash
      result << '<colgroup>'

      if autowidth
        result += (Array.new node.columns.size, %(<col#{slash}>))
      else
        node.columns.each do |col|
          result << ((col.option? 'autowidth') ? %(<col#{slash}>) : %(<col style="width: #{col.attr 'colpcwidth'}%;"#{slash}>))
        end
      end

      result << '</colgroup>'
      node.rows.to_h.each do |tsec, rows|
        next if rows.empty?
        result << %(<t#{tsec}>)
        rows.each do |row|
          result << '<tr>'
          row.each do |cell|
            if tsec == :head
              cell_content = cell.text
            else
              case cell.style
              when :asciidoc
                cell_content = %(<div class="content">#{cell.content}</div>)
              when :literal
                cell_content = %(<div class="literal"><pre>#{cell.text}</pre></div>)
              else
                cell_content = unless (
                  cell_content = cell.content
                ).empty?
                  <<-HTML
                  <p class="tableblock">#{cell_content.join '</p><p class="tableblock">'}</p>
                  HTML
                end
              end
            end

            cell_tag_name = (tsec == :head || cell.style == :header ? 'th' : 'td')
            cell_class_attribute = %( class="tableblock halign-#{cell.attr 'halign'} valign-#{cell.attr 'valign'}")
            cell_colspan_attribute = cell.colspan ? %( colspan="#{cell.colspan}") : ''
            cell_rowspan_attribute = cell.rowspan ? %( rowspan="#{cell.rowspan}") : ''
            cell_style_attribute = (node.document.attr? 'cellbgcolor') ? %( style="background-color: #{node.document.attr 'cellbgcolor'};") : ''
            result << %(<#{cell_tag_name}#{cell_class_attribute}#{cell_colspan_attribute}#{cell_rowspan_attribute}#{cell_style_attribute}>#{cell_content}</#{cell_tag_name}>)
          end
          result << '</tr>'
        end
        result << %(</t#{tsec}>)
      end
    end

    result << '</table>'
    result.join Asciidoctor::LF
  end

  def convert_inline_anchor(node)
    case node.type
    when :xref
      if (path = node.attributes['path'])
        attrs = (append_link_constraint_attrs node, node.role ? [%( class="#{node.role}")] : []).join
        text = node.text || path
      else
        attrs = node.role ? %( class="#{node.role}") : ''
        refid = node.attributes['refid']
        ref = (@refs ||= node.document.catalog[:refs])[refid]

        unless (text = node.text)
          if Asciidoctor::AbstractNode === ref
            text = (ref.xreftext(node.attr('xrefstyle', nil, true))) || %([#{refid}])
          else
            text = %([#{refid}])
          end
        end

        if ref && (ref.context == :paragraph ||
          (ref.context == :section && node.text))
          block_num = render_block_numeral(ref, false)

          if block_num
            text += %Q[<sup class="xref-block-num">#{block_num}</sup>]
          end
        end
      end

      %(<a href="#{node.target}"#{attrs}>#{text}</a>)
    when :ref
      %(<a id="#{node.id}"></a>)
    when :link
      attrs = node.id ? [%( id="#{node.id}")] : []
      attrs << %( class="#{node.role}") if node.role
      attrs << %( class="external") if node.target =~ /^https?:\/\//
      attrs << %( title="#{node.attr 'title'}") if node.attr? 'title'
      %(<a href="#{node.target}"#{(append_link_constraint_attrs(node, attrs)).join}>#{node.text}</a>)
    when :bibref
      %(<a id="#{node.id}"></a>[#{node.reftext || node.id}])
    else
      logger.warn %(unknown anchor type: #{node.type.inspect})
      nil
    end
  end

  def convert_dlist(node)
    result = []
    id_attribute = node.id ? %( id="#{node.id}") : ''

    classes = case node.style
    when 'qanda'
      ['qlist', 'qanda', node.role]
    when 'horizontal'
      ['hdlist', node.role]
    else
      ['dlist', node.style, node.role]
    end.compact

    class_attribute = %( class="#{classes.join ' '}")

    result << %(<div#{id_attribute}#{class_attribute}>)
    result << %(<div class="title">#{node.title}</div>) if node.title?
    case node.style
    when 'qanda'
      result << '<ol>'
      node.items.each do |terms, dd|
        result << '<li>'
        terms.each do |dt|
          result << %(<p><em>#{dt.text}</em></p>)
        end
        if dd
          result << %(<p>#{dd.text}</p>) if dd.text?
          result << dd.content if dd.blocks?
        end
        result << '</li>'
      end
      result << '</ol>'
    when 'horizontal'
      slash = @void_element_slash
      result << '<table>'
      if (node.attr? 'labelwidth') || (node.attr? 'itemwidth')
        result << '<colgroup>'
        col_style_attribute = (node.attr? 'labelwidth') ? %( style="width: #{(node.attr 'labelwidth').chomp '%'}%;") : ''
        result << %(<col#{col_style_attribute}#{slash}>)
        col_style_attribute = (node.attr? 'itemwidth') ? %( style="width: #{(node.attr 'itemwidth').chomp '%'}%;") : ''
        result << %(<col#{col_style_attribute}#{slash}>)
        result << '</colgroup>'
      end
      node.items.each do |terms, dd|
        result << '<tr>'
        result << %(<td class="hdlist1#{(node.option? 'strong') ? ' strong' : ''}">)
        first_term = true
        terms.each do |dt|
          result << %(<br#{slash}>) unless first_term
          result << dt.text
          first_term = nil
        end
        result << '</td>'
        result << '<td class="hdlist2">'
        if dd
          result << %(<p>#{dd.text}</p>) if dd.text?
          result << dd.content if dd.blocks?
        end
        result << '</td>'
        result << '</tr>'
      end
      result << '</table>'
    else
      result << '<dl>'
      dt_style_attribute = node.style ? '' : ' class="hdlist1"'
      node.items.each do |terms, dd|
        terms.each do |dt|
          text = if block_num = render_block_numeral(dt.parent)
            block_num + " " + dt.text
          else
            dt.text
          end

          result << %(<dt#{dt_style_attribute}>#{text}</dt>)
        end

        if dd
          result << '<dd>'
          result << %(<p>#{dd.text}</p>) if dd.text?
          result << dd.content if dd.blocks?
          result << '</dd>'
        end
      end
      result << '</dl>'
    end

    result << '</div>'
    # result.join LF
  end
end
