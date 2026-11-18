*&---------------------------------------------------------------------*
*&  Include YFI_UEBERGABE_BELEGE_LCL
*&---------------------------------------------------------------------*
CLASS lcl_fi_upload DEFINITION FINAL.
  PUBLIC SECTION.
    CLASS-METHODS: get_instance
      RETURNING VALUE(ro_instance) TYPE REF TO lcl_fi_upload.
    METHODS:
      f4_path
        IMPORTING iv_path_fn TYPE dynfnam
                  iv_fityp   TYPE dxfiletyp
        CHANGING  cv_path    TYPE catfilnam,
      read_file
        IMPORTING iv_loct TYPE /fis/bc_file_locationtype
                  iv_path TYPE catfilnam,
      processing.
  PRIVATE SECTION.
    CLASS-DATA:
        mo_instance TYPE REF TO lcl_fi_upload.

    CONSTANTS: mc_l TYPE /fis/bc_file_locationtype VALUE 'L',
               mc_a TYPE /fis/bc_file_locationtype VALUE 'A'.

    DATA: mt_raw_data TYPE stringtab,
          mt_files    TYPE /fisxee/salfldir_t,
          mt_file     TYPE TABLE OF string.
    TYPES: BEGIN OF mty_convert_data,
             file      TYPE string,
             col1(2),  " K; 40; 50;17
             col2(10), " Kopf->Belegdatum(8); Position->Konto(10)
             col3(2),  " Kopf->Belegart(2); Position->SHBKZ(1)
             col4(4),  " Kopf->Buchungskreis(4); Position->Steuerkenz.(2)
             col5(10), " Kopf->Buchungsdatum(8); Position->Kostenstelle(10)
             col6(12), " Kopf->Periode(3); Position->Auftragsnummer(12)
             col7(10), " Kopf->Währung(5); Position-> Profitcenter(10)
             col8(16), "Kopf->Referenz BKPF-XBLNR(16); Position-> BSEG-WRBTR(13)
             col9(25), "Kopf->BKPF-BKTXT(25); Position->BSEG-DMBTR(13)
*             col10(10), "Kopf->BKPF-KURSF(9): Position->BSEG-ZUONR(18)
             col10(20), "Kopf->BKPF-KURSF(9): Position->Steuerbasisbetrag Belegwährung
             col11(20), "Kopf->leer; Position->Steuerbasisbetrag Hauswährung
             col12(20), "Kopf->leer; Position->BSEG-ZUONR(18)
             col13(50), "Kopf->leer; Position->BSEG-SGTXT(50)
           END OF mty_convert_data.

    TYPES: BEGIN OF mty_doc,
             k_index           TYPE syindex,
             file              TYPE string,
             header            TYPE bapiache09,
             accountgl         TYPE bapiacgl09_tab,
             accountreceivable TYPE bapiacar09_tab,
             accountpayable    TYPE bapiacap09_tab,
             accounttax        TYPE bapiactx09_tab,
             currencyamount    TYPE bapiaccr09_tab,
           END OF mty_doc.

    TYPES BEGIN OF mty_error_msg.
    TYPES file TYPE string.
    TYPES processable TYPE abap_bool.
    TYPES index TYPE lineno.
    TYPES xblnr TYPE xblnr.
            INCLUDE TYPE bapiret2.
    TYPES END OF mty_error_msg.

    DATA: mt_convert_data TYPE STANDARD TABLE OF mty_convert_data,
          mt_error_msg    TYPE STANDARD TABLE OF mty_error_msg,
          mt_docs         TYPE STANDARD TABLE OF mty_doc,
          mt_error_files  TYPE HASHED TABLE OF string WITH UNIQUE KEY table_line.

    METHODS:
      convert_data,
      file_sep_line_to_stru
        IMPORTING is_line       TYPE any
                  iv_sep_tech   TYPE char01
                  iv_shift_left TYPE char01
        EXPORTING es_struc      TYPE mty_convert_data,
      fill_header IMPORTING is_data     TYPE mty_convert_data
                  EXPORTING es_header   TYPE bapiache09
                            ev_currency TYPE waers,
      fill_position IMPORTING is_data              TYPE mty_convert_data
                              iv_currency          TYPE waers
                              iv_bukrs             TYPE bukrs
                    CHANGING  cv_itemno            TYPE posnr_acc
                              ct_accountgl         TYPE bapiacgl09_tab
                              ct_accountreceivable TYPE bapiacar09_tab
                              ct_accountpayable    TYPE bapiacap09_tab
                              ct_accounttax        TYPE bapiactx09_tab
                              ct_currencyamount    TYPE bapiaccr09_tab,
      fill_tax  IMPORTING iv_bukrs          TYPE bukrs
                          iv_tax_code       TYPE mwskz
                CHANGING  cv_itemno         TYPE posnr_acc
                          cs_currencyamount TYPE bapiaccr09
                          ct_currencyamount TYPE bapiaccr09_tab
                          ct_accounttax     TYPE bapiactx09_tab,
      form_date IMPORTING iv_date        TYPE char10
                RETURNING VALUE(rv_date) TYPE bldat,

      get_soll_haben IMPORTING iv_bschl             TYPE bschl
                     RETURNING VALUE(rv_soll_haben) TYPE char01,
      check_bapi IMPORTING iv_k_index           TYPE syindex
                           is_header            TYPE bapiache09
                           it_accountgl         TYPE bapiacgl09_tab
                           it_accountreceivable TYPE bapiacar09_tab
                           it_accountpayable    TYPE bapiacap09_tab
                           it_accounttax        TYPE bapiactx09_tab
                           it_currencyamount    TYPE bapiaccr09_tab
                           iv_file              TYPE string,
      post_bapi IMPORTING iv_k_index           TYPE syindex
                          is_header            TYPE bapiache09
                          it_accountgl         TYPE bapiacgl09_tab
                          it_accountreceivable TYPE bapiacar09_tab
                          it_accountpayable    TYPE bapiacap09_tab
                          it_accounttax        TYPE bapiactx09_tab
                          it_currencyamount    TYPE bapiaccr09_tab
                          iv_file              TYPE string,
      read_files_from_directory
        IMPORTING iv_path TYPE catfilnam,
      display_list,
      cleanup
        CHANGING cs_header            TYPE bapiache09
                 ct_accountgl         TYPE bapiacgl09_tab
                 ct_accountreceivable TYPE bapiacar09_tab
                 ct_accountpayable    TYPE bapiacap09_tab
                 ct_accounttax        TYPE bapiactx09_tab
                 ct_currencyamount    TYPE bapiaccr09_tab,
      move_files,
      fill_list
        IMPORTING it_return  TYPE bapiret2_tab
                  iv_k_index TYPE syindex
                  iv_file    TYPE string
                  is_header  TYPE bapiache09.
