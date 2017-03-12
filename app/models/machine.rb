class Machine < ActiveRecord::Base
  attr_protected :id
  belongs_to :location

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :code, :name, length: {within: 3..40}
  validates :hours, numericality: {greater_than_or_equal_to: 0}

  def eliminate
    begin
      self.destroy
    rescue ActiveRecord::StatementInvalid => ex
      puts ex.inspect
      errors.add(:foreign_key, 'no se puede eliminar porque tiene registros asociados')
    rescue Exception => ex
      errors.add(:unknown, ex.message)
    end
  end
end
