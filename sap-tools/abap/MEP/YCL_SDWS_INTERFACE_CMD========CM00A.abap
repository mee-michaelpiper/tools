  METHOD objcl_create.

    DATA lv_objectkey   TYPE objnum.
    DATA lt_return          TYPE TABLE OF bapiret2.

    CHECK mv_classtype IS NOT INITIAL.
    lv_objectkey = iv_newkunnr.

    " Update Characteristic Value in Sap
    CALL FUNCTION 'BAPI_OBJCL_CREATE' "DESTINATION 'NONE'
      EXPORTING
        objectkeynew    = lv_objectkey
        objecttablenew  = mv_objecttable
        classnumnew     = mv_classnum
        classtypenew    = mv_classtype
      TABLES
        allocvaluesnum  = mt_allocvaluesnum
        allocvalueschar = mt_allocvalueschar
        allocvaluescurr = mt_allocvaluescurr
        return          = lt_return.

    LOOP AT lt_return ASSIGNING FIELD-SYMBOL(<mess>)
     WHERE type CA 'EA'.
      set_msg_text( <mess> ).
    ENDLOOP.

    CHECK sy-subrc EQ 0.
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>no_data_found
        mv_kunnr = mv_ref_customer
        mv_msgv1 = convert_syst_msgv( text-005 ).

  ENDMETHOD.
