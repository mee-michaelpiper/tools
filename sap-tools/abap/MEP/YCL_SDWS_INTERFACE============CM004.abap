  METHOD fetch_maapv.

    DATA l_mtcom TYPE mtcom.
    DATA l_msg   TYPE daag_s_t100_message.
    DATA l_maapv TYPE maapv.

    l_mtcom = CORRESPONDING #( is_mtcom ).


    l_mtcom-kenng = 'MAAPV'.
    l_mtcom-spras = sy-langu.
    clear ms_maapv.

    CALL FUNCTION 'MATERIAL_READ'
      EXPORTING
        schluessel           = l_mtcom
      IMPORTING
        matdaten             = ms_maapv
      EXCEPTIONS
        account_not_found    = 1
        batch_not_found      = 2
        forecast_not_found   = 3
        lock_on_account      = 4
        lock_on_material     = 5
        lock_on_plant        = 6
        lock_on_sales        = 7
        lock_on_sloc         = 8
        lock_on_batch        = 9
        lock_system_error    = 10
        material_not_found   = 11
        plant_not_found      = 12
        sales_not_found      = 13
        sloc_not_found       = 14
        slocnumber_not_found = 15
        sloctype_not_found   = 16
        text_not_found       = 17
        unit_not_found       = 18
        invalid_mch1_matnr   = 19
        invalid_mtcom        = 20
        sa_material          = 21
        wv_material          = 22
        waart_error          = 23
        t134m_not_found      = 24
        OTHERS               = 25.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        INTO DATA(mtext)
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.


      RAISE EXCEPTION TYPE ycx_sdws_interface.
    else.
     rs_maapv = ms_maapv.
    ENDIF.


    .


    rs_maapv = ms_maapv.
  ENDMETHOD.
