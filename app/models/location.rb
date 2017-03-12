class Location < ActiveRecord::Base
  attr_protected :id
  has_many :machines

  validates :name, :code, presence: true
  validates :name, :code, length: {within: 3..40}
  validates :code, uniqueness: true

  def self.search(params)
    @locations = Location.order("locations.id ASC")
    @locations.paginate page: params[:page], per_page: params[:per_page]
  end
end
