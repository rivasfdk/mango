# encoding: UTF-8

class SessionsController < ApplicationController
  skip_before_filter :check_authentication
  layout 'login'

  def index
    redirect_to :action=>'show' if session[:user_id]
  end

  def show
    if session[:user_id]
      @critical_ingredients = Ingredient.where(:stock_below_minimum => true).count
      @critical_hoppers = Hopper.where(:stock_below_minimum => true).count
      render :show, :layout => 'dashboard'
    else
      redirect_to :action=>'index'
    end
  end

  def create
    user = User.auth(params[:user][:login], params[:user][:password])
    if user
      session[:user_id] = user.id
      session[:user_name] = user.name
      session[:permissions] = user.get_dashboard_permissions
      session[:reports_permissions] = user.get_reports_permissions
      session[:per_page] = 12
      session[:company] = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['application']
      respond_to do |format|
        format.html do
          redirect_to :action => 'show'
        end
        format.json do
          @user = User.find user.id
          render :json => @user, :methods => [:allow_manual],  :except => [:password_hash, :password_salt]
        end
        format.xml do
          render xml: {success: true, user_name: user.name}
        end
      end
    else
      respond_to do |format|
        format.html do
          flash[:notice] = 'Credenciales inválidas'
          flash[:type] = 'error'
          redirect_to :action => 'index'
        end
        format.json { head :unauthorized }
        format.xml do
          render xml: {success: false}
        end
      end
    end
  end

  def destroy
    session[:user_id] = nil
    session[:per_page] = nil
    session[:company] = nil
    redirect_to :action=>'index'
  end

  def not_implemented
    flash[:notice] = "Esa funcionalidad aún no está implementada"
    flash[:type] = 'warn'
    redirect_to :action => :show
  end

  private

  def select_layout
    session[:user_id].nil? ? 'login': 'dashboard'
  end
end
