# encoding: UTF-8

class Log < ActiveRecord::Base

    attr_protected :id

    TYPES = {
      1 => 'BATCHES',
      2 => 'ORDENES PRODUCCION',
      3 => 'RECETAS',
      4 => 'RECETAS MEDICAMENTOS',
      5 => 'BALANZAS Y TOLVAS',
      6 => 'MATERIA PRIMA',
      7 => 'PRODUCTO TERMINADO',
      8 => 'LOTES MATERIA PRIMA',
      9 => 'LOTES PRODUCTO TERMINADO',
      10 => 'ALMACENES',
      11 => 'MANTENIMIENTO',
      12 => 'LABORATORIO',
      13 => 'CLIENTES',
      14 => 'MAQUILAS',
      15 => 'TURNOS',
      16 => 'USUARIOS',
      17 => 'ROLES',
      18 => 'REPORTES',
      19 => 'CHOFERES',
      20 => 'EMPRESAS DE TRANSPORTE',
      21 => 'CAMIONES',
      22 => 'TICKETS',
      23 => 'CONFIGURACION',
    }

    belongs_to :user

end
