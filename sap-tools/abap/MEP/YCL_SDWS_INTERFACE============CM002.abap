  METHOD convert_ext2int.

    DATA lf_struct TYPE REF TO cl_abap_structdescr.
    DATA lv_fktbst_conv TYPE funcname.

    lf_struct ?= cl_abap_structdescr=>describe_by_data( cs_values ).

    LOOP AT lf_struct->get_ddic_field_list( ) ASSIGNING FIELD-SYMBOL(<info>)
      WHERE convexit NE space.
      CLEAR lv_fktbst_conv.
      CONCATENATE 'CONVERSION_EXIT_' <info>-convexit '_INPUT' INTO lv_fktbst_conv.

      ASSIGN COMPONENT <info>-fieldname OF STRUCTURE cs_values TO FIELD-SYMBOL(<fs_t>).
      CHECK <fs_t> IS ASSIGNED AND <fs_t> IS NOT INITIAL.
      CALL FUNCTION lv_fktbst_conv
        EXPORTING
          input  = <fs_t>
        IMPORTING
          output = <fs_t>
        EXCEPTIONS
          OTHERS = 4.

      UNASSIGN <fs_t>.
    ENDLOOP.

  ENDMETHOD.
