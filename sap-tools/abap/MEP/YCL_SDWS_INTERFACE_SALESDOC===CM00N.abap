  METHOD set_conf_data.

    LOOP AT it_conf ASSIGNING FIELD-SYMBOL(<conf>).

      DATA(lt_item) = export_to_item(
      EXPORTING
        iv_vakey    = |{ iv_posnr && 'CONF' && sy-tabix }|
        is_quellstr  = <conf>
        iv_strnam    = 'CONF_OUT' ).
      APPEND LINES OF lt_item TO ct_item.
    ENDLOOP.

  ENDMETHOD.
