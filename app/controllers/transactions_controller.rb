class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.paginate :page=>params[:page], :per_page=>session[:per_page]
  end

  def new
    @transaction_types = TransactionType.all
    @lots = Lot.where :active => true
    @products_lots = ProductLot.where :active => true
    @clients = Client.all
  end

  def edit
    @transaction = Transaction.find params[:id]
    @transaction_types = TransactionType.all
    @lots = Lot.where :active => true
    @products_lots = ProductLot.where :active => true
    @clients = Client.all
  end

  def create
    ttype = TransactionType.find params[:transaction][:transaction_type_id]
    granted = session[:user].has_module_permission?('transactions', ttype.code)
    if granted
      @transaction = Transaction.new
      @transaction.transaction_type_id = params[:transaction][:transaction_type_id]
      content_type = (params[:content_type] == 'ingredient') ? 1 : 2
      @transaction.content_type = content_type
      if @transaction.content_type == 1
        @transaction.content_id = params[:transaction][:lot_id]
      elsif @transaction.content_type == 2:
        @transaction.content_id = params[:transaction][:product_lot_id]
      end
      @transaction.date = Date.today
      @transaction.amount = params[:transaction][:amount]
      @transaction.document_number = params[:transaction][:document_number]
      @transaction.comment = params[:transaction][:comment]
      @transaction.user = session[:user]
      @transaction.processed_in_stock = 1

      if @transaction.save
        flash[:notice] = 'Transacción guardada con éxito'
        redirect_to :transactions
      else
        new
        render :new
      end
    else
      new
      flash[:type] = 'error'
      flash[:notice] = 'No tiene permisos para realizar esa transacción'
      render :new
    end
  end

  def update
    @transaction = Transaction.find params[:id]
    @transaction.update_attributes(params[:transaction])
    if @transaction.save
      flash[:notice] = 'Transacción guardada con éxito'
      redirect_to :transactions
    else
      edit
      render :edit
    end
  end

  def destroy
    @transaction = Transaction.find params[:id]
    @transaction.eliminate
    if @transaction.errors.size.zero?
      flash[:notice] = "Transacción eliminada con éxito"
    else
      logger.error("Error eliminando transacción: #{@transaction.errors.inspect}")
      flash[:type] = 'error'
      if not @transaction.errors[:foreign_key].nil?
        flash[:notice] = 'La transacción no se puede eliminar porque tiene registros asociados'
      elsif not @transaction.errors[:unknown].nil?
        flash[:notice] = @transaction.errors[:unknown]
      else
        flash[:notice] = "La transacción no se ha podido eliminar"
      end
    end
    redirect_to :transactions
  end

  def reprocess
    begin
      Transaction.get_no_processed().each do |t|
        t.process
      end
      flash[:notice] = "Consumos de materia prima procesados exitosamente"
    rescue Exception => e
      puts e.message
      flash[:type] = 'error'
      flash[:notice] = "Ha ocurrido un error procesando los consumos"
    end
    redirect_to :transactions
  end
  
  def download
	start_date = EasyModel.param_to_date(params[:transaction], 'start')
    end_date = EasyModel.param_to_date(params[:transaction], 'end')
	data = Transaction.generate_export_file(start_date, end_date)
	send_data data, :filename => "transacciones.txt", :type => "text/plain"
  end
end
