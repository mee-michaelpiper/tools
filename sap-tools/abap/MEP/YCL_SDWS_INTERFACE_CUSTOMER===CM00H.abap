METHOD export_bapi_item.

  DATA ls_order_view TYPE order_view.
  DATA lt_order_headers_out	TYPE TABLE OF	bapisdhd.
  DATA lt_order_cond_head   TYPE TABLE OF bapicondhd.
  DATA lt_extensionout      TYPE TABLE OF bapiparex .
  DATA lt_bapisdhdst        TYPE TABLE OF bapisdhdst .
  DATA ls_item     TYPE ysdws_comitm_s.

  ls_order_view-header = abap_true.
  ls_order_view-status_h = abap_true.


  get_salesdocument_db( ).

  CALL FUNCTION 'BAPISDORDER_GETDETAILEDLIST'
    EXPORTING
      i_bapi_view              = ls_order_view
*     I_MEMORY_READ            =
      i_with_header_conditions = 'X'
    TABLES
      sales_documents          = mt_vbl_glt
      order_headers_out        = lt_order_headers_out
*     ORDER_ITEMS_OUT          =
*     ORDER_SCHEDULES_OUT      =
*     ORDER_BUSINESS_OUT       =
*     ORDER_PARTNERS_OUT       =
*     ORDER_ADDRESS_OUT        =
      order_statusheaders_out  = lt_bapisdhdst
*     ORDER_STATUSITEMS_OUT    =
*     ORDER_CONDITIONS_OUT     =
      order_cond_head          = lt_order_cond_head
*     ORDER_COND_ITEM          =
*     ORDER_COND_QTY_SCALE     =
*     ORDER_COND_VAL_SCALE     =
*     ORDER_CONTRACTS_OUT      =
*     ORDER_TEXTHEADERS_OUT    =
*     ORDER_TEXTLINES_OUT      =
*     ORDER_FLOWS_OUT          =
*     ORDER_CFGS_CUREFS_OUT    =
*     ORDER_CFGS_CUCFGS_OUT    =
*     ORDER_CFGS_CUINS_OUT     =
*     ORDER_CFGS_CUPRTS_OUT    =
*     ORDER_CFGS_CUVALS_OUT    =
*     ORDER_CFGS_CUBLBS_OUT    =
*     ORDER_CFGS_CUVKS_OUT     =
*     ORDER_BILLINGPLANS_OUT   =
*     ORDER_BILLINGDATES_OUT   =
*     ORDER_CREDITCARDS_OUT    =
      extensionout             = mt_extensionex.

  SORT mt_vbl_glt.

  LOOP AT mt_vbl_glt ASSIGNING FIELD-SYMBOL(<vbeln>).

    READ TABLE lt_order_headers_out WITH KEY doc_number = <vbeln>-vbeln
      INTO ms_order_header_ex.

    CHECK  ms_order_header_ex-rec_date  IN mt_sel_erdat.

    READ TABLE lt_bapisdhdst WITH KEY sd_doc = <vbeln>-vbeln
     ASSIGNING FIELD-SYMBOL(<sdhdst>).


*   Anzahl Belege aufzählen
    ADD 1 TO mv_number_of_documents.

    LOOP AT mt_outputfields ASSIGNING FIELD-SYMBOL(<opt>)
      WHERE strname = 'BAPISDHD'
        OR strname = 'BAPISDHDST'.

      CASE <opt>-strname.
        WHEN 'BAPISDHD'.
          ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE ms_order_header_ex TO FIELD-SYMBOL(<value>).
        WHEN 'BAPISDHDST'.
          ASSIGN COMPONENT <opt>-fieldname OF STRUCTURE <sdhdst> TO <value>.
      ENDCASE.

      CHECK <value> IS ASSIGNED.
      ls_item-vakey = <vbeln>-vbeln.
      ls_item-qualif = <opt>-fieldname.


      IF <value> IS ASSIGNED.
        WRITE <value> TO ls_item-fvalue.
      ELSE.
        ls_item-fvalue = 'NOT_ASSIGNED'.
      ENDIF.
      APPEND ls_item TO et_item.
      UNASSIGN <value>.

    ENDLOOP.

    DATA(lt_export) = export_bapi_extensions( iv_vakey = <vbeln>-vbeln
          iv_strname = 'BAPE_VBAK' ).

    APPEND LINES OF lt_export TO et_item.
  ENDLOOP.


ENDMETHOD.
