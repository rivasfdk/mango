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
    sharepath = get_mango_field('share_path')
      orders = []
      files.each do |file|
        file = file.downcase
        if file.include? "orden_ticket"
          ticketordersap = File.open(sharepath+file).readlines
          ticketordersap.each do |line|
            keys = ["order_type","order_code","position","content_type","content_code",
                    "content_name","lot_code","sack","quantity","total_weight","client_code",
                    "client_name","client_rif","client_address","client_phone",
                    "doc_type","doc_number"]
            line = line.chomp
            values = line.split(';')
            order = keys.zip(values).to_h
            orders.push(order)
          end
          File.delete(sharepath+file)
        end
      end
      return orders
  end

  def self.create_orders(orders)
    count = 0
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
                     density: 1000
        end
      else
        if Product.where(code: order["content_code"]).empty?
          Product.create code: order["content_code"],
                         name: order["content_name"]
        end
        product = Product.where(code: order["content_code"])
        if ProductLot.where(code: order["lot_code"]).empty?
          ProductLot.create code: order["lot_code"],
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
        count += 1
      end
      if content
        content_type = (Lot.find_by code: order["content_code"]).id
      else
        content_type = (ProductLot.find_by code: order["lot_code"]).id
      end
      ticket_order_act = TicketOrder.find_by code: order_code
      if TicketOrderItems.where(ticket_order_id: ticket_order_act.id, 
                                  position: order["position"]).empty?
        TicketOrderItems.create ticket_order_id: ticket_order_act.id,
                              position:order["position"],
                              content_type: content,
                              content_id: content_type,
                              sack:sack,
                              quantity:order["quantity"],
                              total_weight: order["total_weight"],
                              remaining: order["total_weight"]
      end
    end
    return count
  end

  def self.create_transactions(ticket_id)
    if !(Ticket.find ticket_id).id_order.nil?
      order_id = (Ticket.find ticket_id).id_order
      ticket_order = TicketOrder.find order_id, :include => :ticket_orders_items
      transaction_type_id = ticket_order.order_type ? 4 : 5


      if Transaction.where(ticket_id: ticket_id).empty?
        ticket_order.ticket_orders_items.each do |item|
          if item.content_type
            warehouse = Warehouse.find_by(lot_id: item.content_id)
          else
            warehouse = Warehouse.find_by(product_lot_id: item.content_id)
          end

          sack_weight = item.sack ? item.total_weight/item.quantity : 1
          content_type = item.content_type ? 1 : 2
          Transaction.create transaction_type_id: transaction_type_id,
                             user_id: 1,
                             amount: item.remaining,
                             client_id: ticket_order.client_id,
                             ticket_id: ticket_id,
                             sack: item.sack,
                             sack_weight: sack_weight,
                             sacks: item.quantity,
                             document_number: ticket_order.document_number,
                             stock_after: item.remaining,
                             content_id: item.content_id,
                             content_type: content_type,
                             notified: false,
                             warehouse_id: warehouse.nil? ? nil : warehouse.id
        end
      end
    end
  end

  def self.close(ticket)
    if !ticket.id_order.nil?
      order_id = ticket.id_order
      ticket_order = TicketOrder.find order_id, :include => :ticket_orders_items
      plate = (Truck.find ticket.truck_id).license_plate
      driver = (Driver.find ticket.driver_id).ci
      sharepath = get_mango_field('share_path')
      tmp_dir = get_mango_field('tmp_dir')

      if ticket_order.order_type
        file = File.open(tmp_dir+"Entrada_Orden_Compra_#{Time.now.strftime "%Y%m%d_%H%M%S"}.txt",'w')
        total_remaining = 0
        ticket.transactions.each do |t|
          if t.content_type == 1
            content_code = (Lot.find t.content_id).code
          else
            content_code = (ProductLot.find t.content_id).code
          end
          net_weight = (ticket.incoming_weight-ticket.outgoing_weight).abs
          item = TicketOrderItems.find_by ticket_order_id: ticket_order.id, content_id: t.content_id
          position = item.position
          warehouse = Warehouse.find(t.warehouse_id)
          file.puts "#{ticket_order.code[2..ticket_order.code.length]};#{position};"+
                    "#{content_code};#{ticket.incoming_weight};#{net_weight};"+
                    "#{ticket.outgoing_weight};#{plate};#{driver};#{warehouse.code}\r\n"
          new_remaining = item.remaining - net_weight
          if new_remaining <= 0
            TicketOrderItems.update(item.id, :remaining => 0)
          else
            TicketOrderItems.update(item.id, :remaining => new_remaining)
          end
          total_remaining = total_remaining + new_remaining
        end

        if total_remaining <= 0
          TicketOrder.update(ticket_order.id, :closed => true)
        end
        file.close
      else
        file = File.open(tmp_dir+"traslado_#{Time.now.strftime "%Y%m%d_%H%M%S"}.txt",'w')
        ticket.transactions.each do |t|
          if t.content_type == 1
            lot = Lot.find t.content_id.code
            content = Ingredient.find lot.ingredient_id
          else
            lot = ProductLot.find t.content_id
            content = Product.find lot.product_id
          end
          net_weight = (ticket.incoming_weight-ticket.outgoing_weight).abs
          warehouse = Warehouse.find(t.warehouse_id)
          if warehouse.warehouse_types.sack?
            wh_code = warehouse.warehouse_types.code
          else
            wh_code = warehouse.code
          end
          file.puts "#{ticket_order.code[2..ticket_order.code.length]};"+
                    "#{content.code};#{net_weight};"+
                    "#{wh_code};#{lot.code}\r\n"
        end
        TicketOrder.update(ticket_order.id, :closed => true)
        file.close
      end
      files = Dir.entries(tmp_dir)
        files.each do |f|
          if f.downcase.include? "entrada_orden_compra" or "traslado"
            begin
              FileUtils.mv(tmp_dir+f, sharepath)
            rescue
              puts "++++++++++++++++++++"
              puts "+++ error de red +++"
              puts "++++++++++++++++++++"
            end
          end
        end
    end
    if WarehouseTransactions.find_by(ticket_id: ticket.id).nil?
      ticket.transactions.each do |t|
        content_type = t.content_type == 1 ? true : false
        if content_type
          content_code = (Lot.find t.content_id).code
        else
          content_code = (ProductLot.find t.content_id).code
        end
        net_weight = (ticket.incoming_weight-ticket.outgoing_weight).abs
        warehouse = Warehouse.find(t.warehouse_id)

        actual_stock = warehouse.stock
        if actual_stock < 0
          actual_stock = 0
        end
        if ticket.ticket_type_id == 1
          stock_after = actual_stock + net_weight
        else
          stock_after = actual_stock - net_weight
        end
        if stock_after < 0
          stock_after = 0
        end

        warehouse.update_attributes(stock: stock_after)
        WarehouseTransactions.create transaction_type_id: ticket.ticket_type_id == 1 ? 4 : 5,
                                     warehouse_id: t.warehouse_id,
                                     amount: net_weight,
                                     stock_after: stock_after,
                                     lot_id: t.content_id,
                                     content_type: t.content_type,
                                     user_id: ticket.user_id,
                                     ticket_id: ticket.id
      end
    end
  end


end