ENDCLASS.

CLASS lcl_fi_upload IMPLEMENTATION.
  METHOD get_instance.
    IF mo_instance IS NOT BOUND.
      CREATE OBJECT mo_instance.
    ENDIF.
    ro_instance = mo_instance.
  ENDMETHOD.
  METHOD processing.
    FIELD-SYMBOLS: <fs_data>           TYPE mty_convert_data,
                   <fs_data2>          TYPE mty_convert_data,
                   <fs_currencyamount> TYPE bapiaccr09.
    DATA: ls_pos TYPE  mty_convert_data.
    DATA: lv_index TYPE sy-tabix.
    DATA: lv_k_index TYPE lineno.
    DATA: ls_header TYPE bapiache09.
    DATA: lv_itemno TYPE posnr_acc.
    DATA: lv_currency TYPE waers.
    DATA: lv_bschl TYPE bschl.
    DATA: ls_error_msg TYPE mty_error_msg.
    DATA: lt_accountgl         TYPE bapiacgl09_tab,
          lt_accountreceivable TYPE bapiacar09_tab,
          lt_accountpayable    TYPE bapiacap09_tab,
          lt_accounttax        TYPE bapiactx09_tab,
          lt_currencyamount    TYPE bapiaccr09_tab.


    LOOP AT mt_convert_data ASSIGNING <fs_data>
                            WHERE col1 = 'K'.

      TRANSLATE <fs_data>-col8 TO UPPER CASE.

      IF p_refpr IS NOT INITIAL.
*<!--Begin FIS/OSS:439004/sd:Faktura-Anlage SAP mit ES2000 Daten
        " Prüfung auf doppelte Referenz inkl. Belegdatum ---
        DATA:lv_belnr TYPE bkpf-belnr,
             ls_bkpf  TYPE bkpf,
             lv_bldat TYPE bkpf-bldat.

        CONCATENATE <fs_data>-col2+6(4)
                    <fs_data>-col2+3(2)
                    <fs_data>-col2(2)
                   INTO lv_bldat.

        SELECT SINGLE belnr
              FROM bkpf
              INTO lv_belnr
              WHERE bukrs = <fs_data>-col4
                AND gjahr = <fs_data>-col5+6(4)
                AND xblnr = <fs_data>-col8
                AND bldat = lv_bldat.

        IF sy-subrc = 0.
*<!--Ende FIS/OSS:439004/sd:Faktura-Anlage SAP mit ES2000 Daten
          ls_error_msg-file = <fs_data>-file.
          ls_error_msg-index = sy-tabix.
          ls_error_msg-xblnr = <fs_data>-col8.
          ls_error_msg-type = 'E'.
          ls_error_msg-message = |Referenz { ls_error_msg-xblnr } wurde bereits unter Beleg { <fs_data>-col4 },{ <fs_data>-col2+6(4) },{ lv_belnr } verbucht|.
          APPEND ls_error_msg TO mt_error_msg.
          INSERT <fs_data>-file INTO TABLE mt_error_files.
          CONTINUE.
        ENDIF. "FIS/OSS:439004/sd:Faktura-Anlage SAP mit ES2000 Daten
      ENDIF.

      lv_k_index = sy-tabix.
      lv_index = sy-tabix + 1.
      " Header füllen
      fill_header( EXPORTING is_data   = <fs_data>
                   IMPORTING es_header = ls_header
                             ev_currency = lv_currency ).

      CLEAR: lv_itemno.
      " Position füllen
      LOOP AT mt_convert_data ASSIGNING <fs_data2> FROM lv_index.

        IF <fs_data2>-col1 = 'K' OR <fs_data2>-col1 = space.
          EXIT.
        ENDIF.

        lv_itemno = lv_itemno + 1.

        fill_position(
          EXPORTING
            is_data              = <fs_data2>
            iv_currency          = lv_currency
            iv_bukrs             = ls_header-comp_code
          CHANGING
            cv_itemno            = lv_itemno
            ct_accountgl         = lt_accountgl
            ct_accountreceivable = lt_accountreceivable
            ct_accountpayable    = lt_accountpayable
            ct_accounttax        = lt_accounttax
            ct_currencyamount    = lt_currencyamount
        ).

      ENDLOOP.

*<!--Begin FIS/OSS:439004/sd:Faktura-Anlage SAP mit ES2000 Daten
      " Zahlungsbedingungen nachlesen
      " Debitor-Zahlungsbedingung
      LOOP AT lt_accountreceivable ASSIGNING FIELD-SYMBOL(<fs_ar>).
        SELECT SINGLE zterm
          FROM knb1
          INTO @<fs_ar>-pmnttrms
          WHERE kunnr = @<fs_ar>-customer
            AND bukrs = @ls_header-comp_code.
      ENDLOOP.

      " Kreditor-Zahlungsbedingung
      LOOP AT lt_accountpayable ASSIGNING FIELD-SYMBOL(<fs_ap>).
        SELECT SINGLE zterm
          FROM lfb1
          INTO @<fs_ap>-pmnttrms
          WHERE lifnr = @<fs_ap>-vendor_no
            AND bukrs = @ls_header-comp_code.
      ENDLOOP.
