class DynamicTemplate
  def self.generate(data, filename)
    filepath = "#{Rails.root.to_s}/config/reports/dynamic/#{filename}"
    template = YAML::load(File.open(filepath))

    title_key = template["report"]["body"].keys[-3]
    table_key = template["report"]["body"].keys[-2]
    breakline_key = template["report"]["body"].keys[-1]

    title_template = template["report"]["body"].delete title_key
    table_template = template["report"]["body"].delete table_key
    breakline_template = template["report"]["body"].delete breakline_key

    data['tables'].each_with_index do |tabledata, index|
      breakline = breakline_template

      title = eval(title_template.to_s)
      title["text"]["field"] = "title#{index + 1}"

      table = eval(table_template.to_s)
      table["table"]["field"] = "table#{index + 1}"

      template["report"]["body"][title_key + 3*index] = title
      template["report"]["body"][table_key + 3*index] = table
      template["report"]["body"][breakline_key + 3*index] = breakline

      data["title#{index + 1}"] = tabledata["title"]
      data["table#{index + 1}"] = tabledata["table"]
    end
    data.delete 'tables'

    return data, template
  end
end
