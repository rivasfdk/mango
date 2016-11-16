class SaleOrder < ActiveRecord::Base
  attr_protected :id

  belongs_to :client

  def to_collection_select
    "#{self.code}"
  end

  def self.import
    sale_ord = PedidoVentas.all
    sale_ord.each do |sales|
      content = sales.tip_material.downcase == 'm' ? true : false
      if content
        if Ingredient.where(code: sales.cod_material).empty?
          Ingredient.create code: sales.cod_material,
                            name: sales.nom_material
          ingredient = Ingredient.where(code: sales.cod_material)
          Lot.create code: sales.cod_material,
                     ingredient_id: ingredient[0].id,
                     density: 1
        end
      else
        if Product.where(code: sales.cod_material).empty?
          Product.create code: sales.cod_material,
                         name: sales.nom_material
        end
      end
      if Client.where(code: sales.cod_cliente).empty?
        Client.create code: sales.cod_cliente,
                      name: sales.nom_cliente,
                      ci_rif: sales.rif_cliente,
                      address: sales.dir_cliente,
                      tel1: sales.tel_cliente
      end
      client = Client.where(code: sales.cod_cliente)
      if DocumentType.where(name: sales.tip_documento).empty?
        DocumentType.create name: sales.tip_documento
      end
      document = DocumentType.where(name: sales.tip_documento)
      sack = sales.pre_material.downcase == 's' ? true : false
      if SaleOrder.where(code: sales.num_pedido).empty?
        SaleOrder.create code: sales.num_pedido,
                         order_type: sales.tip_pedido,
                         client_id: client[0].id,
                         document_type_id: document[0].id,
                         document_number: sales.num_documento,
                         closed: false
      end
      if content
        content_type = Ingredient.where(code: sales.cod_material)
      else
        content_type = Product.where(code: sales.cod_material)
      end
      sale_order_act = SaleOrder.where(code: sales.num_pedido)
      if SaleOrderItems.where(sale_order_id: sale_order_act[0].id, 
                                  position: sales.pos_pedido).empty?
      SaleOrderItems.create sale_order_id: sale_order_act[0].id,
                            position:sales.pos_pedido,
                            content_type: content,
                            content_id: content_type[0].id,
                            quantity:sales.can_sacos,
                            sack:sack,
                            total_wheight: sales.pes_neto
      end
    end
  end

end
