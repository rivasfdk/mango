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
        @ingredients = Ingredient.all#actives
        @tickets = Ticket.search(params) 
        @factories = Client.where(factory: true) << Client.new(code: "-1", name: session[:company]['name'])
        mango_features = get_mango_features()
        @mango_romano =  mango_features.include?("mango_romano")
        @warehouse =  mango_features.include?("warehouse")
        @granted_diff_authorized = User.find(session[:user_id]).has_global_permission?('tickets', 'authorize')
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
    mango_features = get_mango_features()
    if mango_features.include?("ticket_txt")
      if @ticket.transactions.first.content_type == 1
        if Lot.find(@ticket.transactions.first.content_id).client_id == 980190967
          @ticket.generate_txt
        end
      else
        if ProductLot.find(@ticket.transactions.first.content_id).client_id == 980190967
          @ticket.generate_txt
        end
      end
    end
    flash[:notice] = 'Ticket notificado con éxito'
    redirect_to :tickets
  end

  def authorize
    @ticket = Ticket.find params[:id]
    @ticket.diff_authorized = 2
    @ticket.authorized_user_id = session[:user_id]
    @ticket.save
    flash[:notice] = "Ticket #{@ticket.number} autorizado para salir con diferencia de peso"
    redirect_to :tickets
  end

  def create
    encre = TicketNumber.first
    if encre.enable_create
      @ticket = Ticket.new params[:ticket]
      @ticket.incoming_date = Time.now
      @ticket.user_id = (User.find session[:user_id]).id
      @ticket.diff_authorized = 0
      @ticket.address = ""
      encre.enable_create = false
      encre.save
      respond_to do |format|
        format.json do
          @ticket.save
          render json: @ticket.errors
        end
        format.html do
          if @ticket.save
            flash[:notice] = 'Ticket guardado con exito'
            redirect_to :tickets #entry_ticket_path(@ticket.id)
          else
            new
            render :new
          end
        end
      end
    else
      redirect_to :tickets
    end
  end

  def new
    mango_features = get_mango_features()
    if mango_features.include?("mango_romano")
      @rorders = TicketOrder.where(order_type: true,closed: false)
      @tickets = Ticket.new
      @clients = Client.all
      @drivers = Driver.where(frequent: true)
      @trucks = Truck.includes(:carrier).where(frequent: true)
      @carriers = Carrier.all
      @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
      encre = TicketNumber.first
      encre.enable_create = true
      encre.save
    else
      redirect_to action: 'index'
    end
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
    @address = Address.all
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

  def update
    respond_to do |format|
      format.html do
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
          t.amount = 0 if t.amount.nil?
        end

        if @ticket.ticket_type_id == 2
          tcount = 0
          totalt = 0
          tsack = false
          @ticket.transactions.each do |t|
            tsack = t.sack
            totalt = totalt + t.amount
            tcount = tcount + 1
          end
          if tsack or tcount > 1
            @ticket.provider_weight = totalt
          else
            @ticket.provider_weight = nil
          end
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
      format.json do
        @ticket = Ticket.find params[:id]
        redirect_to :tickets unless @ticket.open
        @ticket.update_attributes(params[:ticket])
        @ticket.user_id = session[:user_id]
        @ticket.transactions.each do |t|
          t.user_id = @ticket.user_id
          t.client_id = @ticket.client_id
          t.comment = @ticket.comment
          t.notified = @ticket.notified
        end
        @ticket.outgoing_date = Time.now
        @ticket.open = false
        @ticket.save
        render json: @ticket.errors
      end
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

  def close
    @ticket = Ticket.find params[:id], :include => :transactions
    if !@ticket.open
      flash[:notice] = 'El ticket se encuentra cerrado'
      flash[:type] = 'warn'
      redirect_to :tickets
    end
    ticket_type = @ticket.ticket_type_id == 1 ? true : false
    mango_features = get_mango_features()
    @warehouse = mango_features.include?("warehouse")
    if mango_features.include?("sap_romano")
      if !@ticket.id_order.nil?
        @order = TicketOrder.find(@ticket.id_order)
        @label = TicketOrder.find(@ticket.id_order).order_type ? "Orden de Compra" : "Orden de Salida"
      end
    end
    if @warehouse
      @lots_warehouses = Warehouse.where(content_type: true)
      @product_lots_warehouses = Warehouse.where(content_type: false)
    end
    @lots = Lot.includes(:ingredient).where(active: true)
    @clients = Client.all
    @address = Address.all
    @drivers = Driver.where(frequent: true)
    unless @ticket.driver.frequent
      @drivers << @ticket.driver
    end
    @trucks = Truck.includes(:carrier).where(frequent: true)
    unless @ticket.truck.frequent
      @trucks << @ticket.truck
    end
    @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
    if @ticket.diff_authorized > 1
      @user_authorized = User.find(@ticket.authorized_user_id).name
    end
  end

  def do_close
    if params[:commit] == 'Guardar'
      puts 'guardar'
      @ticket = Ticket.find params[:id]
      if !@ticket.open
        flash[:notice] = 'El ticket se encuentra cerrado'
        flash[:type] = 'warn'
        redirect_to :tickets
      else
        @ticket.update_attributes(params[:ticket])
        @ticket.user_id = session[:user_id]
        @ticket.outgoing_weight = nil
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
          t.amount = 0 if t.amount.nil?
        end

        if @ticket.ticket_type_id == 2
          tcount = 0
          totalt = 0
          tsack = false
          @ticket.transactions.each do |t|
            tsack = t.sack
            totalt = totalt + t.amount
            tcount = tcount + 1
          end
          if tsack or tcount > 1
            @ticket.provider_weight = totalt
          else
            @ticket.provider_weight = nil
          end
        end

        if @ticket.valid?
          @ticket.transactions.each do |t|
            t.update_transactions unless t.new_record? || !t.notified
          end
          @ticket.save
          flash[:notice] = 'Ticket guardado con éxito'
          redirect_to :tickets
        else
          close
          render :close
        end
      end

    else
      puts 'cerrar'
      @ticket = Ticket.find params[:id]
      @address = @ticket.address
      if !@ticket.open
        flash[:notice] = 'El ticket se encuentra cerrado'
        flash[:type] = 'warn'
        redirect_to :tickets
      else
        @ticket.update(client_id: params[:ticket][:client_id], address: params[:ticket][:address]) if @ticket.client_id.nil?
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
          t.amount = 0 if t.amount.nil?
        end

        if @ticket.ticket_type_id == 2
          tcount = 0
          totalt = 0
          tsack = false
          @ticket.transactions.each do |t|
            tsack = t.sack
            totalt = totalt + t.amount
            tcount = tcount + 1
          end
          if tsack or tcount > 1
            @ticket.provider_weight = totalt
          else
            @ticket.provider_weight = nil
          end
        end

        if @ticket.save

          @ticket.open = false
          @ticket.outgoing_date = Time.now

          if @ticket.outgoing_weight.nil? or @ticket.outgoing_weight.zero?
            flash[:type] = 'error'
            flash[:notice] = 'El peso de Salida no es valido'
            close
            render :close
          else
            if !@ticket.transactions.empty?
              if @ticket.ticket_type_id == 1
                net_weight = @ticket.incoming_weight - @ticket.outgoing_weight
                dif_min = (Settings.find 1).ticket_reception_diff
                dif = net_weight - @ticket.provider_weight
                if dif < 0
                  dif = (@ticket.provider_weight - net_weight).abs
                  porcent_dif = (dif / @ticket.provider_weight) * 100
                  dif_validation = porcent_dif <= dif_min ? true : false
                else
                  dif_validation = true
                end
              else
                if @ticket.transactions.length > 1 or @ticket.transactions[0].sack
                  net_weight = @ticket.outgoing_weight - @ticket.incoming_weight
                  dif_min = (Settings.find 1).ticket_dispatch_diff
                  total_transaction = 0
                  @ticket.transactions.each do |t|
                    total_transaction = total_transaction + t.amount
                  end
                  @ticket.provider_weight = total_transaction
                  dif = (total_transaction - net_weight).abs
                  porcent_dif = (dif / total_transaction) * 100
                  dif_validation = porcent_dif <= dif_min ? true : false
                else
                  net_weight = @ticket.outgoing_weight - @ticket.incoming_weight
                  dif_validation = true
                end
              end

              if !dif_validation && @ticket.diff_authorized < 2
                Ticket.find(@ticket.id).update(diff_authorized: 1)
                flash[:type] = 'error'
                flash.now[:notice] = "Diferencia de peso es #{porcent_dif.round(1)}% mayor a la minima aceptada: #{dif_min}%"
                close
                render :close
              else
                if net_weight < 0
                  flash[:type] = 'error'
                  flash.now[:notice] = "El peso neto no puede ser NEGATIVO"
                  close
                  render :close
                else
                  if @ticket.client.nil? or @ticket.address.empty?
                      flash[:type] = 'error'
                      flash[:notice] = "No se ha seleccionado dirección de origen o desdino"
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
                      print
                    else
                      flash[:type] = 'error'
                      flash[:notice] = "El peso de Salida no es valido"
                      close
                      render :close
                    end
                  end
                end
              end
            else
              flash[:type] = 'error'
              flash[:notice] = 'Debe agregar por lo menos un rubro!'
              close
              render :close
            end
          end
        else
          flash[:type] = 'error'
          flash[:notice] = 'Error en el ticket!'
          close
          render :close         
        end
      end
    end
    

  end

  def get_server_romano_ip
    server_romano = get_mango_field('server_romano_ip')
    settings = Settings.first
    server_romano_ip = []
    if settings.port1 & !settings.port2
      server_romano_ip[0] = server_romano["in"]
    else
      if settings.port2 & !settings.port1
        server_romano_ip[0] = server_romano["out"]
      else
        if params['type'] == '1'
          server_romano_ip[0] = server_romano["in"]
        else
          server_romano_ip[0] = server_romano["out"]
        end
      end
    end
    render json: server_romano_ip
  end

end
