  METHOD map_import.

    LOOP AT is_import-it_selopt ASSIGNING FIELD-SYMBOL(<sel>).

      ASSIGN COMPONENT <sel>-qualif OF STRUCTURE ms_import TO FIELD-SYMBOL(<fvalue>).
      CHECK <fvalue> IS ASSIGNED.
      <fvalue> = <sel>-fvalue.
      UNASSIGN <fvalue>.
    ENDLOOP.

  ENDMETHOD.