*<!--Ende FIS/OSS:439004/sd:Faktura-Anlage SAP mit ES2000 Daten

*      READ TABLE mt_blocked_files
*           WITH KEY table_line = <fs_data>-file
*           TRANSPORTING NO FIELDS.
*
*      IF sy-subrc = 0.
*        cleanup(
*          CHANGING
*            cs_header            = ls_header
*            ct_accountgl         = lt_accountgl
*            ct_accountreceivable = lt_accountreceivable
*            ct_accountpayable    = lt_accountpayable
*            ct_accounttax        = lt_accounttax
*            ct_currencyamount    = lt_currencyamount
*        ).
*        CONTINUE.
*      ENDIF.

      check_bapi(
        EXPORTING
          iv_k_index           = lv_k_index
          is_header            = ls_header
          it_accountgl         = lt_accountgl
          it_accountreceivable = lt_accountreceivable
          it_accountpayable    = lt_accountpayable
          it_accounttax        = lt_accounttax
          it_currencyamount    = lt_currencyamount
          iv_file              = <fs_data>-file
      ).

      DATA(ls_doc) = VALUE mty_doc(
      k_index           = lv_k_index
      file              = <fs_data>-file
      header            = ls_header
      accountgl         = lt_accountgl
      accountreceivable = lt_accountreceivable
      accountpayable    = lt_accountpayable
      accounttax        = lt_accounttax
      currencyamount    = lt_currencyamount ).

      APPEND ls_doc TO mt_docs.

      cleanup(
        CHANGING
          cs_header            = ls_header
          ct_accountgl         = lt_accountgl
          ct_accountreceivable = lt_accountreceivable
          ct_accountpayable    = lt_accountpayable
          ct_accounttax        = lt_accounttax
          ct_currencyamount    = lt_currencyamount
      ).
    ENDLOOP.
*<-Beginn FISpaf20260615 OSS439004
    IF p_test IS INITIAL.
      DATA: lt_return TYPE bapiret2_tab.

      LOOP AT mt_docs INTO ls_doc.

        READ TABLE mt_error_files
             WITH TABLE KEY table_line = ls_doc-file
             TRANSPORTING NO FIELDS.

        IF sy-subrc = 0.
          CONTINUE.
        ENDIF.

        post_bapi(
          EXPORTING
            iv_k_index           = ls_doc-k_index
            is_header            = ls_doc-header
            it_accountgl         = ls_doc-accountgl
            it_accountreceivable = ls_doc-accountreceivable
            it_accountpayable    = ls_doc-accountpayable
            it_accounttax        = ls_doc-accounttax
            it_currencyamount    = ls_doc-currencyamount
            iv_file              = ls_doc-file ).

        READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E' .
        IF sy-subrc = 0.
          ROLLBACK WORK.
        ELSE.
          COMMIT WORK.
        ENDIF.

      ENDLOOP.

      move_files( ).

    ENDIF.
*<-Ende Fispaf20260615 OSS439004
    IF mt_convert_data IS NOT INITIAL.
      display_list( ).
    ENDIF.
  ENDMETHOD.

*<-Beginn FISpaf20260615 OSS439004
  METHOD move_files.
    DATA: lv_source_dic  TYPE epsdirnam,
          lv_source_file TYPE epsfilnam,
          lv_target_file TYPE epsfilnam,
          lv_target_dic  TYPE epsdirnam,
          lv_fullpath    TYPE string,
          lv_all_ok      TYPE boolean.

    LOOP AT mt_error_msg INTO DATA(ls_line)
         GROUP BY ( file = ls_line-file ) INTO DATA(ls_group).

      lv_all_ok = abap_true.

      LOOP AT GROUP ls_group INTO DATA(ls_sub).
        IF ls_sub-processable IS INITIAL.
          lv_all_ok = abap_false.
          EXIT.
        ENDIF.
      ENDLOOP.

      lv_source_file = ls_sub-file.
      lv_target_file = ls_sub-file.
      lv_source_dic  = p_path.

      IF lv_all_ok = abap_true.
        lv_target_dic = p_path && 'verarbeitet'.
      ELSE.
        lv_target_dic = p_path && 'fehlerhaft'.
      ENDIF.

      cl_cts_language_file_io=>copy_files_local(
      EXPORTING
        im_source_file      = lv_source_file
        im_source_directory = lv_source_dic
        im_target_file      = lv_target_file
        im_target_directory = lv_target_dic
        im_overwrite_mode   = 'F'
     EXCEPTIONS
       open_input_file_failed   = 1
       open_output_file_failed  = 2
       write_block_failed       = 3
       read_block_failed        = 4
       close_output_file_failed = 5
       OTHERS                   = 6 ).

      " Ursprungsdatei löschen
      IF sy-subrc = 0.

        CONCATENATE p_path ls_sub-file INTO lv_fullpath.

        DELETE DATASET lv_fullpath.

        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.
*<-Ende Fispaf20260615 OSS439004

  METHOD cleanup.
    CLEAR: cs_header,
           ct_accountgl,
           ct_accountreceivable,
           ct_accountpayable,
           ct_accounttax,
           ct_currencyamount.
  ENDMETHOD.

  METHOD f4_path.
