module ReportsHelper
  @@ac = ApplicationController.new

  def render_flot(view, data, width, height, options = {})
    jpg_path = "tmp/#{view}-#{session[:user_id]}-#{options[:suffix]}.jpg"
    html_path = "tmp/#{view}-#{session[:user_id]}.html"
    File.open(html_path, 'w') do |file|
      file << @@ac.render_to_string(
        "reports/#{view}.flot",
        layout: 'flot',
        locals: {
          data: data,
          width: width,
          height: height
        }
      )
    end
    %x(wkhtmltoimage --crop-h #{height} --crop-w #{width} #{html_path} #{jpg_path})
    jpg_path
  end

  def to_week_number(week)
    first_week = @data[:first_week]
    week_number = week.strftime('%W').to_i
    if week_number > first_week
      week_number - first_week
    else
      52 - (first_week - week_number)
    end
  end

  def render_weekly_recipes_table(page_index, start_week, weeks)
    thead = content_tag :thead do
      content_tag :tr do
        tr = [content_tag(:th, 'Receta')]
        tr << 12.times.collect do |i|
          if i < weeks
            week_start = start_week + i.weeks
            week_end = week_start + 1.week - 1.day
            cell_content = "Semana #{to_week_number(week_start)}\n#{EasyModel.print_formatted_date(week_start)}\n#{EasyModel.print_formatted_date(week_end)}"
          end
          content_tag :th, cell_content
        end
        tr.join.html_safe
      end
    end
    tbody = content_tag :tbody do
      alternate = 1
      internal_consumption = nil
      @data[:results].collect do |result|
        trs = []
        if result[:internal_consumption] != internal_consumption
          trs << content_tag(:tr, class: 'subheader') do
            content_tag :td, result[:internal_consumption] ? 'Consumo interno' : 'Ventas', class: 'center', colspan: 12 + 1
          end
          internal_consumption = result[:internal_consumption]
          alternate = 1
        end
        alternate *= -1
        trs << content_tag(:tr, class: alternate == 1 ? 'blank' : 'alternate') do
          tr = [content_tag(:td, result[:recipe_name], class: 'center')]
          tr << 12.times.collect do |i|
            if i < weeks
              cell_content = result[:versions][i + 12 * page_index].collect do |recipe|
                link_to recipe[:version], recipe[:path], target: '_blank'
              end.join(', ').html_safe
            end
            content_tag :td, cell_content, class: 'center'
          end
          tr.join.html_safe
        end
        trs.join.html_safe
      end.join.html_safe
    end
    content_tag :table, thead.concat(tbody), id: 'tabledata'
  end
end
