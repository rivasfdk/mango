# Based on Table with MultiCells script by Olivier Plathey 
# and the work of Bojan Mihelac in FPDF:Table <http://source.mihelac.org>
# Author: Wil Alvarez <wil.alejandro@gmail.com> - 2011-07-28
# Modified by: Eleazar Meza <meza.eleazar@gmail.com> - 2013-10-16

require 'pdf/fpdf'

module EasyReport

  class Report < FPDF
    DEFAULT_ALIGN = 'C'
    DEFAULT_LINE_HEIGHT = 5
    DEFAULT_BREAKLINE = 1
    DEFAULT_TEXT_MARGIN = 0
    DEFAULT_PAGE_MARGIN = 15
    DEFAULT_WIDTH = 0
    DEFAULT_STYLE = {
      'font_family' => 'Arial',
      'font_size' => 9,
      'font_weight' => '',
      'font_color' => [0, 0, 0],
      'bg_color' => nil,
      'border' => 0,
    }
    DEFAULT_HEADING_STYLE = {
      'font_family' => 'Arial',
      'font_size' => 9,
      'font_weight' => 'B',
      'font_color' => [0, 0, 0],
      'bg_color' => [220, 220, 220],
      'border' => 0,
    }
    DEFAULT_HEADING = {
      'align' => DEFAULT_ALIGN,
      'style' => DEFAULT_HEADING_STYLE
    }

    def initialize(data, template)
      @data = data
      load_config(template)
      super(@config['page']['orientation'], 'mm', @config['page']['size'])
      set_font(DEFAULT_STYLE)
      SetCreator('Mango v1.0')
      SetMargins(@page_margins, @page_margins, @page_margins)
      SetAutoPageBreak(true, @page_margins)
    end

  public
    def render
      AddPage()
      Body()
      Output()
    end

    def Header
      1.upto(@header.length) do |i|
        type = @header[i].keys()[0]
        if type == 'image'
          render_image(@header[i][type])
        elsif type == 'text'
          render_text(@header[i][type])
        elsif type == 'date'
          render_date(@header[i][type])
        elsif type == 'pagenum'
          render_pagenum(@header[i][type])
        elsif type == 'breakline'
          render_breakline
        end
      end
    end

    def Body
      1.upto(@body.length) do |i|
        type = @body[i].keys()[0]
        if type == 'image'
          render_image(@body[i][type])
        elsif type == 'text'
          render_text(@body[i][type])
        elsif type == 'table'
          render_table(@body[i][type])
        elsif type == 'breakline'
          render_breakline
        end
      end
    end

    def Footer
      SetY(-@page_margins)
      1.upto(@footer.length) do |i|
        type = @footer[i].keys()[0]
        if type == 'image'
          render_image(@footer[i][type])
        elsif type == 'text'
          render_text(@footer[i][type])
        end
      end
    end

  private

    def load_config(template)
      unless template.is_a? Hash
        filepath = "#{Rails.root.to_s}/config/reports/#{template}"
        config = YAML::load(File.open(filepath))
      else
        config = template
      end
      @config = config['report']['settings']
      @header = config['report']['header']
      @body = config['report']['body']
      @footer = config['report']['footer']
      @page_margins = @config['page']['margins'] || DEFAULT_PAGE_MARGIN
    end

    def render_text(element)
      style = get_style(element['style'])
      align = get_align(element['align'])
      width = get_width(element['width'])
      margin = get_margin(element['margin'])
      ln = get_breakline(element['breakline'])
      text = get_text(element)
      set_cell(text, style, align, width, margin, ln)
    end

    def render_image(element)
      path = get_text(element)
      w = element['width']
      h = element['height']
      x = element['x']
      y = element['y']
      Image(path, x, y, w, h)
    end

    def render_date(element)
      element['label'] = Time.now.strftime(element['pattern'])
      render_text(element)
    end

    def render_pagenum(element)
      element['label'] = element['pattern'].gsub('<PAGE>', "#{PageNo()}")
      render_text(element)
    end

    def render_table(element)
      config, show_head = get_table_cell_config(element)
      set_table_header(config, show_head)
      totals = set_table_body(element, config, show_head)
      set_table_totalization(element, config, totals, show_head)
    end

    def render_breakline
      h = DEFAULT_STYLE['font_size'].to_i / 2
      Ln(h)
    end

    def get_text(element)
      if element['field'].nil?
        unless element['label'].nil?
          return element['label']
        else
          return ''
        end
      else
        if @data.has_key?(element['field'])
          return @data[element['field']]
        else
          raise IndexError, "Undefined field '#{element['field']}' in report configuration"
        end
      end
    end

    def get_align(value)
      return DEFAULT_ALIGN if value.nil?
      return 'C' if value.downcase == 'center'
      return 'L' if value.downcase == 'left'
      return 'R' if value.downcase == 'right'
      return value
    end

    def get_breakline(value)
      return DEFAULT_BREAKLINE if value.nil?
      return value
    end

    def get_margin(value)
      return DEFAULT_TEXT_MARGIN if value.nil?
      return value
    end

    def get_width(value)
      return DEFAULT_WIDTH if value.nil?
      return value
    end

    def get_style(tag)
      base = DEFAULT_STYLE.clone()
      return base if tag.nil?

      base['font_family'] = tag['font_family'] || DEFAULT_STYLE['font_family']
      base['font_size'] = tag['font_size'] || DEFAULT_STYLE['font_size']
      base['font_weight'] = tag['font_weight'] || DEFAULT_STYLE['font_weight']
      base['font_color'] = tag['font_color'] || DEFAULT_STYLE['font_color']
      base['bg_color'] = tag['bg_color'] || DEFAULT_STYLE['bg_color']
      base['border'] = get_border(tag['border']) || DEFAULT_STYLE['border']

      return base
    end

    def get_border(value)
      return 0 if value.nil?
      return value
    end

    def get_image_path(filename)
      return "#{Rails.root.to_s}/app/assets/images/#{filename}"
    end

    def get_grouping(element)
      grouping = {
        'id' => [],
        'style' => [],
        'align' => []}
      return nil if element.nil?

      1.upto(element.length) do |i|
        grouping['id'] << element[i].keys[0]
        grouping['style'] << get_style(element[i][element[i].keys[0]]['style'])
        grouping['align'] << get_style(element[i][element[i].keys[0]]['align'])
      end
      grouping['current'] = nil
      return grouping
    end

    def get_totalization(element)
      totalization = nil
      unless element.nil?
        totalization = {
          'precision' => (element.has_key?('precision')) ? element['precision'] : 0,
          'label' => element['label'],
          'border' => get_border(element['border']),
          'align' => get_align(element['align']),
          'style' => get_style(element['style']),
        }
      end
      return totalization
    end

    def get_table_cell_config(element)
      columns = []
      default_width = 0
      current_width = 0
      no_width_columns = 0
      show_heading = false
      element['heading'] = DEFAULT_HEADING if element['heading'].nil?

      1.upto(element['columns'].length) do |i|
        key = element['columns'][i].keys()[0]
        col = element['columns'][i][key]
        totalize = (col.has_key?('totalize')) ? col['totalize'] : false
        perc_totalize = (col.has_key?('perc_totalize')) ? col['perc_totalize'] : false
        perc_num = (col.has_key?('perc_num')) ? col['perc_num'] : 0
        perc_dem = (col.has_key?('perc_dem')) ? col['perc_dem'] : 0
        
        unit = (col.has_key?('unit')) ? " #{col['unit']}" : ''

        unless col['width'].nil?
          current_width += col['width']
        else
          no_width_columns += 1
        end

        columns << {
          'field' => key,
          'label' => col['label'],
          'width' => col['width'],
          'totalize' => totalize,
          'perc_totalize' => perc_totalize,
          'perc_num' => perc_num,
          'perc_dem' => perc_dem,
          'precision' => col['precision'],
          'unit' => unit,
          'head' => {
            'align' => get_align(element['heading']['align']),
            'style' => get_style(element['heading']['style']),
          },
          'cell' => {
            'align' => get_align(col['align']),
            'style' => get_style(col['style']),
          }
        }
      end

      if (no_width_columns > 0)
        default_width = (@fwPt - (current_width * @k) - (@page_margins * 2 * @k)) / no_width_columns
        default_width /= @k
      end

      columns.each_index do |i|
        columns[i]['width'] = default_width.to_i if columns[i]['width'].nil?
        show_heading = true unless columns[i]['label'].nil?
      end

      return columns, show_heading
    end

    def set_bg_color(bg_color)
      if bg_color.nil?
        SetFillColor(255, 255, 255)
      else
        SetFillColor(bg_color[0].to_i, bg_color[1].to_i, bg_color[2].to_i)
      end
      return 1
    end

    def set_text_color(font_color)
      return if font_color.nil?
      SetTextColor(font_color[0].to_i, font_color[1].to_i, font_color[2].to_i)
    end

    def set_font(style)
      SetFont(style['font_family'], style['font_weight'], style['font_size'].to_i)
    end

    def set_cell(text, style, align=DEFAULT_ALIGN, width=0, margin=0, ln=0)
      fill = set_bg_color(style['bg_color'])
      set_text_color(style['font_color'])
      set_font(style)
      ln = get_breakline(ln)
      h = style['font_size'].to_i / 2
      Cell(margin, h, '', style['border']) if margin > 0
      width -= margin if width > 0

      Cell(width, h, text, style['border'], 0, align, fill)
      Ln(h) unless ln.zero?
    end

    def set_table_header(config, show_head=false)
      if show_head
        arr_width = config.map {|c| c['width']}
        arr_label = config.map {|c| c['label']}
        h = max_height(arr_width, arr_label, DEFAULT_LINE_HEIGHT)
        config.each do |column|
          style = column['head']['style']
          #align = column['head']['align']
          align = column['cell']['align']
          x = GetX()
          y = GetY()
          fill = set_bg_color(style['bg_color'])
          set_text_color(style['font_color'])
          set_font(style)
          Rect(x, y, column['width'], h, 'F')
          MultiCell(column['width'], DEFAULT_LINE_HEIGHT, column['label'], 0, align, 0)
          SetXY(x + column['width'], y)
        end
        Ln(h)
      end
    end

    def set_table_body(element, config, show_head=false)
      totals = {}
      table_data = @data[element['field']]
      grouping = get_grouping(element['grouping'])
      totalization = get_totalization(element['totalization'])

      table_data.each do |row|
        unless grouping.nil?
          title = row.delete(grouping['id'][0])
          if title != grouping['current']
            Ln(DEFAULT_LINE_HEIGHT/2)
            set_cell(title, grouping['style'][0], grouping['align'][0], 0, 0, 1)
            grouping['current'] = title
          end
        end
        arr_width = config.map {|c| c['width']}
        arr_content = row.values().collect{|value| value.to_s }
        h = max_height(arr_width, arr_content, DEFAULT_LINE_HEIGHT)

        set_table_header(config, show_head) if check_page_break(h)

        config.each do |column|
          if column['totalize']
            if totals.has_key?(column['field'])
              totals[column['field']] += row[column['field']].to_f
            else
              totals[column['field']] = row[column['field']].to_f
            end
          elsif column['perc_totalize']
            totals[column['field']] = totals[column['perc_num']] * 100 / totals [column['perc_dem']] rescue 0
          end

          field_text = row[column['field']]
          if column['precision']
            field_text = number_with_precision(row[column['field']].to_f, column['precision'].to_i)
          end

          text = "#{field_text}#{column['unit']}"
          style = column['cell']['style']
          align = column['cell']['align']
          x = GetX()
          y = GetY()
          fill = set_bg_color(style['bg_color'])
          set_text_color(style['font_color'])
          set_font(style)
          Rect(x, y, column['width'], h, 'F')
          MultiCell(column['width'], DEFAULT_LINE_HEIGHT, text, 0, align, 0)
          SetXY(x + column['width'], y)
        end
        Ln(h)
      end
      return totals
    end

    def set_table_totalization(element, config, totals, show_head)
      index = 0
      label_width = 0
      totalization = get_totalization(element['totalization'])
      return if totalization.nil?

      set_table_header(config, show_head) if check_page_break(DEFAULT_LINE_HEIGHT)

      config.each_index do |i|
        index = i
        break if config[i]['totalize']
        break if config[i]['perc_totalize']
        label_width += config[i]['width']
      end
      x = GetX()
      y = GetY()
      fill = set_bg_color(totalization['style']['bg_color'])
      set_text_color(totalization['style']['font_color'])
      set_font(totalization['style'])
      Rect(x, y, label_width, DEFAULT_LINE_HEIGHT, 'F')
      MultiCell(label_width, DEFAULT_LINE_HEIGHT, totalization['label'], totalization['border'], totalization['align'], fill)
      SetXY(x + label_width, y)

      index.upto(config.length - 1) do |i|
        field_text = totals[config[i]['field']]
        if totalization['precision']
          field_text = number_with_precision(totals[config[i]['field']].to_f, totalization['precision'].to_i)
        end
        text = ''
        if config[i]['totalize']
          text = "#{field_text}#{config[i]['unit']}"
        elsif config[i]['perc_totalize']
          text = "#{field_text}#{config[i]['unit']}"
        end
        x = GetX()
        y = GetY()
        fill = set_bg_color(totalization['style']['bg_color'])
        set_text_color(totalization['style']['font_color'])
        set_font(totalization['style'])
        Rect(x, y, config[i]['width'], DEFAULT_LINE_HEIGHT, 'F')
        MultiCell(config[i]['width'], DEFAULT_LINE_HEIGHT, text, totalization['border'], config[i]['cell']['align'], fill)
        SetXY(x + config[i]['width'], y)
      end
      Ln(DEFAULT_LINE_HEIGHT)
    end

    def check_page_break(h)
      if (self.GetY + h > @PageBreakTrigger)
        AddPage(@CurOrientation)
        return true
      else
        return false
      end
    end

    def max_height(arr_width, contents, line_height)
      arr = []
      arr_width.each_index do |i|
        arr << nb_lines(arr_width[i], contents[i])
      end
      h = arr.max * line_height
    end

    def nb_lines(width, text2)
      text = text2.clone()
      cw = @CurrentFont['cw']
      width = @w - @rMargin - @x  if (width == 0)
      wmax = (width - 2 * @cMargin) * 1000 / @FontSize
      s = text.gsub("\r", '')
      nb = s.length
      nb -= 1 if (nb > 0 and s[nb-1] == "\n")
      sep = -1
      i, j, l = 0, 0, 0
      nl = 1
      while i < nb
        c = s[i].chr
        if (c == "\n")
          i += 1
          sep = -1
          j = 1
          l = 0
          nl += 1
          next
        end
        sep = i if (c == ' ')
        l += cw[c[0].ord]/@k
        #puts "len: #{l} c: #{c} cw: #{cw[c[0]]} nl: #{nl}"
        if (l > wmax)
          if (sep == -1)
            i += 1 if i == j
          else
            i = sep + 1
          end
          sep = -1
          j = i
          l = 0
          nl += 1
        else
          i += 1
        end
      end
      nl
    end

    def round(number, options = {})
      options = options.stringify_keys
      precision = options["precision"] || 2
      unit = options["unit"] || ""
      separator = precision > 0 ? options["separator"] || "," : ""
      delimiter = options["delimiter"] || "."

      begin
        parts = number_with_precision(number, precision).split('.')
        unit + number_with_delimiter(parts[0], delimiter) + separator + parts[1].to_s
      rescue
        number
      end
    end

    def number_with_delimiter(number, delimiter=",", separator=".")
      begin
        parts = number.to_s.split('.')
        parts[0].gsub!(/(\d)(?=(\d\d\d)+(?!\d))/, "\\1#{delimiter}")
        parts.join separator
      rescue
        number
      end
     end

    def number_with_precision(number, precision=3)
      "%01.#{precision}f" % number
    rescue
      number
    end

  end # Report
end #EasyReport
