  METHOD get_default_values.

    DATA lv_attrnam TYPE string.
    FIELD-SYMBOLS <fieldvalue> TYPE any.

    SELECT * INTO TABLE @DATA(lt_dflt) FROM  ysdws_dflt_value
           WHERE  caller      = @mv_caller
           AND    strname     = @iv_strname.

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
