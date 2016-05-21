# encoding: UTF-8

class TransactionsController < ApplicationController
  def index
    @transactions = Transaction.includes(:user, :transaction_type)
      .paginate(page: params[:page], per_page: session[:per_page])
      .order('id desc')
  end

  def new
    @transaction_types = TransactionType.all
    @lots = Lot.where :active => true
    @products_lots = ProductLot.where :active => true
    @clients = Client.all
  end

  def create
    ttype = TransactionType.find params[:transaction][:transaction_type_id]
    granted = User.find(session[:user_id]).has_module_permission?('transactions', ttype.code)
    if granted
      @transaction = Transaction.new
      @transaction.transaction_type_id = params[:transaction][:transaction_type_id]
      content_type = (params[:content_type] == 'ingredient') ? 1 : 2
      @transaction.content_type = content_type
      if @transaction.content_type == 1
        @transaction.content_id = params[:transaction][:lot_id]
      elsif @transaction.content_type == 2
        @transaction.content_id = params[:transaction][:product_lot_id]
      end
      @transaction.amount = params[:transaction][:amount]
      last_document_number = Transaction.where('document_number is not null').last.document_number
      @transaction.document_number = last_document_number.succ
      @transaction.comment = params[:transaction][:comment]
      @transaction.user_id = session[:user_id]
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
end
