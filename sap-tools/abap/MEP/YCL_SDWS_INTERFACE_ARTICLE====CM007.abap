  METHOD map_import.


*    DATA ls_vtweg TYPE LINE OF ycl_sdws_interface_all=>tty_sel_vtweg.
*    DATA ls_vkorg TYPE LINE OF ycl_sdws_interface_all=>tty_sel_vkorg.

    DATA ls_matnr TYPE LINE OF ycl_sdws_interface_all=>tty_sel_matnr.

    LOOP AT is_import-it_selopt ASSIGNING FIELD-SYMBOL(<sel>).

      ASSIGN COMPONENT <sel>-qualif OF STRUCTURE ms_import TO FIELD-SYMBOL(<fs>).
      CHECK <fs> IS ASSIGNED.

      <fs> = <sel>-fvalue.
      UNASSIGN <fs>.
    ENDLOOP.


  ENDMETHOD.
