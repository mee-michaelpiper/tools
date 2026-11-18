  METHOD fill_bapi_item_customer.

    DATA ls_extensionin    TYPE bapiparex.
    DATA ls_help           TYPE bapiparex_help.
    DATA da_length_bape_vbap TYPE i.
    DATA l_len_value         TYPE i.

    CHECK is_bape_vbap IS NOT INITIAL.

    DATA(ls_bape_vbap) = is_bape_vbap.
    ls_help-structure         = 'BAPE_VBAP'.
    ls_bape_vbap-posnr        = iv_posnr.

*   Länge der BAPE_VBAP feststellen
    DESCRIBE FIELD ls_bape_vbap LENGTH l_len_value IN BYTE MODE.
    da_length_bape_vbap =
       l_len_value DIV cl_abap_char_utilities=>charsize +
       sign( l_len_value MOD cl_abap_char_utilities=>charsize ).

* Daten übertragen * CHECKMAN / UNICODE
    CALL METHOD cl_abap_container_utilities=>fill_container_c
      EXPORTING
        im_value               = ls_bape_vbap
      IMPORTING
        ex_container           = ls_help+30(da_length_bape_vbap)
      EXCEPTIONS
        illegal_parameter_type = 1
        OTHERS                 = 2.


    ls_extensionin            = ls_help.

    APPEND ls_extensionin TO mt_extensionin.


    CLEAR: ls_help, ls_extensionin.
    ls_help-structure        = 'BAPE_VBAPX'.
    DATA(ls_bape_vbapx)      = is_bape_vbapx.

*   Länge der BAPE_VBAPx feststellen
    DESCRIBE FIELD ls_bape_vbapx LENGTH l_len_value IN BYTE MODE.
    da_length_bape_vbap =
       l_len_value DIV cl_abap_char_utilities=>charsize +
       sign( l_len_value MOD cl_abap_char_utilities=>charsize ).

    ls_bape_vbapx-posnr      = iv_posnr.
* Daten übertragen * CHECKMAN / UNICODE
    CALL METHOD cl_abap_container_utilities=>fill_container_c
      EXPORTING
        im_value               = ls_bape_vbapx
      IMPORTING
        ex_container           = ls_help+30(da_length_bape_vbap)
      EXCEPTIONS
        illegal_parameter_type = 1
        OTHERS                 = 2.


    ls_extensionin           = ls_help.
    APPEND ls_extensionin TO mt_extensionin.

  ENDMETHOD.
