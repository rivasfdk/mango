module ActionsHelper
  def render_action_factory_lots(url)
    image = image_tag('action-edit.png', alt: 'Lotes por fábrica')
    return link_to image + " Lotes por fábrica", url, class: 'action'
  end

  def render_action_show(url)
    image = image_tag('action-show.png', alt: 'Mostrar')
    return link_to image + " Mostrar", url, class: 'action'
  end

  def render_action_show_lots(url)
    image = image_tag('action-show.png', alt: 'Ver lotes')
    return link_to image + " Ver lotes", url, class: 'action'
  end

  def render_action_show_parameters(url)
    image = image_tag('action-show.png', alt: 'Mostrar características')
    return link_to image + " Mostrar características", url, class: 'action'
  end

  def render_action_edit_ranges(url)
    image = image_tag('action-edit.png', alt: 'Editar rangos')
    return link_to image + " Editar rangos", url, class: 'action'
  end

  def render_action_show_hoppers(url)
    image = image_tag('action-show.png', alt: 'Mostrar tolvas')
    return link_to image + " Mostrar tolvas", url, class: 'action'
  end

  def render_action_deactivate(url, confirm)
    image = image_tag('action-reset.png', alt: 'Desactivar')
    return link_to image + " Desactivar", url, class: 'action', data: { confirm: confirm }
  end

  def render_action_edit(url)
    image = image_tag('action-edit.png', alt: 'Editar')
    return link_to image + "Editar", url, class: 'action'
  end

  def render_action_adjust(url)
    image = image_tag('action-edit.png', alt: 'Ajustar')
    return link_to image + "Ajustar", url, class: 'action'
  end

  def render_action_repair(url)
    image = image_tag('action-edit.png', alt: 'Reparar')
    return link_to image + "Reparar", url, class: 'action'
  end

  def render_action_notify(url)
    image = image_tag('action-edit.png', alt: 'Notificar')
    return link_to image + "Notificar", url, class: 'action'
  end

  def render_action_notify_confirm(url, confirm)
    image = image_tag('action-edit.png', alt: 'Notificar')
    return link_to image + "Notificar", url, class: 'action', data: { confirm: confirm }
  end

  def render_action_recalculate(url)
    image = image_tag('action-reset.png', alt: 'Recalcular')
    return link_to image + "Recalcular", url, class: 'action'
  end

  def render_action_clone(url, confirm)
    image = image_tag('action-clone.png', alt: 'Clonar')
    return link_to image + " Clonar", url, class: 'action', data: { confirm: confirm }
  end

  def render_action_print(url)
    image = image_tag('action-print.png', alt: 'Imprimir')
    return link_to image + " Imprimir", url, class: 'action'
  end

  def render_action_change_hopper_lot(url)
    image = image_tag('action-edit.png', alt: 'Cambiar lote')
    return link_to image + " Cambiar lote", url, class: 'action'
  end

  def render_action_fill_hopper(url)
    image = image_tag('action-edit.png', alt: 'Llenar')
    return link_to image + " Llenar", url, class: 'action'
  end

  def render_action_delete(url, confirm)
    image = image_tag('action-delete.png', alt: 'Borrar')
    return link_to image + " Eliminar", url, class: 'action', method: :delete, data: { confirm: confirm }
  end

  def render_action_create(url, confirm)
    image = image_tag('action-new.png', alt: 'crear')
    return link_to image + " Crear", url, class: 'action', method: :post, data: { confirm: confirm }
  end

  def render_remote_action_show(url)
    image = image_tag('action-show.png', alt: 'Mostrar')
    return link_to image, url, remote: true
  end

  def render_remote_action_delete(url , confirm)
    image = image_tag('action-delete.png', alt: 'Borrar')
    return link_to image + " Eliminar", url, method: :delete, remote: true, data: { confirm: confirm }, html: {class: 'action'}
  end

  def render_action_modify()
    image = image_tag('action-edit.png', alt: 'Modificar')
    return link_to image + " Modificar", '#!', class: 'action action-modify'
  end

  def render_action_cancel()
    image = image_tag('action-cancel.png', alt: 'Cancelar')
    return link_to image + " Cancelar", '#!', class: 'action action-cancel'
  end

  def render_action_change_ingredient(url)
    image = image_tag('action-edit.png', alt: 'Cambiar materia prima')
    return link_to image + " Cambiar materia prima", url, class: 'action'
  end

  def render_action_change_product(url)
    image = image_tag('action-edit.png', alt: 'Cambiar producto terminado')
    return link_to image + " Cambiar producto terminado", url, class: 'action'
  end

  def render_action_fill_warehouse(url)
    image = image_tag('action-edit.png', alt: 'Llenar')
    return link_to image + " Llenar", url, class: 'action'
  end
end
