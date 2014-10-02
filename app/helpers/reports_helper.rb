module ReportsHelper
  @@ac = ApplicationController.new

  def render_flot(view, data, width, height)
    jpg_path = "tmp/#{view}-#{session[:user_id]}.jpg"
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
end
