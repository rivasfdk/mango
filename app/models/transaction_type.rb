class TransactionType < ActiveRecord::Base
  attr_protected :id

  has_many :transactions

  validates_uniqueness_of :code
  validates_presence_of :code, :description, :sign

  after_save :create_permission
  after_destroy :destroy_permission

  private

  def create_permission
    p = Permission.create({:name=>"Transaction '#{self.description}'", :module=>'transactions', :action=>self.code, :mode=>'module'})
  end

  def destroy_permission
    begin
      p = Permission.where({:module=>'transactions', :action=>self.code, :mode=>'module'}).first
      p.destroy
    rescue
    end
  end
end
