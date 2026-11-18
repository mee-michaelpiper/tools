  METHOD fetch_maepv.



    DATA l_mtcom TYPE mtcom.
    DATA l_mtcor TYPE mtcor.
    DATA l_msg   TYPE daag_s_t100_message.
    DATA l_maepv TYPE maepv.

    clear ms_maepv.
    l_mtcom = CORRESPONDING #( is_mtcom ).
    l_mtcom-kenng = 'MAEPV'.
    l_mtcom-spras = sy-langu.

    CALL FUNCTION 'MATERIAL_READ'
      EXPORTING
        schluessel         = l_mtcom
      IMPORTING
        matdaten           = ms_maepv
        return             = l_mtcor
      EXCEPTIONS
        material_not_found = 1
        plant_not_found    = 2.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        INTO DATA(mtext)
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.


      RAISE EXCEPTION TYPE ycx_sdws_interface.
    ENDIF.




    rs_maepv = ms_maepv.
  ENDMETHOD.
