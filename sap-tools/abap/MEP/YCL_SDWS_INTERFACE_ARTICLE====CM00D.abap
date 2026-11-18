  METHOD export_material.

    DATA lt_container TYPE ysdws_comitm_tt.

    rt_item = export_to_item(
      EXPORTING
         iv_vakey =  |{ mv_number_of_documents  && 'CLIENT' }|
        is_quellstr  = mara
        iv_strnam    = 'MARA' ).


    LOOP AT mt_unitsofmeasure ASSIGNING FIELD-SYMBOL(<marm>). " Mengeneinheiten
      lt_container = export_to_item(
      EXPORTING
         iv_vakey =  |{ mv_number_of_documents && 'MARM' && <marm>-MEINH }|
        is_quellstr  = <marm>
        iv_strnam    = 'MARM' ).
      APPEND LINES OF lt_container TO rt_item.
    ENDLOOP.
*    lt_container = export_bapi_extensions(
*    EXPORTING
*      iv_strname = 'BAPI_TE_MARA'
*      iv_vakey   = |{ mv_number_of_documents && 'CLIENT' }| ).
*    APPEND LINES OF lt_container TO rt_item.

    LOOP AT mt_materialdescription ASSIGNING FIELD-SYMBOL(<descr>).
      lt_container = export_to_item(
       EXPORTING
          iv_vakey =  |{ mv_number_of_documents && 'DESCR' && <descr>-spras }|
         is_quellstr  = <descr>
         iv_strnam    = 'MAKT' ).
      APPEND LINES OF lt_container TO rt_item.
    ENDLOOP.

    IF ms_import-plant NE space.
      lt_container = export_to_item(
            EXPORTING
               iv_vakey =  |{ mv_number_of_documents && 'PLANT' && ms_import-plant }|
              is_quellstr  = marc
              iv_strnam    = 'MARC' ).
      APPEND LINES OF lt_container TO rt_item.

*      lt_container = export_bapi_extensions(
*      EXPORTING
*        iv_strname = 'BAPI_TE_MARC'
*        iv_vakey   = |{ mv_number_of_documents && 'PLANT' && ms_import-plant }| ).
*      APPEND LINES OF lt_container TO rt_item.
    ENDIF.

    IF ms_import-salesorganisation NE space.
      lt_container = export_to_item(
            EXPORTING
               iv_vakey =  |{ mv_number_of_documents && 'SALES' && ms_import-salesorganisation }|
              is_quellstr  = mvke
              iv_strnam    = 'MVKE' ).
      APPEND LINES OF lt_container TO rt_item.

*      lt_container = export_bapi_extensions(
*      EXPORTING
*        iv_strname = 'BAPI_TE_MVKE'
*        iv_vakey   = |{ mv_number_of_documents && 'SALES' && ms_import-salesorganisation }| ).
*      APPEND LINES OF lt_container TO rt_item.
    ENDIF.

  ENDMETHOD.
