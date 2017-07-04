# encoding: UTF-8

class UsersController < ApplicationController
  def index
    if session[:user_id] == 1
      @users = User.order('name ASC').paginate :page=>params[:page], :per_page=>session[:per_page]
    else
      cant = User.all.length
      @users = User.where(id: (2..cant)).order('name ASC').paginate :page=>params[:page], :per_page=>session[:per_page]
    end
  end

  def new
    @roles = Role.get_all
  end

  def edit
    @user = User.find params[:id]
    @roles = Role.get_all
  end

  def create
    @user = User.new params[:user]
    if @user.save
      flash[:notice] = 'Usuario guardado con éxito'
      redirect_to :users
    else
      new
      render :new
    end
  end

  def update
    @user = User.find params[:id]
    @user.update_attributes(params[:user])
    if @user.save
      flash[:notice] = 'Usuario guardado con éxito'
      redirect_to :users
    else
      edit
      render :edit
    end
  end

  def destroy
    @user = User.find params[:id]
    @user.eliminate
    if @user.errors.empty?
      flash[:notice] = "Usuario eliminado con éxito"
    else
      logger.error("Error eliminando usuario: #{@user.errors.inspect}")
      flash[:type] = 'error'
      if not @user.errors[:foreign_key].nil?
        flash[:notice] = 'El usuario no se puede eliminar porque tiene registros asociados'
      elsif not @user.errors[:unknown].nil?
        flash[:notice] = @user.errors[:unknown]
      else
        flash[:notice] = "El usuario no se ha podido eliminar"
      end
    end
    redirect_to :users
  end
end
