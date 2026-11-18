  METHOD convert_2base64.

    DATA bindata TYPE xstring.
    DATA filesize  TYPE i.
    DATA lv_string TYPE string.
    DATA header TYPE thead.
    DATA options TYPE itcpo.
    DATA result TYPE itcpp.
    DATA textlines TYPE text_lines.
    DATA textlmsg TYPE text_lines.
    DATA otf TYPE STANDARD TABLE OF itcoo.
    DATA textname  TYPE thead-tdname VALUE 'YSD_INTERFACE_MESSAGE'.
    DATA id        TYPE thead-tdid VALUE 'ST'.
    DATA language TYPE thead-tdspras.
    DATA ls_t100_key TYPE scx_t100key.
    DATA ls_print_params  TYPE  pri_params.

    CALL FUNCTION 'GET_PRINT_PARAMETERS'
      EXPORTING
        mode                   = 'CURRENT' "l_print_param_mode
        no_dialog              = 'X'
      IMPORTING
        out_parameters         = ls_print_params
*       valid                  = ls_valid
      EXCEPTIONS
        archive_info_not_found = 1
        invalid_print_params   = 2
        invalid_archive_params = 3
        OTHERS                 = 4.

    IF sy-subrc NE 0.
      set_msg_fields( IMPORTING  es_msg_fields = ls_t100_key ).
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ls_t100_key.

    ENDIF.

    options-tdcopies   = ls_print_params-prcop.
    options-tddest   = ls_print_params-pdest.
    options-tddataset	= 'SCRIPT'.
    options-tdsuffix1	= 'LP01'.
    options-tdsuffix2	= sy-uname.
    options-tdlifetime = 1.
    options-tdarmod	= 1.
    options-tdgetotf = 'X'.

    language = sy-langu.

* read text from database
    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        language  = language
        name      = textname
        object    = 'TEXT'
        id        = id
      IMPORTING
        header    = header
      TABLES
        lines     = textlines
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.

    IF sy-subrc NE 0.
      set_msg_fields( IMPORTING  es_msg_fields = ls_t100_key ).
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ls_t100_key.

    ENDIF.
* Meldungen in Textline hinzufügen
    IF iv_bindata IS SUPPLIED.
      bindata = iv_bindata.
    ENDIF.

    IF iv_bapimsg IS SUPPLIED.
      splitt_string2tab(
         EXPORTING
           iv_string = iv_bapimsg
         IMPORTING
          rt_components = textlmsg  ).

      APPEND LINES OF textlmsg TO textlines.
*      lv_string = iv_bapimsg.
*      bindata = bindata && cl_bcs_convert=>string_to_xstring( lv_string ).
    ENDIF.

    LOOP AT it_returns ASSIGNING FIELD-SYMBOL(<retrun>).
*      lv_string = <retrun>-message.
*      bindata = bindata && cl_bcs_convert=>string_to_xstring( lv_string ).
      splitt_string2tab(
         EXPORTING
           iv_string = <retrun>-message
         IMPORTING
          rt_components = textlmsg  ).

      APPEND LINES OF textlmsg TO textlines.
    ENDLOOP.

*  print text using GETOTF = 'X'
    CALL FUNCTION 'PRINT_TEXT'
      EXPORTING
        device        = 'PRINTER'
        dialog        = ' '
        header        = header
        options       = options
      IMPORTING
        result        = result
      TABLES
        lines         = textlines
        otfdata       = otf
      EXCEPTIONS
        canceled      = 01
        device        = 02
        form          = 03
        options       = 04
        unclosed      = 05
        unknown       = 06
        format        = 07
        textformat    = 08
        communication = 09.

    IF sy-subrc NE 0.
      set_msg_fields( IMPORTING  es_msg_fields = ls_t100_key ).
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ls_t100_key.

    ENDIF.

* convert to PDF
    CALL FUNCTION 'CONVERT_OTF'
      EXPORTING
        format                = 'PDF'
      IMPORTING
        bin_filesize          = filesize
        bin_file              = bindata
      TABLES
        otf                   = otf
        lines                 = textlines
      EXCEPTIONS
        err_conv_not_possible = 1
        err_bad_otf           = 2.

    IF sy-subrc NE 0.
      set_msg_fields( IMPORTING  es_msg_fields = ls_t100_key ).
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ls_t100_key.
    ENDIF.

    CALL FUNCTION 'SSFC_BASE64_ENCODE'
      EXPORTING
        bindata = bindata
*       binleng = iv_binleng
      IMPORTING
        b64data = rv_b64data.

    IF sy-subrc NE 0.
      set_msg_fields( IMPORTING  es_msg_fields = ls_t100_key ).
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ls_t100_key.
    ENDIF.

  ENDMETHOD.
