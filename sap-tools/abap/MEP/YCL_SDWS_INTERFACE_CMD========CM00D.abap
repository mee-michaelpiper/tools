  METHOD constructor.
    CALL METHOD super->constructor.
    mv_caller = ycl_sdws_interface_all=>mo_instance->mv_caller.

  ENDMETHOD.
