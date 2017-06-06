class Driver < ActiveRecord::Base
  attr_protected :id

  has_many :tickets

  validates :name, :ci, presence: true
  validates :ci, uniqueness: {if: :frequent, case_sensitive: false, scope: :frequent}

  validates :ci, length: {within: 3..10}
  validates :name, length: {within: 3..40}

  def to_collection_select
    "#{self.ci} - #{self.name}"
  end

  def self.search(params)
    @drivers = Driver.order("name asc")
    @drivers = @drivers.where(frequent: true)
    @drivers = @drivers.where(id: params["driver_id"]) if params["driver_id"].present?
    @drivers.paginate page: params[:page], per_page: params[:per_page]
  end

end
