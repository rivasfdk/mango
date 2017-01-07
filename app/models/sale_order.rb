class SaleOrder < ActiveRecord::Base
  attr_protected :id

  belongs_to :client

  def to_collection_select
    "#{self.code}"
  end

  def self.import(files)
    sharepath = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['share_path']
      orders = []
      files.each do |file|
        file = file.downcase
        if file.include? "orden_venta"
          purchasesordersap = File.open(sharepath+file).readlines
          purchasesordersap.each do |line|
            keys = ["order_type","order_code","position","content","mat_code","mat_name","quantity","sack","total_weight","client_code","client_name","client_address","client_rif","client_phone","doc_type","doc_number"]
            line = line.chomp
            values = line.split(';')
            order = keys.zip(values).to_h
            orders.push(order)
          end
        end
      end
      return orders
  end

  def self.create_orders(salesorders)
    salesorders.each do |sales|
      content = sales["content"].downcase == 'm' ? true : false
      if content
        if Ingredient.where(code: sales["mat_code"]).empty?
          Ingredient.create code: sales["mat_code"],
                            name: sales["mat_name"]
          ingredient = Ingredient.where(code: sales["mat_code"])
          Lot.create code: sales["mat_code"],
                     ingredient_id: ingredient[0].id,
                     density: 1
        end
      else
        if Product.where(code: sales["mat_code"]).empty?
          Product.create code: sales["mat_code"],
                         name: sales["mat_name"]
          product = Product.where(code: sales["mat_code"])
          ProductLot.create code: sales["mat_code"],
                            product_id: product[0].id
        end
      end
      if Client.where(code: sales["client_code"]).empty?
        Client.create code: sales["client_code"],
                      name: sales["client_name"],
                      ci_rif: sales["client_rif"],
                      address: sales["client_address"],
                      tel1: sales["client_phone"]
      end
      client = Client.where(code: sales["client_code"])
      if DocumentType.where(name: sales["doc_type"]).empty?
        DocumentType.create name: sales["doc_type"]
      end
      document = DocumentType.where(name: sales["doc_type"])
      sack = sales["sack"].downcase == 's' ? true : false
      if SaleOrder.where(code: sales["order_code"]).empty?
        SaleOrder.create code: sales["order_code"],
                         order_type: sales["order_type"],
                         client_id: client[0].id,
                         document_type_id: document[0].id,
                         document_number: sales["doc_number"],
                         closed: false
      end
      if content
        content_type = Ingredient.where(code: sales["mat_code"])
      else
        content_type = Product.where(code: sales["mat_code"])
      end
      sale_order_act = SaleOrder.where(code: sales["order_code"])
      if SaleOrderItems.where(sale_order_id: sale_order_act[0].id, 
                                  position: sales["position"]).empty?
      SaleOrderItems.create sale_order_id: sale_order_act[0].id,
                            position:sales["position"],
                            content_type: content,
                            content_id: content_type[0].id,
                            quantity:sales["quantity"],
                            sack:sack,
                            total_wheight: sales["total_weight"]
      end
    end
  end

end
