  METHOD get_configuration.


    CALL FUNCTION 'VC_I_GET_CONFIGURATION'
      EXPORTING
        instance            = iv_cuobj
      TABLES
        configuration       = rt_conf
      EXCEPTIONS
        instance_not_found  = 1
        internal_error      = 2
        no_class_allocation = 3
        instance_not_valid  = 4
        OTHERS              = 5.

     if sy-subrc ne 0.

     endif.
  ENDMETHOD.
