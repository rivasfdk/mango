class Batch < ActiveRecord::Base
  belongs_to :order
  belongs_to :schedule
  belongs_to :user
  has_many :batch_hopper_lot

  validates :order_id, uniqueness: {scope: :number}
  validates :order, :schedule, :user, :start_date, :end_date, presence: true
  validates :number, numericality: {only_integer: true, greater_than: 0}

  def self.get_real_batches(order_id)
    return self.where(:order_id => order_id).count
  end

  def self.get_real_total(order_id)
    total = 0
    batches = self.where(:order_id => order_id)
    batches.each do |b|
      b.batch_hopper_lot.each do |bhl|
        total += bhl.amount
      end
    end
    return total
  end

  def calculate_start_date
    start_date = BatchHopperLot.where(:batch_id=>self.id).minimum('created_at')
    unless start_date.nil?
      return start_date.strftime("%d/%m/%Y %H:%M:%S")
    else
      return "??/??/?? ??:??:??"
    end    
  end

  def calculate_end_date
    end_date = BatchHopperLot.where(:batch_id=>self.id).maximum('created_at')
    unless end_date.nil?
      return end_date.strftime("%d/%m/%Y %H:%M:%S")
    else
      return "??/??/?? ??:??:??"
    end
  end

  def self.search(params)
    @batches = Batch.order('batches.id DESC')
    @batches = @batches.includes(:order, :schedule, :user)
    @batches = @batches.where('orders.code = ?', params[:order_code]) if params[:order_code].present?
    @batches.paginate :page => params[:page], :per_page => params[:per_page]
  end
end
