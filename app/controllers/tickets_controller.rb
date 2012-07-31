class TicketsController < ApplicationController
  def index
    respond_to do |format|
      format.html do
        @tickets = Ticket.paginate :all, :page=>params[:page], :per_page=>session[:per_page], :order => 'number DESC'
        render :html => @tickets
      end
      format.json do
        @tickets = Ticket.find :all, :conditions => {:open => true}
        render :json => @tickets, :include => {:ticket_type => {}, :driver => {}, :truck => {:include => {:carrier => {}}}}
      end
    end
  end

  def new
    @ticket_types = TicketType.find :all
    @trucks = Truck.find :all
    @drivers = Driver.find :all
  end

  def edit
    @ticket = Ticket.find params[:id]
    @ticket_types = TicketType.find :all
    @trucks = Truck.find :all
    @drivers = Driver.find :all
  end

  def create
    @ticket = Ticket.new params[:ticket]
    @ticket.incoming_date = Time.now
    respond_to do |format|
      format.html do
        if @ticket.save
          flash[:notice] = 'Ticket guardado con éxito'
          redirect_to :tickets
        else
          new
          render :new
        end
      end
      format.json do
        @ticket.save
        render :json => @ticket.errors
      end
    end
  end

  def update
    @ticket = Ticket.find params[:id]
    @ticket.update_attributes(params[:ticket])
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
        render :json => @ticket.errors
      end
    end
  end

  def print
    data = EasyModel.ticket params[:id]
    if data.nil?
      flash[:notice] = 'El ticket se encuentra abierto'
      flash[:type] = 'warn'
      redirect_to :action => 'index'
    else
      report = EasyReport::Report.new data, 'ticket.yml'
      send_data report.render, :filename => "ticket_#{data['number']}.pdf", :type => "application/pdf"
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
