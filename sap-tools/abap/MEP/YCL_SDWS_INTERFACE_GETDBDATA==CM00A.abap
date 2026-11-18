  METHOD check_ofields.


    SELECT fieldname FROM  dd03l
      INTO TABLE @DATA(lt_components)
           WHERE  tabname    = @ms_import-in-i_tabname
           AND    comptype   = 'E'.


    LOOP AT ct_fields ASSIGNING FIELD-SYMBOL(<selfield>).
      READ TABLE lt_components WITH KEY fieldname = <selfield>-field
       TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>no_data_object
            mv_msgv1 = CONV #( |{ 'Feld:' && <selfield>-field }| ).

      ENDIF.
    ENDLOOP.
    IF sy-subrc NE 0.
      LOOP AT lt_components ASSIGNING FIELD-SYMBOL(<comp>).
        APPEND <comp>-fieldname TO ct_fields.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.
