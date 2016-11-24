class PurchaseOrder < ActiveRecord::Base
  attr_protected :id

  belongs_to :client

  def to_collection_select
    "#{self.code}"
  end

  def self.import
    pur_ord = PedidoCompras1.all
    pur_ord.each do |purchases|
      if Ingredient.where(code: purchases.cod_material).empty?
        Ingredient.create code: purchases.cod_material,
                          name: purchases.nom_material
        ingredient = Ingredient.where(code: purchases.cod_material)
        Lot.create code: purchases.cod_material,
                   ingredient_id: ingredient[0].id,
                   density: 1
      end
      if Client.where(code: purchases.cod_proveedor).empty?
        Client.create code: purchases.cod_proveedor,
                      name: purchases.nom_proveedor,
                      ci_rif: purchases.rif_proveedor,
                      address: purchases.dir_proveedor,
                      tel1: purchases.tel_proveedor
      end
      client = Client.where(code: purchases.cod_proveedor)
      sack = purchases.pre_material.downcase == 's' ? true : false
      if PurchaseOrder.where(code: purchases.num_orden).empty?
        PurchaseOrder.create code: purchases.num_orden,
                             id_client: client[0].id,
                             closed: false
      end
      ingredient = Ingredient.where(code: purchases.cod_material)
      purchase_order_act = PurchaseOrder.where(code: purchases.num_orden)
      if PurchaseOrderItems.where(id_purchase_order: purchase_order_act[0].id, 
                                  position: purchases.num_posicion).empty?
      PurchaseOrderItems.create id_purchase_order: purchase_order_act[0].id,
                                id_ingredient: ingredient[0].id,
                                position:purchases.num_posicion,
                                quantity:purchases.can_sacos,
                                sack:sack,
                                total_weight: purchases.can_pedido
      end
    end
  end

end