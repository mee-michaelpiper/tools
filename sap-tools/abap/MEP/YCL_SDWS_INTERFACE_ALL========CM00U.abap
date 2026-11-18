  METHOD GET_DESCRIPTION.
    DATA: lv_tabname    TYPE dd08l-tabname,
          lv_checktable TYPE dd08l-checktable,
          lt_dfies      TYPE STANDARD TABLE OF dfies,
          lv_spras      TYPE spras,
          fieldname     TYPE  dfies-lfieldname,
          lv_where      TYPE string.

    FIELD-SYMBOLS: <ls_dfies> TYPE dfies.

    lv_spras = sy-langu.
    clear es_values.
    es_values-vakey = iv_vakey.
    es_values-qualif = iv_fieldname && 'T'.

    CHECK iv_value NE space.

*    SELECT SINGLE tabname FROM dd08l
*     INTO lv_tabname
*   WHERE checktable = iv_tabname
*     AND fieldname  = iv_fieldname
*     AND frkart     = 'TEXT'.
    SELECT tabname FROM dd08l                 "FISJL20200429  OSS336178 HANADB
     INTO lv_tabname  UP TO 1 ROWS
      WHERE checktable = iv_tabname
       AND fieldname  = iv_fieldname
       AND frkart     = 'TEXT' ORDER BY PRIMARY KEY.
    ENDSELECT.
    IF NOT sy-subrc IS INITIAL.
*      SELECT SINGLE checktable FROM dd08l
*        INTO lv_checktable
*      WHERE tabname   = iv_tabname
*        AND fieldname = iv_fieldname
*        AND frkart    = 'REF'.
      SELECT checktable FROM dd08l            "FISJL20200429  OSS336178 HANADB
        INTO lv_checktable UP TO 1 ROWS
      WHERE tabname   = iv_tabname
        AND fieldname = iv_fieldname
        AND frkart    = 'REF' ORDER BY PRIMARY KEY.
      ENDSELECT.
      IF NOT sy-subrc IS INITIAL.

        fieldname = iv_fieldname.
        CALL FUNCTION 'DDUT_TEXT_FOR_VALUE'
          EXPORTING
            tabname       = iv_tabname
            fieldname     = fieldname
*           CALLING_PROGRAM         =
*           STRUCNAME     =
            value         = iv_value
*           VALUE_IS_EXTERNAL       = ' '
*           LANGU         = SY-LANGU
          IMPORTING
            text          = lv_where
*           NOT_UNIQUE    =
*           VALUE_INTERNAL          =
*           TEXT_FIELDS   =
*          CHANGING
*           ADDITIONAL_FIELDS       =
          EXCEPTIONS
            no_ddic_field = 1
            illegal_value = 2
            OTHERS        = 3.
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.

        es_values-fvalue = lv_where.
        EXIT.


      ELSE.
*        SELECT SINGLE tabname FROM dd08l
*          INTO lv_tabname
*      WHERE checktable  = lv_checktable
*        AND fieldname   = iv_fieldname
*        AND frkart      = 'TEXT'.
        SELECT tabname FROM dd08l        "FISJL20200429 OSS36178 HANADB
         INTO lv_tabname  UP TO 1 ROWS
          WHERE checktable  = lv_checktable
          AND fieldname   = iv_fieldname
          AND frkart      = 'TEXT' ORDER BY PRIMARY KEY.
        ENDSELECT.
      ENDIF.
    ENDIF.
    CHECK lv_tabname IS NOT INITIAL.


    CALL FUNCTION 'DDIF_FIELDINFO_GET'
      EXPORTING
        tabname        = lv_tabname
      TABLES
        dfies_tab      = lt_dfies[]
*       FIXED_VALUES   =
      EXCEPTIONS
        not_found      = 1
        internal_error = 2
        OTHERS         = 3.
    IF sy-subrc <> 0.
*  Tabelle existiert nicht
      RETURN.
    ELSE.
      CLEAR lv_where.
      DATA: lv_value TYPE string.
      CONCATENATE ''''  iv_value ''''  INTO lv_value. CONDENSE lv_value NO-GAPS.
      CONCATENATE '(' iv_fieldname '= ' lv_value ')' INTO lv_where SEPARATED BY space.
      CLEAR lv_value.
      "    CONCATENATE '''' sy-langu ''''  INTO lv_value. CONDENSE lv_value NO-GAPS.
      CONCATENATE '''' lv_spras ''''  INTO lv_value. CONDENSE lv_value NO-GAPS.
      CONCATENATE lv_where 'and ( SPRAS = ' lv_value ')' INTO lv_where SEPARATED BY space.
      DELETE lt_dfies WHERE keyflag = abap_true.
      READ TABLE lt_dfies ASSIGNING <ls_dfies> INDEX 1.
    ENDIF.
    FIELD-SYMBOLS <lv_value> TYPE any.
    TRY.
        SELECT SINGLE (<ls_dfies>-fieldname)
          INTO es_values-fvalue
          FROM (lv_tabname)
          WHERE (lv_where).
      CATCH cx_sy_dynamic_osql_error.
        MESSAGE `Wrong WHERE condition!` TYPE 'I'.
    ENDTRY.


  ENDMETHOD.