*   lokale Daten
    CONSTANTS:
      lc_loct   TYPE char8 VALUE 'P_LOCT',
      lc_fityp  TYPE char8 VALUE 'P_FITYP',
      lc_char_a TYPE char1 VALUE 'A',
      lc_char_p TYPE char1 VALUE 'P'.

    DATA: lt_dynpfields   TYPE TABLE OF dynpread,
          ls_dynpfields   TYPE dynpread,
          lf_window_title TYPE string,
          lv_action       TYPE i,
          lv_cnt          TYPE i,
          lt_filename     TYPE filetable,
          lv_location     TYPE  dxfields-location,
          lv_dynpfield    TYPE dynpread-fieldname,
          lv_dynpfield2   TYPE dynpread-fieldname.

    FIELD-SYMBOLS: <fs_dynf> TYPE dynpread.

    lv_dynpfield2 = lc_fityp.
    lv_dynpfield  = iv_path_fn.

    CLEAR:  lt_dynpfields,
            ls_dynpfields.

    MOVE lc_loct TO ls_dynpfields-fieldname.
    APPEND ls_dynpfields TO lt_dynpfields.

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname               = sy-cprog
        dynumb               = sy-dynnr
      TABLES
        dynpfields           = lt_dynpfields
      EXCEPTIONS
        invalid_abapworkarea = 1
        invalid_dynprofield  = 2
        invalid_dynproname   = 3
        invalid_dynpronummer = 4
        invalid_request      = 5
        no_fielddescription  = 6
        invalid_parameter    = 7
        undefind_error       = 8
        double_conversion    = 9
        stepl_not_found      = 10
        OTHERS               = 11.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    READ TABLE lt_dynpfields ASSIGNING <fs_dynf> WITH KEY fieldname = lc_loct.
    IF sy-subrc = 0.
      IF <fs_dynf>-fieldvalue EQ lc_char_a.
        lv_location = lc_char_a.
      ELSE.
        lv_location = lc_char_p.
      ENDIF.
    ENDIF.

    CLEAR:  lt_dynpfields,
            ls_dynpfields.

    MOVE lc_fityp TO ls_dynpfields-fieldname.
    APPEND ls_dynpfields TO lt_dynpfields.

    CALL FUNCTION 'DYNP_VALUES_READ'
      EXPORTING
        dyname               = sy-cprog
        dynumb               = sy-dynnr
      TABLES
        dynpfields           = lt_dynpfields
      EXCEPTIONS
        invalid_abapworkarea = 01
        invalid_dynprofield  = 02
        invalid_dynproname   = 03
        invalid_dynpronummer = 04
        invalid_request      = 05
        no_fielddescription  = 06
        undefind_error       = 07.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    UNASSIGN <fs_dynf>.

    READ TABLE lt_dynpfields ASSIGNING <fs_dynf> WITH KEY fieldname = lc_fityp.
    IF sy-subrc = 0.
      IF lv_location = lc_char_p AND  <fs_dynf>-fieldvalue = lc_char_p.
        CALL METHOD cl_gui_frontend_services=>file_open_dialog
          EXPORTING
            window_title            = lf_window_title
          CHANGING
            file_table              = lt_filename
            rc                      = lv_cnt
            user_action             = lv_action
          EXCEPTIONS
            file_open_dialog_failed = 1
            cntl_error              = 2
            error_no_gui            = 3
            not_supported_by_gui    = 4
            OTHERS                  = 5.

        IF sy-subrc <> 0.
          MESSAGE i117(cacsib_edt).
        ENDIF.

        IF lv_cnt > 1.
          MESSAGE e062(cacsib_edt).
        ELSE.
          IF NOT lv_cnt < 1.
            READ TABLE lt_filename
              INTO cv_path INDEX 1.
          ENDIF.
        ENDIF.
      ELSE.
        CALL FUNCTION 'F4_DXFILENAME_4_DYNP'
          EXPORTING
            dynpfield_filetype = lv_dynpfield2
            dynpfield_filename = lv_dynpfield
            dyname             = sy-cprog
            dynumb             = sy-dynnr
            filetype           = iv_fityp
            location           = lc_char_a.
      ENDIF.
    ENDIF.
  ENDMETHOD.                    "f4_path
  METHOD read_file.
    DATA: lv_path          TYPE string,
          lv_string        TYPE string,
          lv_file_complete TYPE string,
          lv_file          TYPE string,
          lv_fullpath      TYPE string.

    FIELD-SYMBOLS: <ls_file> LIKE LINE OF mt_files.

    CASE iv_loct.
      WHEN mc_l.  "Datei aus Lokal
        lv_path = iv_path.

        CALL METHOD cl_gui_frontend_services=>gui_upload
          EXPORTING
            filename                = lv_path
            has_field_separator     = abap_false
          CHANGING
            data_tab                = mt_raw_data
          EXCEPTIONS
            file_open_error         = 1
            file_read_error         = 2
            no_batch                = 3
            gui_refuse_filetransfer = 4
            invalid_type            = 5
            no_authority            = 6
            unknown_error           = 7
            bad_data_format         = 8
            header_not_allowed      = 9
            separator_not_allowed   = 10
            header_too_long         = 11
            unknown_dp_error        = 12
            access_denied           = 13
            dp_out_of_memory        = 14
            disk_full               = 15
            dp_timeout              = 16
            not_supported_by_gui    = 17
            error_no_gui            = 18
            OTHERS                  = 19.

        IF sy-subrc <> 0.
          MESSAGE e007(yfi).
*   Datei kann nicht gelesen werden !
        ENDIF.
      WHEN mc_a.  "Datei aus Applikationsserver
*<-Beginn FISpaf20264028 OSS439004
        read_files_from_directory( iv_path = iv_path ).

        IF mt_files IS NOT INITIAL.

          LOOP AT mt_files ASSIGNING <ls_file>
            WHERE name CP 'SAP_Export*'.

            lv_file_complete = <ls_file>-name.

            SPLIT lv_file_complete AT '.CSV' INTO lv_file DATA(lv_remaining).
            lv_file = lv_file && '.CSV'.

            " Falls .pdf (klein) verwendet wurde
            IF lv_remaining IS INITIAL.
              SPLIT lv_file_complete AT '.csv' INTO lv_file DATA(lv_remaining2).
              lv_file = lv_file && '.csv'.
            ENDIF.

            APPEND lv_file TO mt_file.

            CONCATENATE iv_path lv_file INTO lv_fullpath.

            OPEN DATASET lv_fullpath FOR INPUT IN TEXT MODE ENCODING UTF-8 IGNORING CONVERSION ERRORS.
            IF sy-subrc <> 0.
              RETURN.
            ENDIF.
            DO.
              READ DATASET lv_fullpath INTO lv_string.
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.
              lv_string = |{ lv_file };{ lv_string }|.
              APPEND lv_string TO mt_raw_data.
            ENDDO.

            CLOSE DATASET lv_fullpath.

          ENDLOOP.

        ENDIF.
