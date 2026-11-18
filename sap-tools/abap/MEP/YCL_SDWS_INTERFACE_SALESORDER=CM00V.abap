  METHOD set_sysmsg_text.


    DATA ls_bapiret TYPE  bapiret2.

    ls_bapiret-id = sy-msgid.
    ls_bapiret-number = sy-msgno.
    ls_bapiret-message_v1 = sy-msgv1.
    ls_bapiret-message_v2 = sy-msgv2.
    ls_bapiret-message_v3 = sy-msgv3.
    ls_bapiret-message_v4 = sy-msgv4.


    " Aufbereitung der Message in der angeforderten Language
    CALL FUNCTION 'BAPI_MESSAGE_GETDETAIL'
      EXPORTING
        id         = ls_bapiret-id
        number     = sy-msgno
"       language   = iv_langu
        textformat = 'ASC'
*       LINKPATTERN        =
        message_v1 = ls_bapiret-message_v1
        message_v2 = ls_bapiret-message_v2
        message_v3 = ls_bapiret-message_v3
        message_v4 = ls_bapiret-message_v4
*       LANGUAGE_ISO       =
      IMPORTING
        message    = ls_bapiret-message
*       RETURN     =
*         TABLES
*       TEXT       =
      .

    INSERT ls_bapiret INTO mt_returns INDEX 1.

  ENDMETHOD.
