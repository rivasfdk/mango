# Adds inline formatting to text boxes in Thinreports
# I'm so sorry

module ThinReports
  module Generator
    module PDF::Graphics
      def text_box(content, x, y, w, h, attrs = {})
        w, h = s2f(w, h)
        box_attrs = text_box_attrs(x, y, w, h, :single   => attrs.delete(:single), 
                                               :overflow => attrs[:overflow])
        # Do not break by word unless :word_wrap is :break_word
        content = text_without_line_wrap(content) if attrs[:word_wrap] == :none
        
        with_text_styles(attrs) do |built_attrs, font_styles|
          # Parse inline formatting
          text_array = Prawn::Text::Formatted::Parser.to_array(content)
          text_array.each { |text| text[:styles] |= font_styles }
          
          pdf.formatted_text_box(text_array, built_attrs.merge(box_attrs))
        end
      rescue Prawn::Errors::CannotFit => e
        # Nothing to do.
        # 
        # When the area is too small compared
        # with the content and the style of the text.
        #   (See prawn/core/text/formatted/line_wrap.rb#L185)
      end
    end
  end
end
  