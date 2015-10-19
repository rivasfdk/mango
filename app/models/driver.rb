class Driver < ActiveRecord::Base
  has_many :tickets

  validates :name, :ci, presence: true
  validates :ci, uniqueness: {if: :frequent, case_sensitive: false}

  validates :ci, length: {within: 3..10}
  validates :name, length: {within: 3..40}

  def to_collection_select
    "#{self.ci} - #{self.name}"
  end
end
