  METHOD get_default_values.

    DATA lv_attrnam TYPE string.
    FIELD-SYMBOLS <fieldvalue> TYPE any.
    DATA lo_typedescr TYPE REF TO cl_abap_typedescr.
    DATA lo_desc TYPE REF TO cl_abap_typedescr.

    lo_typedescr = cl_abap_typedescr=>describe_by_data( cs_zielstr ).
    DATA(name) = lo_typedescr->get_relative_name( ).
    SELECT * INTO TABLE @DATA(lt_dflt) FROM  ysdws_dflt_value
           WHERE  caller      = @ycl_sdws_interface_all=>mo_instance->mv_caller
           AND    strname     = @name.



    LOOP AT lt_dflt ASSIGNING FIELD-SYMBOL(<dflt>).
      UNASSIGN <fieldvalue>.

      ASSIGN COMPONENT <dflt>-fieldname OF STRUCTURE cs_zielstr TO <fieldvalue>.
      CHECK <fieldvalue> IS ASSIGNED.
      IF <dflt>-setkz = abap_true.
        <fieldvalue> = <dflt>-fieldvalue.
      ELSEIF <fieldvalue> IS INITIAL.
        <fieldvalue> = <dflt>-fieldvalue.
      ENDIF.

      CHECK cs_zielstrx IS SUPPLIED. "IS BOUND.
      UNASSIGN <fieldvalue>.
      ASSIGN COMPONENT <dflt>-fieldname OF STRUCTURE  cs_zielstrx TO <fieldvalue>.
      CHECK <fieldvalue> IS ASSIGNED.
      <fieldvalue> = abap_true.

    ENDLOOP.

  ENDMETHOD.
