  METHOD get_log_values_from_structure.

    DATA ls_log_value TYPE ysdws_log_value.
    DATA lo_field_catalog TYPE REF TO cl_abap_structdescr.

    lo_field_catalog ?= cl_abap_structdescr=>describe_by_data( is_structure ).

    DATA(lt_field_list) = lo_field_catalog->get_ddic_field_list( ).

    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE is_structure TO FIELD-SYMBOL(<lv_field_value>).
      IF sy-subrc <> 0.
        EXIT.
      ELSE.
        IF <lv_field_value> IS NOT INITIAL.
          DESCRIBE FIELD <lv_field_value> TYPE DATA(lv_data_type).   " Feld = lv_type = 'C'.
          IF lv_data_type <> 'h'.
            READ TABLE lt_field_list INDEX sy-index ASSIGNING FIELD-SYMBOL(<ls_field_list>).
            IF sy-subrc = 0 AND <ls_field_list>-fieldname <> 'I_SESSIONID'.
              CLEAR ls_log_value.
              ls_log_value-guid           = is_log_time-guid.
              ls_log_value-interface_type = iv_interface_type.
              ls_log_value-tabix          = iv_tabix.
              ls_log_value-structure      = <ls_field_list>-tabname.
              ls_log_value-fieldname      = <ls_field_list>-fieldname.
              IF lv_data_type = 'P'.
                WRITE <lv_field_value> TO ls_log_value-fieldvalue LEFT-JUSTIFIED.
              ELSE.
                ls_log_value-fieldvalue     = <lv_field_value>.
              ENDIF.
              APPEND ls_log_value TO ct_log_value.
            ENDIF.
          ELSE.
            CONTINUE.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDDO.

  ENDMETHOD.
