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
      flash[:notice] = 'Ticket guardado con éxito'
      redirect_to :tickets
    else
      new
      render :new
    end
  end

  def new
    sharepath = get_mango_field('share_path')
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
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
          TicketOrder.create_orders(orders)
          TicketOrder.remaining
        end
      end
      @rorders = TicketOrder.where(order_type: true,closed: false)
    end
    @tickets = Ticket.new
    @transactions = Transaction.new
    @clients = Client.all
    @drivers = Driver.where(frequent: true)
    @trucks = Truck.includes(:carrier).where(frequent: true)
    @lots = Lot.includes(:ingredient).where(active: true)
    @warehouses = Warehouse.where(content_type: false)
    @granted_manual = User.find(session[:user_id]).has_global_permission?('tickets', 'manual')
  end

  def edit
    @ticket = Ticket.find params[:id], :include => :transactions
    mango_features = get_mango_features()
    if mango_features.include?("sap_romano")
      TicketOrder.create_transactions(params[:id])
      if not @ticket.id_order.nil?
        @orders = TicketOrder.where(id: @ticket.id_order)
        @label = @orders[0].order_type ? "Orden de Compra" : "Orden de Salida"
      else
        @orders = []
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
    @ticket.open = false
    @ticket.outgoing_date = Time.now

    if not @ticket.outgoing_weight.nil?
      if @ticket.valid?
        @ticket.transactions.each do |t|
          t.update_transactions unless t.new_record? || !t.notified
        end
        mango_features = get_mango_features()
          if mango_features.include?("sap_romano")
            TicketOrder.close(@ticket)
          end
        @ticket.save
        flash[:notice] = 'Ticket cerrado con éxito'
        redirect_to :tickets
      else
        edit
        render :edit
      end
    else
      flash[:notice] = 'El peso de Salida no es valido'
      render :edit
    end
  end

  def print
    @data = EasyModel.ticket params[:id]
    if @data.nil?
      flash[:notice] = 'El ticket se encuentra abierto'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      ticket_template = get_mango_field('ticket_template')
      if ticket_template
        @data[:ticket_template] = ticket_template
        rendered = render_to_string formats: [:pdf]
      else
        rendered = EasyReport::Report.new(@data, 'ticket.yml').render
      end
      send_data rendered, filename: "ticket_#{@data['number']}.pdf", type: "application/pdf"
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

  def get_server_romano_ip
    server_romano_ip = get_mango_field('server_romano_ip')
    render json: server_romano_ip
  end

end