*<-Ende Fispaf20260428 OSS439004
    ENDCASE.
    IF mt_raw_data IS NOT INITIAL.
      convert_data( ).
    ENDIF.
  ENDMETHOD.

  METHOD read_files_from_directory.
    DATA: lt_files TYPE /fisxee/salfldir_t,
          lv_path  TYPE salfile-longname.

    FIELD-SYMBOLS: <ls_file> LIKE LINE OF lt_files.

    lv_path = iv_path.

    CALL FUNCTION 'RZL_READ_DIR_LOCAL'
      EXPORTING
        name           = lv_path
      TABLES
        file_tbl       = lt_files
      EXCEPTIONS
        argument_error = 1
        not_found      = 2
        OTHERS         = 3.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    "delete rows defining directory (which start from '.')
    "or subdirectory (which start from '..')
    LOOP AT lt_files ASSIGNING <ls_file>.

      IF <ls_file>-name(1) = '.'.
        CLEAR <ls_file>-name .
      ENDIF.

    ENDLOOP.

    DELETE lt_files WHERE name = space.

    REFRESH mt_files.
    mt_files = lt_files.
  ENDMETHOD.

  METHOD convert_data.
    DATA: ls_raw_data     LIKE LINE OF mt_raw_data,
          ls_convert_data TYPE mty_convert_data.

    LOOP AT mt_raw_data INTO ls_raw_data.
      file_sep_line_to_stru(
        EXPORTING
          is_line     = ls_raw_data
          iv_sep_tech = ';'
          iv_shift_left = abap_true
        IMPORTING
          es_struc    = ls_convert_data
      ).
      APPEND ls_convert_data TO mt_convert_data.
    ENDLOOP.
  ENDMETHOD.
  METHOD file_sep_line_to_stru.
    DATA lt_split TYPE STANDARD TABLE OF string.
    FIELD-SYMBOLS <lf_split> TYPE string.
    FIELD-SYMBOLS <lf_struc> TYPE any.


    CLEAR es_struc.
    SPLIT is_line AT iv_sep_tech INTO TABLE lt_split.

    CHECK NOT lt_split IS INITIAL.

    DO.
      ASSIGN COMPONENT sy-index OF STRUCTURE es_struc TO <lf_struc>.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.
      READ TABLE lt_split ASSIGNING <lf_split> INDEX sy-index.
*   CHECK sy-subrc = 0.                  " DEL 20170330_PERFORMANCE
      IF sy-subrc <> 0.                    " INS 20170330_PERFORMANCE
        EXIT.
      ENDIF.
      MOVE <lf_split> TO <lf_struc>.
      CHECK NOT iv_shift_left IS INITIAL.
      SHIFT <lf_struc> LEFT DELETING LEADING space.
    ENDDO.
  ENDMETHOD.
  METHOD fill_header.

