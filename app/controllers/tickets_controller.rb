# encoding: UTF-8

class TicketsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @tickets = Ticket.search(params[:number], params[:page], session[:per_page])
        render html: @tickets
      end
      format.json do
        @tickets = Ticket.includes(ticket_type: {},
                                   driver: {},
                                   truck: {carrier: {}})
                         .where(open: true)
        render json: @tickets,
               include: {ticket_type: {},
                         driver: {},
                         truck: {include: {carrier: {}}}}
      end
    end
  end

  def repair
    @ticket = Ticket.find params[:id], :include => :transactions
    @lots = Lot.includes(:ingredient).where(active: true)
  end

  def do_repair
    @ticket = Ticket.find params[:id]
    @ticket.update_attributes(params[:ticket])
    if @ticket.valid?
      @ticket.transactions.each do |t|
        t.transaction_type_id = @ticket.ticket_type_id == 1 ? 4 : 5
        t.user_id = @ticket.user_id
        t.client_id = @ticket.client_id
        t.comment = @ticket.comment
        logger.debug t.new_record?
        t.update_transactions unless t.new_record?
      end
    end
    @ticket.repaired = true
    if @ticket.save
      flash[:notice] = 'Ticket reparado con éxito'
      redirect_to :tickets
    else
      logger.debug @ticket.errors.messages
      @lots = Lot.includes(:ingredient).where(active: true)
      render :repair
    end
  end

  def create
    @ticket = Ticket.new params[:ticket]
    @ticket.incoming_date = Time.now
    respond_to do |format|
      format.json do
        @ticket.save
        render json: @ticket.errors
      end
    end
  end

  def update
    @ticket = Ticket.find params[:id]
    @ticket.update_attributes(params[:ticket])
    @ticket.user_id = session[:user_id]
    @ticket.transactions.each do |t|
      t.user_id = @ticket.user_id
      t.client_id = @ticket.client_id
      t.comment = @ticket.comment
    end
    @ticket.outgoing_date = Time.now
    @ticket.open = false
    respond_to do |format|
      format.html do
        if @ticket.save
          flash[:notice] = 'Ticket guardado con éxito'
          redirect_to :tickets
        else
          edit
          render :edit
        end
      end
      format.json do
        @ticket.save
        render json: @ticket.errors
      end
    end
  end

  def print
    data = EasyModel.ticket params[:id]
    if data.nil?
      flash[:notice] = 'El ticket se encuentra abierto'
      flash[:type] = 'warn'
      redirect_to action: 'index'
    else
      report = EasyReport::Report.new data, 'ticket.yml'
      send_data report.render, filename: "ticket_#{data['number']}.pdf", type: "application/pdf"
    end
  end

  def destroy
    @ticket = Ticket.find params[:id]
    if @ticket.open
      @ticket.eliminate
      if @ticket.errors.size.zero?
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
end
