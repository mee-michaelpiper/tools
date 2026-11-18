  METHOD get_instance.
    IF mo_instance IS NOT BOUND.
      mo_instance = NEW #( is_import ).
    ENDIF.

    ro_instance = mo_instance.
  ENDMETHOD.
