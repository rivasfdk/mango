class JavascriptsController < ApplicationController
  def dynamic_clients
    @clients = Client.find :all
  end
end
