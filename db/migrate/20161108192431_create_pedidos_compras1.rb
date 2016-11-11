class CreatePedidosCompras1 < ActiveRecord::Migration
  def change
    create_table :pedidos_compras1 do |t|
      t.string :num_orden
      t.integer :num_posicion
      t.string :cod_material
      t.string :nom_material
      t.float :can_pedido
      t.string :pre_material
      t.integer :can_sacos
      t.string :cod_proveedor
      t.string :nom_proveedor
      t.string :rif_proveedor
      t.string :dir_proveedor
      t.string :tel_proveedor

      t.timestamps
    end
  end
end
