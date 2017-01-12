include MangoModule

class TicketOrder < ActiveRecord::Base

  attr_protected :id

  belongs_to :client
  belongs_to :document_type

  has_many :tickets
  has_many :ticket_orders_items

  def to_collection_select
    "#{self.code}"
  end

  def self.import(files)
    sharepath = YAML::load(File.open("#{Rails.root.to_s}/config/global.yml"))['share_path']
      orders = []
      files.each do |file|
        file = file.downcase
        if file.include? "orden_ticket"
          ticketordersap = File.open(sharepath+file).readlines
          ticketordersap.each do |line|
            keys = ["order_type","order_code","position","content_type","content_code",
                    "content_name","sack","quantity","total_weight","client_code",
                    "client_name","client_rif","client_address","client_phone",
                    "doc_type","doc_number"]
            line = line.chomp
            values = line.split(';')
            order = keys.zip(values).to_h
            orders.push(order)
          end
        end
      end
      return orders
  end

  def self.create_orders(orders)
    orders.each do |order|
      order_type = order["order_type"].downcase == 'r' ? true : false
      if order_type
        order_code = 'R-'+order["order_code"]
      else
        order_code = 'D-'+order["order_code"]
      end
      content = order["content_type"].downcase == 'm' ? true : false
      if content
        if Ingredient.where(code: order["content_code"]).empty?
          Ingredient.create code: order["content_code"],
                            name: order["content_name"]
          ingredient = Ingredient.where(code: order["content_code"])
          Lot.create code: order["content_code"],
                     ingredient_id: ingredient[0].id,
                     density: 1
        end
      else
        if Product.where(code: order["content_code"]).empty?
          Product.create code: order["content_code"],
                         name: order["content_name"]
          product = Product.where(code: order["content_code"])
          ProductLot.create code: order["content_code"],
                            product_id: product[0].id
        end
      end
      if Client.where(code: order["client_code"]).empty?
        Client.create code: order["client_code"],
                      name: order["client_name"],
                      ci_rif: order["client_rif"],
                      address: order["client_address"],
                      tel1: order["client_phone"]
      end
      client = Client.where(code: order["client_code"])
      if DocumentType.where(name: order["doc_type"]).empty?
        DocumentType.create name: order["doc_type"]
      end
      document = DocumentType.where(name: order["doc_type"])
      sack = order["sack"].downcase == 's' ? true : false
      if TicketOrder.where(code: order_code).empty?
        TicketOrder.create code: order_code,
                         order_type: order_type,
                         client_id: client[0].id,
                         document_type_id: document[0].id,
                         document_number: order["doc_number"],
                         closed: false
      end
      if content
        content_type = (Lot.find_by code: order["content_code"]).id
      else
        content_type = (ProductLot.find_by code: order["content_code"]).id
      end
      ticket_order_act = TicketOrder.where(code: order_code)
      if TicketOrderItems.where(ticket_order_id: ticket_order_act[0].id, 
                                  position: order["position"]).empty?
        TicketOrderItems.create ticket_order_id: ticket_order_act[0].id,
                              position:order["position"],
                              content_type: content,
                              content_id: content_type,
                              sack:sack,
                              quantity:order["quantity"],
                              total_weight: order["total_weight"]
      end
    end
  end

  def self.create_transactions(ticket_id)
    order_id = (Ticket.find ticket_id).id_order
    ticket_order = TicketOrder.find order_id, :include => :ticket_orders_items
    transaction_type_id = ticket_order.order_type ? 4 : 5
    if Transaction.where(ticket_id: ticket_id).empty?
      ticket_order.ticket_orders_items.each do |item|
        sack_weight = item.sack ? item.total_weight/item.quantity : 1
        content_type = item.content_type ? 1 : 2
        Transaction.create transaction_type_id: transaction_type_id,
                           user_id: 1,
                           amount: item.total_weight,
                           client_id: ticket_order.client_id,
                           ticket_id: ticket_id,
                           sack: item.sack,
                           sack_weight: sack_weight,
                           sacks: item.quantity,
                           document_number: ticket_order.document_number,
                           content_id: item.content_id,
                           content_type: content_type,
                           notified: false
      end
    end
  end

end
