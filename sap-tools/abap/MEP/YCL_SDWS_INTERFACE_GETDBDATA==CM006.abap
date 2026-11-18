  METHOD GET_INSTANCE.

    IF ro_instance IS NOT BOUND.
      mo_instance = NEW #(  ).
    ENDIF.

    ro_instance = mo_instance.

  ENDMETHOD.
