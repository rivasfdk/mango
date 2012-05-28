class TicketsController < ApplicationController
  def index
    @tickets = Ticket.paginate :all, :page=>params[:page], :per_page=>session[:per_page], :order => 'number DESC', :conditions => {:open => true}
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
    if @ticket.save
      flash[:notice] = 'Ticket guardado con éxito'
      redirect_to :tickets
    else
      new
      render :new
    end
  end

  def update
    @ticket = Ticket.find params[:id]
    @ticket.update_attributes(params[:ticket])
    if @ticket.save
      flash[:notice] = 'Ticket guardado con éxito'
      redirect_to :tickets
    else
      edit
      render :edit
    end
  end

  def destroy
    @ticket = Ticket.find params[:id]
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
        flash[:notice] = "El ticket no se ha podido eliminar"
      end
    end
    redirect_to :tickets
  end
end
