  METHOD CONSTRUCTOR.

    mv_caller = ycl_sdws_interface_all=>mo_instance->mv_caller.

    IF ycl_sdws_interface_all=>mo_instance->mv_set_all_output_data EQ space.
      SELECT        * INTO TABLE mt_outputfields
        FROM  ysdws_ex
             WHERE  caller   = mv_caller
             AND    service  = ycl_sdws_interface_all=>mc_interface_salesdoc." Webshop: Schnittstelle .

    ELSE.
      SELECT tabname AS strname
             fieldname INTO CORRESPONDING FIELDS OF TABLE mt_outputfields FROM  dd03l
 "            WHERE  tabname  IN ('VBPAVB', 'SADRVB')
             WHERE  tabname IN ('BAPISDFLOW','BAPISDHD','BAPISDHEDU','BAPISDIT',
                  'BAPISDHEDU', 'VBPAVB', 'BAPICOND', 'SADRVB', 'BAPE_VBAK', 'BAPE_VBAP',
                'CONF_OUT')
              and INTLEN gt 0.

    ENDIF.
  ENDMETHOD.
