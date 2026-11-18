*&---------------------------------------------------------------------*
*& Report  YSDWS_TEST_CMD
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT ysdws_test_cmd.

DATA gs_i_master_data TYPE cmds_ei_main.
DATA gs_e_master_data TYPE cmds_ei_main.
DATA gs_error TYPE cvis_message.
DATA gs_master_data_correct	TYPE cmds_ei_main.
DATA gs_message_correct	TYPE cvis_message.
DATA gs_master_data_defective	TYPE cmds_ei_main.
DATA gs_message_defective	TYPE cvis_message.
DATA gs_yknka LIKE knka.
DATA gs_yknkk LIKE knkk.

PARAMETERS p_kunnr TYPE kna1-kunnr DEFAULT '0010010180'.

START-OF-SELECTION.

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

  lv_objectkey = p_kunnr.

  " Get Class Type and Object Table for this Characteristic
  SELECT SINGLE klart obtab FROM tcla
  INTO (lv_classtype , lv_objecttable)
  WHERE klart = '011'.
  IF sy-subrc NE 0 .
    RETURN.
  ENDIF.

  " Get the Class Num of Characteristic
  SELECT SINGLE class FROM klah
  INTO lv_classnum
  WHERE klart = '011'.
  IF sy-subrc NE 0 .
    RETURN.
  ENDIF.

  " Check if this Characteristic exist : Update or Creation ?
  CALL FUNCTION 'BAPI_OBJCL_GETDETAIL'
    EXPORTING
      objectkey       = lv_objectkey
      objecttable     = lv_objecttable
      classnum        = lv_classnum
      classtype       = lv_classtype
    IMPORTING
      status          = lv_status
      standardclass   = lv_standardclass
    TABLES
      allocvaluesnum  = lt_allocvaluesnum
      allocvalueschar = lt_allocvalueschar
      allocvaluescurr = lt_allocvaluescurr
      return          = lt_return.


  DATA : ls_cust TYPE cmds_ei_extern.
  ls_cust-header-object_instance-kunnr =  p_kunnr.
  ls_cust-header-object_task = 'M'.

  APPEND ls_cust TO gs_i_master_data-customers.

  cmd_ei_api_extract=>get_data(
    EXPORTING
      is_master_data = gs_i_master_data    " Ext. Schnittstelle:
    IMPORTING
      es_master_data = gs_e_master_data    " Ext. Schnittstelle:
    es_error       =  gs_error   " Fehlerindikator und Systemnachrichten
).


  TRY.
      DATA(header) = gs_e_master_data-customers[ 1 ]-header.
      header-object_instance-kunnr = space.
      header-object_task = 'I'.

      TRY.
          DATA(central_data)  = gs_e_master_data-customers[ 1 ]-central_data.
          central_data-address-task = 'I'.
          LOOP AT central_data-contact-contacts ASSIGNING FIELD-SYMBOL(<contact>).
            <contact>-task = 'I'.
            CLEAR <contact>-data_key.
          ENDLOOP.
          central_data-tax_ind-tax_ind[ 1 ]-task = 'I'.

        CATCH cx_sy_itab_line_not_found.
      ENDTRY.
      TRY.
          DATA(company_data)  = gs_e_master_data-customers[ 1 ]-company_data.
          company_data-company[ 1 ]-task = 'I'.
          company_data-company[ 1 ]-dunning-dunning[ 1 ]-task = 'I'.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

      TRY.
          DATA(sales_data)  = gs_e_master_data-customers[ 1 ]-sales_data.
          sales_data-sales[ 1 ]-task = 'I'.
          LOOP AT sales_data-sales[ 1 ]-functions-functions
            ASSIGNING FIELD-SYMBOL(<function>).
            <function>-task = 'I'.
            CLEAR <function>-data.

          ENDLOOP.
        CATCH cx_sy_itab_line_not_found.
      ENDTRY.

    CATCH cx_sy_itab_line_not_found.
  ENDTRY.

  CLEAR gs_i_master_data.
  gs_i_master_data-customers = VALUE #( ( header = header central_data = central_data company_data = company_data sales_data = sales_data ) ).

  CALL METHOD cmd_ei_api=>initialize.

  CALL METHOD cmd_ei_api=>maintain_bapi(
    EXPORTING
*     iv_test_run              = iv_test_run
      iv_collect_messages      = 'X'
      is_master_data           = gs_i_master_data
    IMPORTING
      es_master_data_correct   = gs_master_data_correct
      es_message_correct       = gs_message_correct
      es_master_data_defective = gs_master_data_defective
      es_message_defective     = gs_message_defective ).

  IF gs_message_correct-is_error IS INITIAL.

    SELECT SINGLE * FROM knka
     WHERE kunnr = @p_kunnr
      INTO @DATA(ls_knka).
    IF sy-subrc EQ 0.
      SELECT * FROM knkk
       WHERE  kunnr = @p_kunnr
        INTO TABLE @DATA(lt_knkk).

      LOOP AT lt_knkk ASSIGNING FIELD-SYMBOL(<knkk>).
        ls_knka-kunnr = gs_master_data_correct-customers[ 1 ]-header-object_instance-kunnr.
        <knkk>-kunnr = gs_master_data_correct-customers[ 1 ]-header-object_instance-kunnr.
        CALL FUNCTION 'CREDITLIMIT_CHANGE'  "UPDATE/INSERT des Kreditlimits
          EXPORTING
            i_knka   = ls_knka
            i_knkk   = <knkk>
            upd_knka = 'I'
            upd_knkk = 'I'
*           xneua    = SPACE    " Kennzeichen: Nur Kreditlimit neu aufbauen?
*           xrefl    = SPACE
            yknka    = gs_yknka
            yknkk    = gs_yknkk.
      ENDLOOP.
    ENDIF.

    lv_objectkey = gs_master_data_correct-customers[ 1 ]-header-object_instance-kunnr.


* call function 'CLFM_OBJECT_CLASSIFICATION'.


    " Update Characteristic Value in Sap
    CALL FUNCTION 'BAPI_OBJCL_CREATE' "DESTINATION 'NONE'
      EXPORTING
        objectkeynew    = lv_objectkey
        objecttablenew  = lv_objecttable
        classnumnew     = lv_classnum
        classtypenew    = lv_classtype
      TABLES
        allocvaluesnum  = lt_allocvaluesnum
        allocvalueschar = lt_allocvalueschar
        allocvaluescurr = lt_allocvaluescurr
        return          = lt_return.



    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT' .




  ENDIF.
