  METHOD set_data.

    LOOP AT it_source ASSIGNING FIELD-SYMBOL(<source>).

      ASSIGN COMPONENT <source>-qualif OF STRUCTURE cs_target TO FIELD-SYMBOL(<target>).
      IF <target> IS ASSIGNED.
        TRY.
            <target> = <source>-fvalue.
          CATCH cx_root.
        ENDTRY.
      ENDIF.
      UNASSIGN <target>.
    ENDLOOP.

  ENDMETHOD.