*BAPIACHE09 füllen
    es_header-bus_act = 'RFBU'.
    "Name des Benutzers
    es_header-username = sy-uname.
    "Blegekopftext
    es_header-header_txt = is_data-col9.
    "Buchungskreis
    es_header-comp_code = is_data-col4.
    "Belegdatum im Beleg
    es_header-doc_date = form_date( iv_date = is_data-col2 ).
    "Buchungsdatum im Beleg
    es_header-pstng_date = form_date( iv_date = is_data-col5 ).
    "Belegart
    es_header-doc_type = is_data-col3.
    "ReferenzNr
    es_header-ref_doc_no = is_data-col8.
    "Geschäftsmonat
    es_header-fis_period = is_data-col6.
    " Währung für position
    ev_currency = is_data-col7.
  ENDMETHOD.
  METHOD fill_position.

    DATA: ls_accountgl         TYPE bapiacgl09,
          ls_currencyamount    TYPE bapiaccr09,
          ls_accountreceivable TYPE bapiacar09,
          ls_accountpayable    TYPE bapiacap09.

    DATA: lv_amt_doccur TYPE char30,
          lv_amt_base   TYPE char30.
    DATA: lv_bschl      TYPE bschl,
          lv_soll_haben TYPE char01.

    IF is_data-col1 = '40' OR is_data-col1 = '50'.
      " Buchungsschlüssel 40 oder 50 -> BAPIACGL09-GL_ACCOUNT füllen
      ls_accountgl-itemno_acc = cv_itemno.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = is_data-col2   " C-Feld
        IMPORTING
          output = ls_accountgl-gl_account.   " interne Darstellung von INPUT, beliebiger Typ
      ls_accountgl-tax_code = is_data-col4.

      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = is_data-col5  " C-Feld
        IMPORTING
          output = ls_accountgl-costcenter.   " interne Darstellung von INPUT, beliebiger Typ

      ls_accountgl-orderid = is_data-col6.
      ls_accountgl-profit_ctr = is_data-col7.
      ls_accountgl-alloc_nmbr = is_data-col12.
      ls_accountgl-item_text = is_data-col13.

      ls_currencyamount-itemno_acc = cv_itemno.
      lv_amt_doccur = is_data-col8.
      CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
        EXPORTING
          i_string                   = lv_amt_doccur  " Wert in 'Character'
        IMPORTING
          e_dec                      = ls_currencyamount-amt_doccur    " Wert in 'packed decimal', vier Nachkommastellen
        EXCEPTIONS
          wrong_characters           = 1
          first_character_wrong      = 2
          arithmetic_sign            = 3
          multiple_decimal_separator = 4
          thousandsep_in_decimal     = 5
          thousand_separator         = 6
          number_too_big             = 7
          OTHERS                     = 8.
      IF sy-subrc <> 0.
        REPLACE ALL OCCURRENCES OF '.' IN lv_amt_doccur WITH space.
        REPLACE ALL OCCURRENCES OF ',' IN lv_amt_doccur WITH '.'.
        CONDENSE lv_amt_doccur NO-GAPS.
        ls_currencyamount-amt_doccur = lv_amt_doccur.
      ENDIF.

      lv_bschl = is_data-col1.
      lv_soll_haben = get_soll_haben( iv_bschl = lv_bschl ).
      IF lv_soll_haben = '-'.
        ls_currencyamount-amt_doccur = ls_currencyamount-amt_doccur * -1.
      ENDIF.
      ls_currencyamount-currency = iv_currency.

      APPEND ls_accountgl TO ct_accountgl.
      " Steuer berechen und Steuerdaten füllen
      IF is_data-col10 IS NOT INITIAL.

        lv_amt_base = is_data-col10.
        CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
          EXPORTING
            i_string                   = lv_amt_base  " Wert in 'Character'
          IMPORTING
            e_dec                      = ls_currencyamount-amt_base    " Wert in 'packed decimal', vier Nachkommastellen
          EXCEPTIONS
            wrong_characters           = 1
            first_character_wrong      = 2
            arithmetic_sign            = 3
            multiple_decimal_separator = 4
            thousandsep_in_decimal     = 5
            thousand_separator         = 6
            number_too_big             = 7
            OTHERS                     = 8.
        IF sy-subrc <> 0.
          REPLACE ALL OCCURRENCES OF '.' IN lv_amt_base WITH space.
          REPLACE ALL OCCURRENCES OF ',' IN lv_amt_base WITH '.'.
          CONDENSE lv_amt_base NO-GAPS.
          ls_currencyamount-amt_base = lv_amt_base.
        ENDIF.

        IF lv_soll_haben = '-'.
          ls_currencyamount-amt_base = ls_currencyamount-amt_base * -1.
        ENDIF.

        fill_tax(
          EXPORTING
            iv_bukrs          = iv_bukrs
            iv_tax_code       = is_data-col4(2)
          CHANGING
            cv_itemno         = cv_itemno
            cs_currencyamount = ls_currencyamount
            ct_currencyamount = ct_currencyamount
            ct_accounttax     = ct_accounttax
        ).
      ELSE.
        APPEND ls_currencyamount TO ct_currencyamount.
      ENDIF.

    ELSEIF is_data-col1 >= '01' AND is_data-col1 <= '19'.
      " Buchungsschlüssel 01 bis 19 -> BAPIACAR09-CUSTOMER füllen
      ls_accountreceivable-itemno_acc = cv_itemno.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = is_data-col2   " C-Feld
        IMPORTING
          output = ls_accountreceivable-customer.  " interne Darstellung von INPUT, beliebiger Typ
      ls_accountreceivable-sp_gl_ind = is_data-col3.
      ls_accountreceivable-tax_code = is_data-col4.
      ls_accountreceivable-profit_ctr = is_data-col7.
      ls_accountreceivable-alloc_nmbr = is_data-col12.
      ls_accountreceivable-item_text = is_data-col13.

      ls_currencyamount-itemno_acc = cv_itemno.
      lv_amt_doccur = is_data-col8.
      CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
        EXPORTING
          i_string                   = lv_amt_doccur " Wert in 'Character'
        IMPORTING
          e_dec                      = ls_currencyamount-amt_doccur    " Wert in 'packed decimal', vier Nachkommastellen
        EXCEPTIONS
          wrong_characters           = 1
          first_character_wrong      = 2
          arithmetic_sign            = 3
          multiple_decimal_separator = 4
          thousandsep_in_decimal     = 5
          thousand_separator         = 6
          number_too_big             = 7
          OTHERS                     = 8.
      IF sy-subrc <> 0.
        REPLACE ALL OCCURRENCES OF '.' IN lv_amt_doccur WITH space.
        REPLACE ALL OCCURRENCES OF ',' IN lv_amt_doccur WITH '.'.
        CONDENSE lv_amt_doccur NO-GAPS.
        ls_currencyamount-amt_doccur = lv_amt_doccur.
      ENDIF.

      lv_bschl = is_data-col1.
      lv_soll_haben = get_soll_haben( iv_bschl = lv_bschl ).
      IF lv_soll_haben = '-'.
        ls_currencyamount-amt_doccur = ls_currencyamount-amt_doccur * -1.
      ENDIF.

      ls_currencyamount-currency = iv_currency.

      APPEND ls_accountreceivable TO ct_accountreceivable.

      IF is_data-col10 IS NOT INITIAL.
        lv_amt_base = is_data-col10.
        CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
          EXPORTING
            i_string                   = lv_amt_base  " Wert in 'Character'
          IMPORTING
            e_dec                      = ls_currencyamount-amt_base    " Wert in 'packed decimal', vier Nachkommastellen
          EXCEPTIONS
            wrong_characters           = 1
            first_character_wrong      = 2
            arithmetic_sign            = 3
            multiple_decimal_separator = 4
            thousandsep_in_decimal     = 5
            thousand_separator         = 6
            number_too_big             = 7
            OTHERS                     = 8.
        IF sy-subrc <> 0.
          REPLACE ALL OCCURRENCES OF '.' IN lv_amt_base WITH space.
          REPLACE ALL OCCURRENCES OF ',' IN lv_amt_base WITH '.'.
          CONDENSE lv_amt_base NO-GAPS.
          ls_currencyamount-amt_base = lv_amt_base.
        ENDIF.

        IF lv_soll_haben = '-'.
          ls_currencyamount-amt_base = ls_currencyamount-amt_base * -1.
        ENDIF.

        fill_tax(
          EXPORTING
            iv_bukrs          = iv_bukrs
            iv_tax_code       = is_data-col4(2)
          CHANGING
            cv_itemno         = cv_itemno
            cs_currencyamount = ls_currencyamount
            ct_currencyamount = ct_currencyamount
            ct_accounttax     = ct_accounttax
        ).
      ELSE.
        APPEND ls_currencyamount TO ct_currencyamount.
      ENDIF.

    ELSEIF is_data-col1 >= '21' AND is_data-col1 <= '39'.
      " Buchungsschlüssel 21 bis 39 -> BAPIACAP09-VENDOR füllen
      ls_accountpayable-itemno_acc =  cv_itemno.
      CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
        EXPORTING
          input  = is_data-col2   " C-Feld
        IMPORTING
          output = ls_accountpayable-vendor_no.  " interne Darstellung von INPUT, beliebiger Typ
      ls_accountpayable-sp_gl_ind = is_data-col3.
      ls_accountpayable-tax_code = is_data-col4.
      ls_accountpayable-profit_ctr = is_data-col7.
      ls_accountpayable-alloc_nmbr = is_data-col12.
      ls_accountpayable-item_text = is_data-col13.

      ls_currencyamount-itemno_acc = cv_itemno.
      lv_amt_doccur = is_data-col8.

      CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
        EXPORTING
          i_string                   = lv_amt_doccur  " Wert in 'Character'
        IMPORTING
          e_dec                      = ls_currencyamount-amt_doccur    " Wert in 'packed decimal', vier Nachkommastellen
        EXCEPTIONS
          wrong_characters           = 1
          first_character_wrong      = 2
          arithmetic_sign            = 3
          multiple_decimal_separator = 4
          thousandsep_in_decimal     = 5
          thousand_separator         = 6
          number_too_big             = 7
          OTHERS                     = 8.
      IF sy-subrc <> 0.
        REPLACE ALL OCCURRENCES OF '.' IN lv_amt_doccur WITH space.
        REPLACE ALL OCCURRENCES OF ',' IN lv_amt_doccur WITH '.'.
        CONDENSE lv_amt_doccur NO-GAPS.
        ls_currencyamount-amt_doccur = lv_amt_doccur.
      ENDIF.

      lv_bschl = is_data-col1.
      lv_soll_haben = get_soll_haben( iv_bschl = lv_bschl ).
      IF lv_soll_haben = '-'.
        ls_currencyamount-amt_doccur = ls_currencyamount-amt_doccur * -1.
      ENDIF.
      ls_currencyamount-currency = iv_currency.

      APPEND ls_accountpayable TO ct_accountpayable.

      IF is_data-col10 IS NOT INITIAL.

        lv_amt_base = is_data-col10.
        CALL FUNCTION 'C14DG_CHAR_NUMBER_CONVERSION'
          EXPORTING
            i_string                   = lv_amt_base  " Wert in 'Character'
          IMPORTING
            e_dec                      = ls_currencyamount-amt_base    " Wert in 'packed decimal', vier Nachkommastellen
          EXCEPTIONS
            wrong_characters           = 1
            first_character_wrong      = 2
            arithmetic_sign            = 3
            multiple_decimal_separator = 4
            thousandsep_in_decimal     = 5
            thousand_separator         = 6
            number_too_big             = 7
            OTHERS                     = 8.
        IF sy-subrc <> 0.
          REPLACE ALL OCCURRENCES OF '.' IN lv_amt_base WITH space.
          REPLACE ALL OCCURRENCES OF ',' IN lv_amt_base WITH '.'.
          CONDENSE lv_amt_base NO-GAPS.
          ls_currencyamount-amt_base = lv_amt_base.
        ENDIF.

        IF lv_soll_haben = '-'.
          ls_currencyamount-amt_base = ls_currencyamount-amt_base * -1.
        ENDIF.

        fill_tax(
          EXPORTING
            iv_bukrs          = iv_bukrs
            iv_tax_code       = is_data-col4(2)
          CHANGING
            cv_itemno         = cv_itemno
            cs_currencyamount = ls_currencyamount
            ct_currencyamount = ct_currencyamount
            ct_accounttax     = ct_accounttax
        ).
      ELSE.
        APPEND ls_currencyamount TO ct_currencyamount.
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD fill_tax.
    TYPES: lty_mwdat TYPE STANDARD TABLE OF rtax1u15.
    DATA: lv_waers TYPE bkpf-waers,
          lv_wrbtr TYPE bseg-wrbtr,
          lt_mwdat TYPE lty_mwdat,
          ls_tax   TYPE bapiactx09.

    FIELD-SYMBOLS: <fs_mwdat> TYPE rtax1u15.

    MOVE cs_currencyamount-currency TO lv_waers.
    lv_wrbtr = cs_currencyamount-amt_base + cs_currencyamount-amt_doccur.

    CALL FUNCTION 'CALCULATE_TAX_FROM_GROSSAMOUNT'
      EXPORTING
        i_bukrs                 = iv_bukrs   " Buchungskreis
        i_mwskz                 = iv_tax_code  " Steuerkennzeichen
        i_waers                 = lv_waers   " Währungsschlüssel
        i_wrbtr                 = lv_wrbtr   " Bruttobetrag
      TABLES
        t_mwdat                 = lt_mwdat    " Tabelle der Steuerwerte und Prozentsätze
      EXCEPTIONS
        bukrs_not_found         = 1
        country_not_found       = 2
        mwskz_not_defined       = 3
        mwskz_not_valid         = 4
        account_not_found       = 5
        different_discount_base = 6
        different_tax_base      = 7
        txjcd_not_valid         = 8
        not_found               = 9
        ktosl_not_found         = 10
        kalsm_not_found         = 11
        parameter_error         = 12
        knumh_not_found         = 13
        kschl_not_found         = 14
        unknown_error           = 15
        OTHERS                  = 16.
    IF sy-subrc <> 0.
