  METHOD constructor.

    SELECT        * INTO TABLE mt_outputfields
     FROM  ysdws_ex
          WHERE  caller   = ycl_sdws_interface_all=>mo_instance->mv_caller
          AND    service  = ycl_sdws_interface_all=>mo_instance->mv_interface." Webshop: Schnittstelle .



  ENDMETHOD.
