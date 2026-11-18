  METHOD check_ifields.


    SELECT fieldname FROM  dd03l
      INTO TABLE @DATA(lt_components)
           WHERE  tabname    = @ms_import-in-i_tabname
           AND    comptype   = 'E'.

    LOOP AT ms_import-in-it_selopt ASSIGNING FIELD-SYMBOL(<selfield>).
      READ TABLE lt_components WITH KEY fieldname = <selfield>-qualif
       TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>no_data_object
            mv_msgv1 = CONV #( |{ 'Feld:' && <selfield>-qualif }| ).

      ENDIF.
    ENDLOOP.
  ENDMETHOD.
