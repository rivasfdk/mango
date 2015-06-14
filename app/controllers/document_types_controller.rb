class DocumentTypesController < ApplicationController
  skip_before_filter :check_permissions, only: [:index]
  def index
    @document_types = DocumentType.all
    render json: @document_types
  end
end
