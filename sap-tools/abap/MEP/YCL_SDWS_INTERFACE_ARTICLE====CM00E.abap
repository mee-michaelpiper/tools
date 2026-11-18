 METHOD READ_MATERIALS.


   SELECT matnr  FROM  mara into table @mt_materials
          WHERE  matnr  in @mt_sel_matnr
           and   ersda in @mt_sel_ersda
           and   laeda in @mt_sel_laeda.




 ENDMETHOD.
