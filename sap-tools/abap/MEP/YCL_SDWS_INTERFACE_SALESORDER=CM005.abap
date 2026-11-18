  METHOD fill_bapi_header_customer.

    DATA: ls_bape_vbak   TYPE bape_vbak,
          ls_bape_vbakx  TYPE bape_vbakx,
          ls_help        TYPE bapiparex_help,
          ls_extensionin TYPE bapiparex.

    ls_bape_vbak = is_bape_vbak.
    ls_bape_vbakx = is_bape_vbakx.

    CALL METHOD get_default_values
      EXPORTING
        iv_strname  = 'BAPE_VBAK'
        iv_caller   = mv_caller
      CHANGING
        cs_zielstr  = ls_bape_vbak
        cs_zielstrx = ls_bape_vbakx.

    CHECK ls_bape_vbak IS NOT INITIAL.

    ls_help-structure     =  'BAPE_VBAK'.
    ls_help-value         =  ls_bape_vbak.
    ls_extensionin        =  ls_help.
    APPEND ls_extensionin TO mt_extensionin.


    CLEAR: ls_help, ls_extensionin.
    ls_help-structure     = 'BAPE_VBAKX'.
    ls_help-value         = ls_bape_vbakx.                  "#EC *
    ls_extensionin        =  ls_help.
    APPEND ls_extensionin TO mt_extensionin.



  ENDMETHOD.
