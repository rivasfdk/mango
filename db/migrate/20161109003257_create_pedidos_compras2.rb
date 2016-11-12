class CreatePedidosCompras2 < ActiveRecord::Migration
  def change
    create_table :pedidos_compras2 do |t|
      t.string :num_orden
      t.integer :num_posicion
      t.string :cod_material
      t.float :can_bruto
      t.float :can_neto
      t.float :can_tara
      t.string :pla_camion
      t.string :ced_chofer
      t.string :num_almacen

      t.timestamps
    end
  end
end
