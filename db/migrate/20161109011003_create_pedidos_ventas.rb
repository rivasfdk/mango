class CreatePedidosVentas < ActiveRecord::Migration
  def change
    create_table :pedidos_ventas do |t|
      t.string :tip_pedido
      t.string :num_pedido
      t.integer :pos_pedido
      t.string :tip_material
      t.string :cod_material
      t.string :nom_material
      t.integer :can_sacos
      t.string :pre_material
      t.float :pes_neto
      t.string :cod_cliente
      t.string :nom_cliente
      t.string :dir_cliente
      t.string :rif_cliente
      t.string :tel_cliente
      t.string :tip_documento
      t.string :num_documento

      t.timestamps
    end
  end
end
