class Batch < ActiveRecord::Base
  belongs_to :order
  belongs_to :schedule
  belongs_to :user
  has_many :batch_hopper_lot

  validates :order_id, uniqueness: {scope: :number}
  validates :order, :schedule, :user, :start_date, :end_date, presence: true
  validates :number, numericality: {only_integer: true, greater_than: 0}

  def self.search(params)
    @batches = Batch.order('batches.id DESC')
    @batches = @batches.includes(:order, :schedule, :user)
    @batches = @batches.where('orders.code = ?', params[:order_code]) if params[:order_code].present?
    @batches.paginate page: params[:page], per_page: params[:per_page]
  end
end
