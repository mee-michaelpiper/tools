  METHOD fetch_detail_objcl.
*    raising YCX_SDWS_INTERFACE.
    DATA: lv_objectkey   TYPE objnum,
          lv_objecttable TYPE tabelle,
          lv_classnum    TYPE klasse_d,
          lv_classtype   TYPE klassenart.

    DATA: lt_allocvaluesnum  TYPE TABLE OF bapi1003_alloc_values_num,
          lt_allocvalueschar TYPE TABLE OF bapi1003_alloc_values_char,
          ls_allocvalueschar LIKE LINE OF lt_allocvalueschar,
          lt_allocvaluescurr TYPE TABLE OF bapi1003_alloc_values_curr,
          lt_return          TYPE TABLE OF bapiret2.

    DATA: lv_status        TYPE clstatus,
          lv_standardclass TYPE stdclass.

    DATA: lt_allocvaluescharnew TYPE TABLE OF bapi1003_alloc_values_char,
          ls_allocvaluescharnew LIKE LINE OF lt_allocvaluescharnew.

    DATA: lt_allocvaluesnumnew  TYPE TABLE OF bapi1003_alloc_values_num,
          lt_allocvaluescurrnew TYPE TABLE OF bapi1003_alloc_values_curr.

    lv_objectkey = mv_ref_customer.

    " Get Class Type and Object Table for this Characteristic
    SELECT SINGLE klart obtab FROM tcla
    INTO (mv_classtype , mv_objecttable)
    WHERE klart = ms_dflt_value-klart.
    IF sy-subrc NE 0 .
      RETURN.
    ENDIF.

    " Get the Class Num of Characteristic
    SELECT SINGLE class FROM klah
    INTO mv_classnum
    WHERE klart = ms_dflt_value-klart.
    IF sy-subrc NE 0 .
      RETURN.
    ENDIF.

    " Check if this Characteristic exist : Update or Creation ?
    CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
      EXPORTING
        objectkey       = lv_objectkey
        objecttable     = mv_objecttable
        classnum        = mv_classnum
        classtype       = mv_classtype
      IMPORTING
        status          = lv_status
        standardclass   = lv_standardclass
      TABLES
        allocvaluesnum  = mt_allocvaluesnum
        allocvalueschar = mt_allocvalueschar
        allocvaluescurr = mt_allocvaluescurr
        return          = lt_return.


  ENDMETHOD.
