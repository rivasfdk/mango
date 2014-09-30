# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include Rails.application.routes.url_helpers

  def alternate_row_class(num)
    class_row = (num % 2).zero? ? 'blank' : 'alternate'
    return class_row, num + 1
  end

  def render_error_messages(messages)
    return '' if messages.blank?
    errors = content_tag(:div, 
      content_tag(:div, '', :class=>'background') +
      content_tag(:div, 
        messages + 
        content_tag(:div, button_to_function('Cerrar', 'close_error_dialog()', :class=>'err_btn'), :id=>'errorButton'),
      :id=>'errorDialog'),
    :id=>'modal')
    return errors
  end

  def title(page_title)
    content_for :title, page_title.to_s
  end

  def link_to_add_fields(name, f, association)
    new_object = f.object.class.reflect_on_association(association).klass.new
    fields = f.fields_for(association, new_object, :child_index => "new_#{association}") do |builder|
      render(association.to_s.singularize + "_fields", :f => builder)
    end
    link_to_function(name, raw("add_fields(this, \"#{association}\", \"#{escape_javascript(fields)}\")"))
  end
end