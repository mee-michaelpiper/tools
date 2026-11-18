METHOD CHECK_FIELDS_IN_VIEW .

  STATICS: lt_dfies TYPE TABLE OF dfies.

  DATA: lt_whitelist TYPE string_hashed_table.
  DATA: lv_field     TYPE string.

  FIELD-SYMBOLS: <ls_dfies> TYPE dfies,
                 <l_field>  TYPE string.

*--- not necessary if no fields in selection table
  IF it_fields IS INITIAL.
    RETURN.
  ENDIF.

*--- if fields are not in buffer - read it
  READ TABLE lt_dfies INDEX 1 ASSIGNING <ls_dfies>.
  IF sy-subrc IS NOT INITIAL OR <ls_dfies>-tabname NE i_viewname.
    CALL FUNCTION 'DDIF_NAMETAB_GET'
      EXPORTING
        tabname   = i_viewname
      TABLES
        dfies_tab = lt_dfies
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.
    IF sy-subrc IS INITIAL.
      SORT lt_dfies BY fieldname.
    ENDIF.
  ENDIF.

*build up whitlist
  LOOP AT lt_dfies ASSIGNING <ls_dfies>.
    lv_field = <ls_dfies>-fieldname.
    INSERT lv_field INTO TABLE lt_whitelist.
  ENDLOOP.

*--- use only fields for selection that are in table
  LOOP AT it_fields ASSIGNING <l_field>.
    READ TABLE lt_dfies TRANSPORTING NO FIELDS
                        WITH KEY fieldname = <l_field>
                        BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      TRY.
          "do check for field in whitelist
          cl_abap_dyn_prg=>check_whitelist_tab(
            EXPORTING
              val       = <l_field>
              whitelist = lt_whitelist ).

        CATCH cx_abap_not_in_whitelist.    " Value is not in the whitelist
          ASSERT 1 = 0.
      ENDTRY.
      APPEND <l_field> TO rt_fields.
    ENDIF.
  ENDLOOP.

ENDMETHOD.