*     MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      RETURN.
    ENDIF.

    READ TABLE lt_mwdat ASSIGNING <fs_mwdat> INDEX 1.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    cs_currencyamount-amt_doccur = 0.
    APPEND cs_currencyamount TO ct_currencyamount.
    cv_itemno = cv_itemno + 1.
    cs_currencyamount-itemno_acc = cv_itemno.
    cs_currencyamount-amt_doccur = <fs_mwdat>-wmwst.
    cs_currencyamount-amt_base = <fs_mwdat>-kawrt.
    APPEND cs_currencyamount TO ct_currencyamount.

    ls_tax-itemno_acc = cv_itemno.
    ls_tax-cond_key = <fs_mwdat>-kschl.
    ls_tax-tax_code = iv_tax_code.
    APPEND ls_tax TO ct_accounttax.
  ENDMETHOD.
  METHOD form_date.
    rv_date+6(2) = iv_date+0(2).
    rv_date+4(2) = iv_date+3(2).
    rv_date+0(4) = iv_date+6(4).
  ENDMETHOD.
  METHOD get_soll_haben.
    IF iv_bschl = '40' OR
       ( iv_bschl >= '01' AND iv_bschl <= '09' ) OR
       ( iv_bschl >= '21' AND iv_bschl <= '29' ).
      rv_soll_haben = '+'.
    ELSEIF iv_bschl = '50' OR
       ( iv_bschl >= '11' AND iv_bschl <= '19' ) OR
       ( iv_bschl >= '29' AND iv_bschl <= '39' ).
      rv_soll_haben = '-'.
    ENDIF.
  ENDMETHOD.
  METHOD check_bapi.
    DATA: lt_return            TYPE bapiret2_tab,
          lt_accountgl         TYPE bapiacgl09_tab,
          lt_accountreceivable TYPE bapiacar09_tab,
          lt_accountpayable    TYPE bapiacap09_tab,
          lt_accounttax        TYPE bapiactx09_tab,
          lt_currencyamount    TYPE bapiaccr09_tab,
          lv_all_ok            TYPE abap_bool.

    lt_accountgl          = it_accountgl.
    lt_accountreceivable  = it_accountreceivable.
    lt_accountpayable     = it_accountpayable.
    lt_accounttax         = it_accounttax.
    lt_currencyamount     = it_currencyamount.

    " BAPI aufrufen
    CALL FUNCTION 'BAPI_ACC_DOCUMENT_CHECK'
      EXPORTING
        documentheader    = is_header  " Kopfzeile
      TABLES
        accountgl         = lt_accountgl  " Sachkontenzeile
        accountreceivable = lt_accountreceivable  " Debitorzeile
        accountpayable    = lt_accountpayable  " Kreditorzeile
        accounttax        = lt_accounttax  " Steuerzeile
        currencyamount    = lt_currencyamount   " Währungspositionen
        return            = lt_return.   " Returnparameter

    fill_list(
      EXPORTING
        it_return  = lt_return
        iv_k_index = iv_k_index
        iv_file    = iv_file
        is_header  = is_header ).

    READ TABLE lt_return
      WITH KEY type = 'E'
      TRANSPORTING NO FIELDS.

    IF sy-subrc = 0.
      INSERT iv_file INTO TABLE mt_error_files.
    ENDIF.

    CLEAR lt_return.
  ENDMETHOD.

  METHOD post_bapi.
    DATA: lt_return            TYPE bapiret2_tab,
          lt_accountgl         TYPE bapiacgl09_tab,
          lt_accountreceivable TYPE bapiacar09_tab,
          lt_accountpayable    TYPE bapiacap09_tab,
          lt_accounttax        TYPE bapiactx09_tab,
          lt_currencyamount    TYPE bapiaccr09_tab,
          lv_all_ok            TYPE abap_bool.

    lt_accountgl          = it_accountgl.
    lt_accountreceivable  = it_accountreceivable.
    lt_accountpayable     = it_accountpayable.
    lt_accounttax         = it_accounttax.
    lt_currencyamount     = it_currencyamount.

    " BAPI aufrufen
    CALL FUNCTION 'BAPI_ACC_DOCUMENT_POST'
      EXPORTING
        documentheader    = is_header    " Kopfzeile
      TABLES
        accountgl         = lt_accountgl  " Sachkontenzeile
        accountreceivable = lt_accountreceivable  " Debitorzeile
        accountpayable    = lt_accountpayable  " Kreditorzeile
        accounttax        = lt_accounttax  " Steuerzeile
        currencyamount    = lt_currencyamount   " Währungspositionen
        return            = lt_return.   " Returnparameter

    fill_list(
      EXPORTING
        it_return  = lt_return
        iv_k_index = iv_k_index
        iv_file    = iv_file
        is_header  = is_header ).

    CLEAR lt_return.
  ENDMETHOD.

  METHOD fill_list.
    DATA: ls_error_msg  TYPE mty_error_msg.

    FIELD-SYMBOLS:<fs_return> TYPE bapiret2.

    LOOP AT it_return ASSIGNING <fs_return>.
      MOVE-CORRESPONDING <fs_return> TO ls_error_msg.
      ls_error_msg-file  = iv_file.
      IF ls_error_msg-type <> 'E'.
        ls_error_msg-processable = 'X'.
      ENDIF.
      ls_error_msg-index = iv_k_index.
      ls_error_msg-xblnr = is_header-ref_doc_no.
      APPEND ls_error_msg TO mt_error_msg.
      CLEAR ls_error_msg.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_list.
    DATA: lr_table TYPE REF TO cl_salv_table.
    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lr_table
          CHANGING
            t_table      = mt_error_msg ).
      CATCH cx_salv_msg.                                "#EC NO_HANDLER
    ENDTRY.
    lr_table->display( ).
  ENDMETHOD.
ENDCLASS.
