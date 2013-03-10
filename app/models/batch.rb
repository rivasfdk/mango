class Batch < ActiveRecord::Base
  belongs_to :order
  belongs_to :schedule
  belongs_to :user
  has_many :batch_hopper_lot

  validates_uniqueness_of :order_id, :scope => [:number]
  validates_presence_of :order, :schedule, :user, :start_date, :end_date
  validates_numericality_of :number, :only_integer => true, :greater_than_or_equal_to => 0
  validates_associated :order, :schedule, :user

  before_validation :check_associations

  def check_associations
    if order_id.kind_of?(Integer) && !Order.exists?(order_id)
      errors[:order_id] << "doesn't exist"
    end
    if schedule_id.kind_of?(Integer) && !Schedule.exists?(schedule_id)
      errors[:schedule_id] << "doesn't exist"
    end
    if user_id.kind_of?(Integer) && !User.exists?(user_id)
      errors[:user_id] << "doesn't exist"
    end
  end

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
    @batches = @batches.includes(:order).where('orders.code = ?', params[:order_code]) if params[:order_code].present?
    @batches.paginate :page => params[:page], :per_page => params[:per_page]
  end
end
