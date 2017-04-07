  # encoding: UTF-8

include MangoModule

class TicketsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @states = Ticket.get_states()
        @drivers = Driver.where(frequent: true)
        @carriers = Carrier.where(frequent: true)
        @ticket_types = TicketType.all
        @ingredients = Ingredient.actives
        @tickets = Ticket.search(params) 
        @factories = Client.where(factory: true) << Client.new(code: "-1", name: session[:company]['name'])
        render html: @tickets
      end
      format.json do
        @tickets = Ticket.includes(ticket_type: {}, driver: {}, truck: {carrier: {}}).where(open: true)
        render json: @tickets, include: {ticket_type: {}, driver: {}, truck: {include: {carrier: {}}}}
      end
    end
  end

  def repair
    @ticket = Ticket.find params[:id], :include => :transactions
    @lots = Lot.includes(:ingredient).where(active: true)
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    @lots_warehouses = Warehouse.where(product_lot_id: nil)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
  end

  def do_repair
    @ticket = Ticket.find params[:id]
    @ticket.update_attributes(params[:ticket])
    @ticket.transactions.each do |t|
      t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
      t.notified = @ticket.notified
      unless t.sack
        t.sacks = nil
        t.sack_weight = nil
      end
      t.amount = t.amount_was if t.marked_for_destruction?
    end
    if @ticket.valid?
      @ticket.transactions.each do |t|
        t.update_transactions unless t.new_record? || !t.notified
      end
      @ticket.repaired = true
      @ticket.save
      flash[:notice] = 'Ticket reparado con éxito'
      redirect_to :tickets
    else
      @lots = Lot.includes(:ingredient).where(active: true)
      @product_lots = ProductLot.includes(:product).where(active: true)
      @clients = Client.all
      @drivers = Driver.where(frequent: true)
      unless @ticket.driver.frequent
        @drivers << @ticket.driver
      end
      render :repair
    end
  end

  def notify
    @ticket = Ticket.find params[:id]
    @ticket.notify unless @ticket.open
    flash[:notice] = 'Ticket notificado con éxito'
    redirect_to :tickets
  end

  def create
    @ticket = Ticket.new params[:ticket]
    @ticket.incoming_date = Time.now
    @ticket.user_id = (User.find session[:user_id]).id
    if @ticket.save
      flash[:notice] = 'Ticket guardado, seleccione los rubros del ticket'
      redirect_to items_ticket_path(@ticket.id)
    else
      new
      render :new
    end
  end

  def new
    @rorders = TicketOrder.where(order_type: true,closed: false)
    @tickets = Ticket.new
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    @trucks = Truck.includes(:carrier).where(frequent: true)
    @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
  end

  def import
    sharepath = get_mango_field('share_path')
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      order_count = 0
      files = []
      begin
        files = Dir.entries(sharepath)
      rescue
        puts "++++++++++++++++++++"
        puts "+++ error de red +++"
        puts "++++++++++++++++++++"
      end
      if files.any?
        orders = TicketOrder.import(files)
        if not orders.empty?
          order_count = TicketOrder.create_orders(orders)
        end
      end
      if order_count > 0
        flash[:notice] = "Se importaron #{order_count} ordenes con exito"
      else
        flash[:type] = 'warn'
        flash[:notice] = 'No se encontraron ordenes para importar'
      end
    end
    redirect_to action: 'index'
  end

  def edit
    @ticket = Ticket.find params[:id], :include => :transactions
    ticket_type = @ticket.ticket_type_id == 1 ? true : false
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      if !@ticket.id_order.nil?
        @orders = TicketOrder.where(order_type: ticket_type,closed: false)
        @label = TicketOrder.find(@ticket.id_order).order_type ? "Orden de Compra" : "Orden de Salida"
      else
        @orders = []
      end
    end
    @lots_warehouses = Warehouse.where(product_lot_id: nil)
    @product_lots_warehouses = Warehouse.where(lot_id: nil)
    @lots = Lot.includes(:ingredient).where(active: true)
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
  end

  def update
    @ticket = Ticket.find params[:id]
    redirect_to :tickets unless @ticket.open
    @ticket.update_attributes(params[:ticket])
    @ticket.user_id = session[:user_id]
    @ticket.transactions.each do |t|
      t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
      t.notified = @ticket.notified
      unless t.sack
        t.sacks = nil
        t.sack_weight = nil
      end
      t.amount = t.amount_was if t.marked_for_destruction?
    end
    @ticket.outgoing_date = Time.now
    if @ticket.valid?
      @ticket.transactions.each do |t|
        t.update_transactions unless t.new_record? || !t.notified
      end
      @ticket.save
      flash[:notice] = 'Ticket guardado con éxito'
      redirect_to :tickets
    else
      edit
      render :edit
    end
  end

  def print
    @ticket = Ticket.find params[:id]
    @data = EasyModel.ticket params[:id]
    if @data.nil?
      flash[:notice] = 'El ticket se encuentra abierto'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      ticket_template = get_mango_field('ticket_template')
      case ticket_template
      when 1
        rendered = render_to_string formats: [:pdf]
      when 2
        @data[:ticket_template] = '2'
        rendered = render_to_string formats: [:pdf], template: 'tickets/custom_ticket'
      else
        rendered = render_to_string formats: [:pdf], template: 'tickets/default_ticket'
      end
      send_data rendered, filename: "ticket_#{@data['number']}.pdf", type: "application/pdf", disposition: 'inline'
    end
  end

  def destroy
    @ticket = Ticket.find params[:id]
    if @ticket.open
      @ticket.eliminate
      if @ticket.errors.empty?
        flash[:notice] = "Ticket eliminado con éxito"
      else
        logger.error("Error eliminando ticket: #{@ticket.errors.inspect}")
        flash[:type] = 'error'
        if not @ticket.errors[:foreign_key].nil?
          flash[:notice] = 'El ticket no se puede eliminar porque tiene registros asociados'
        elsif not @ticket.errors[:unknown].nil?
          flash[:notice] = @ticket.errors[:unknown]
        else
          flash[:notice] = "No se puede eliminar un ticket cerrado"
        end
      end
    else
      flash[:type] = 'error'
      flash[:notice] = "El ticket no se ha podido eliminar"
    end
    redirect_to :tickets
  end

  def items
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      TicketOrder.create_transactions(params[:id])
    end
    @ticket = Ticket.find params[:id], :include => :transactions
    @ticket.transactions.each do |t|
      content_type = (t.content_type == 1) ? true : false
      if t.warehouse_id.nil?
        if content_type
          warehouse = Warehouse.find_by(lot_id: t.content_id)
        else
          warehouse = Warehouse.find_by(product_lot_id: t.content_id)
        end
        if warehouse.nil?
          warehouse_content = WarehouseContents.find_by(content_id: t.content_id, content_type: content_type)
          if !warehouse_content.nil?
            warehouse = Warehouse.find(warehouse_content.warehouse_id)
          end
        end
        t.warehouse_id = warehouse.nil? ? nil : warehouse.id
      end
    end
    @lots_warehouses = []
    @product_lots_warehouses = []
    @lots = Lot.includes(:ingredient).where(active: true, empty: nil)
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
  end

  def update_items
    @ticket = Ticket.find params[:id]
    redirect_to :tickets unless @ticket.open
    @ticket.update_attributes(params[:ticket])
    @ticket.user_id = session[:user_id]
    error = nil
    @ticket.transactions.each do |t|
      t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
      t.notified = @ticket.notified
      unless t.sack
        t.sacks = nil
        t.sack_weight = nil
      end
      t.amount = t.amount_was if t.marked_for_destruction?
    end
    @ticket.transactions.each do |t|
      if t.content_id.nil?
        error = "Debe selecionar un lote"
      elsif t.warehouse_id.nil?
        error = "El lote #{t.get_lot.to_collection_select} no esta asignado a ningún almacen"
      else
        t.update_transactions unless t.new_record? || !t.notified
      end
    end
    if error.nil?
      @ticket.save
      flash[:notice] = 'Items guardados con éxito'
      if @ticket.incoming_weight.nil?
        entry
        redirect_to entry_ticket_path(@ticket.id)
      else
        redirect_to action: 'index'
      end
    else
      flash[:type] = 'error'
      flash[:notice] = error
      items
      render :items
    end
  end

  def entry
    @ticket = Ticket.find params[:id], :include => :transactions
    ticket_type = @ticket.ticket_type_id == 1 ? true : false
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      if !@ticket.id_order.nil?
        @order = TicketOrder.find(@ticket.id_order)
        @label = TicketOrder.find(@ticket.id_order).order_type ? "Orden de Compra" : "Orden de Salida"
      end
    end
    @lots = Lot.includes(:ingredient).where(active: true)
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
    @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
  end

  def update_entry
    @ticket = Ticket.find params[:id]
    redirect_to :tickets unless @ticket.open
    @ticket.update_attributes(params[:ticket])
    @ticket.user_id = session[:user_id]
    @ticket.transactions.each do |t|
      t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
      t.notified = @ticket.notified
      unless t.sack
        t.sacks = nil
        t.sack_weight = nil
      end
      t.amount = t.amount_was if t.marked_for_destruction?
    end
    @ticket.outgoing_date = Time.now
    if @ticket.valid?
      @ticket.transactions.each do |t|
        t.update_transactions unless t.new_record? || !t.notified
      end
      @ticket.save
      flash[:notice] = 'Ticket guardado con éxito'
      redirect_to :tickets
    else
      entry
      render :entry
    end
  end

  def close
    @ticket = Ticket.find params[:id], :include => :transactions
    ticket_type = @ticket.ticket_type_id == 1 ? true : false
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      if !@ticket.id_order.nil?
        @order = TicketOrder.find(@ticket.id_order)
        @label = TicketOrder.find(@ticket.id_order).order_type ? "Orden de Compra" : "Orden de Salida"
      end
    end
    @lots_warehouses = Warehouse.where(content_type: true)
    @product_lots_warehouses = Warehouse.where(content_type: false)
    @lots = Lot.includes(:ingredient).where(active: true)
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
    @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
  end

  def do_close
    @ticket = Ticket.find params[:id]
    redirect_to :tickets unless @ticket.open
    @ticket.update_attributes(params[:ticket])
    @ticket.user_id = session[:user_id]
    @ticket.transactions.each do |t|
      t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
      t.notified = @ticket.notified
      unless t.sack
        t.sacks = nil
        t.sack_weight = nil
      end
      t.amount = t.amount_was if t.marked_for_destruction?
    end
    @ticket.open = false
    @ticket.outgoing_date = Time.now

    if @ticket.outgoing_weight.nil? or @ticket.outgoing_weight.zero?
      flash[:type] = 'error'
      flash[:notice] = 'El peso de Salida no es valido'
      close
      render :close
    else

      if @ticket.ticket_type_id == 1
        net_weight = @ticket.incoming_weight - @ticket.outgoing_weight
        dif_min = (Settings.find 1).ticket_reception_diff
        dif = (@ticket.provider_weight - net_weight).abs
        porcent_dif = (dif / @ticket.provider_weight) * 100
        dif_validation = porcent_dif <= dif_min ? true : false
      else
        net_weight = @ticket.outgoing_weight - @ticket.incoming_weight
        dif_min = (Settings.find 1).ticket_dispatch_diff
        total_transaction = 0
        @ticket.transactions.each do |t|
          total_transaction = total_transaction + t.amount
        end
        dif = (total_transaction - net_weight).abs
        porcent_dif = (dif / total_transaction) * 100
        dif_validation = porcent_dif <= dif_min ? true : false
      end

      if !dif_validation
        flash[:type] = 'error'
        flash[:notice] = "Diferencia de peso es #{porcent_dif}% mayor a la minima aceptada: #{dif_min}%"
        close
        render :close
      else
        if @ticket.transactions.length > 1
          @ticket.transactions.each do |t|
            t.update_transactions unless t.new_record? || !t.notified
          end
        else
          @ticket.transactions.each do |t|
            t.amount = net_weight
            t.update_transactions unless t.new_record? || !t.notified
          end
        end
        mango_features = get_mango_features()
          if mango_features.include?("sap_romano")
            TicketOrder.close(@ticket)
          end
        if @ticket.valid?
          @ticket.save
          flash[:notice] = 'Ticket cerrado con éxito'
          redirect_to :tickets, :action => "print"
        else
          flash[:type] = 'error'
          flash[:notice] = "El peso de Salida no es valido"
          close
          render :close
        end
      end
    end

  end

  def get_server_romano_ip
    server_romano_ip = get_mango_field('server_romano_ip')
    render json: server_romano_ip
  end

end
