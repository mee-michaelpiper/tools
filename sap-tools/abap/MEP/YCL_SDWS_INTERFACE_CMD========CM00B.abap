  METHOD set_msg_text.

    DATA ls_bapiret TYPE  bapiret2.

    IF is_bapiret IS SUPPLIED.
      ls_bapiret = is_bapiret.
    ELSE.
      ls_bapiret-id = sy-msgid.
      ls_bapiret-number = sy-msgno.
      ls_bapiret-message_v1 = sy-msgv1.
      ls_bapiret-message_v2 = sy-msgv2.
      ls_bapiret-message_v3 = sy-msgv3.
      ls_bapiret-message_v4 = sy-msgv4.
    ENDIF.

    " Aufbereitung der Message in der angeforderten Language
    CALL FUNCTION 'BAPI_MESSAGE_GETDETAIL'
      EXPORTING
        id         = ls_bapiret-id
        number     = ls_bapiret-number
"       language   = iv_langu
        textformat = 'ASC'
*       LINKPATTERN        =
        message_v1 = ls_bapiret-message_v1
        message_v2 = ls_bapiret-message_v2
        message_v3 = ls_bapiret-message_v3
        message_v4 = ls_bapiret-message_v4
*       LANGUAGE_ISO       =
      IMPORTING
        message    = ls_bapiret-message.

    mt_returns = VALUE #( BASE mt_returns ( type = ls_bapiret-type message = ls_bapiret-message ) ).


  ENDMETHOD.
