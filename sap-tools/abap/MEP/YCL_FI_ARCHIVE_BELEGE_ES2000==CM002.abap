  METHOD archive_invoices.
    CONSTANTS: lc_spaces_20   TYPE c LENGTH 20 VALUE '             MANUELL',
               lc_ar_object_i TYPE string VALUE 'YIFINVOICE',
               lc_ar_object_o TYPE string VALUE 'YOFINVOICE'.

    TYPES BEGIN OF lty_arch_msg.
    TYPES file TYPE string.
    TYPES processable TYPE abap_bool.
    TYPES bukrs TYPE bukrs.
    TYPES belnr TYPE belnr_d.
    TYPES gjahr TYPE gjahr.
    TYPES msg TYPE bapi_msg.
    TYPES END OF lty_arch_msg.

    DATA: lv_file_complete TYPE string,
          lv_file          TYPE string,
          lv_gjahr         TYPE gjahr,
          lv_ref           TYPE xblnr1,
          lv_object_id     TYPE sapb-sapobjid,
          lv_ar_object     TYPE toaom-ar_object,
          lv_filesize      TYPE epsf-epsfilsiz,
          lv_file_eps      TYPE epsfilnam,
          lv_pdf_xstring   TYPE xstring,
          lv_fullpath      TYPE string,
          lv_line          TYPE raw255,
          lv_path          TYPE epsf-epsdirnam,
          lv_length        TYPE i,
          lv_filename      TYPE toaat-filename,
          lv_flength       TYPE sapb-length,
          lv_source_dic    TYPE epsdirnam,
          lv_source_file   TYPE epsfilnam,
          lv_target_file   TYPE epsfilnam,
          lv_target_dic    TYPE epsdirnam,
          lt_archivierung  TYPE TABLE OF yfi_archivierung,
          lt_raw           TYPE STANDARD TABLE OF raw255,
          lt_pdf_data      TYPE TABLE OF tbl1024,
          ls_archivierung  TYPE yfi_archivierung,
          ls_outdoc        TYPE toadt,
          lt_arch_msg      TYPE STANDARD TABLE OF lty_arch_msg,
          ls_arch_msg      TYPE lty_arch_msg.

    FIELD-SYMBOLS: <ls_file> LIKE LINE OF mt_files.

    IF mt_files IS NOT INITIAL.

      "FISpaf20260323 OSS439004 start
      " Schleife über alle Dateien, die mit I* oder O* beginnen (Eingangs-/Ausgangsrechnungen)
      LOOP AT mt_files ASSIGNING <ls_file>
          WHERE name CP 'I*'
             OR name CP 'O*'.

        " Weiterverarbeiten nur, wenn auch eine Datei gefunden wurde
        IF sy-subrc = 0.

          "----------------------------------------------------------
          " Initialisierungen
          "----------------------------------------------------------
          CLEAR: lv_ar_object, lv_object_id, lv_flength, lv_pdf_xstring, lv_filename.

          " Kompletter Dateiname zwischenspeichern
          lv_file_complete = <ls_file>-name.

          "----------------------------------------------------------
          " Dateiendung entfernen, egal ob .PDF oder .pdf
          "----------------------------------------------------------
          SPLIT lv_file_complete AT '.PDF' INTO lv_file DATA(lv_remaining).
          lv_file = lv_file && '.PDF'.

          " Falls .pdf (klein) verwendet wurde
          IF lv_remaining IS INITIAL.
            SPLIT lv_file_complete AT '.pdf' INTO lv_file DATA(lv_remaining2).
            lv_file = lv_file && '.pdf'.
          ENDIF.

          "----------------------------------------------------------
          " Filename in Typ (I/O), Jahr, Referenz splitten
          "----------------------------------------------------------
          SPLIT lv_file AT '_' INTO DATA(lv_type) lv_gjahr lv_ref.

          " PDF-Endung aus Referenz entfernen
          REPLACE '.PDF' IN lv_ref WITH '' IGNORING CASE.

          " Führende Nullen aus der Rechnungsreferenz entfernen
          SHIFT lv_ref LEFT DELETING LEADING '0'.

          CLEAR ls_archivierung.

          "----------------------------------------------------------
          " BKPF-Datensatz lesen (Prüfen, ob Rechnung existiert)
          "----------------------------------------------------------
          SELECT SINGLE belnr, gjahr, bukrs
            FROM bkpf
            WHERE gjahr = @lv_gjahr
              AND xblnr = @lv_ref
            INTO CORRESPONDING FIELDS OF @ls_archivierung.

          ls_archivierung-mandt    = iv_client.
          ls_archivierung-filename = lv_file.

          " Objekt-ID für die Archivierung generieren (Bukrs+Belnr+Gjahr)
          IF ls_archivierung-bukrs IS NOT INITIAL OR ls_archivierung-belnr IS NOT INITIAL OR ls_archivierung-gjahr <> '0000'.
            lv_object_id = ls_archivierung-bukrs.
            lv_object_id+4 = ls_archivierung-belnr.
            lv_object_id+14 = ls_archivierung-gjahr.
          ENDIF.

          " AR-Objekt je nach Typ bestimmen
          IF lv_type = 'I'.
            CONCATENATE lc_ar_object_i ls_archivierung-bukrs INTO lv_ar_object.
          ELSEIF lv_type = 'O'.
            CONCATENATE lc_ar_object_o ls_archivierung-bukrs INTO lv_ar_object.
          ENDIF.

          lv_file_eps = lv_file.
          lv_path     = iv_path.

          "----------------------------------------------------------
          " Dateiattribute lesen (Dateigröße)
          "----------------------------------------------------------
          CALL FUNCTION 'EPS_GET_FILE_ATTRIBUTES'
            EXPORTING
              file_name = lv_file_eps
              dir_name  = lv_path
            IMPORTING
              file_size = lv_filesize.

          CONCATENATE iv_path lv_file INTO lv_fullpath.

          "----------------------------------------------------------
          " Datei einlesen in RAW-Format
          "----------------------------------------------------------
          DATA lv_xstring TYPE xstring.
          OPEN DATASET lv_fullpath FOR INPUT IN BINARY MODE.
          IF sy-subrc = 0.
            READ DATASET lv_fullpath INTO lv_xstring.
*            WHILE sy-subrc = 0.
*              READ DATASET lv_fullpath INTO lv_line.
*              IF sy-subrc = 0.
*                APPEND lv_line TO lt_raw.
*                lv_length = lv_length + xstrlen( lv_line ).
*              ENDIF.
*            ENDWHILE.
            CLOSE DATASET lv_fullpath.
          ENDIF.

          " RAW → XSTRING konvertieren
*          CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
*            EXPORTING
*              input_length = lv_length
*            IMPORTING
*              buffer       = lv_pdf_xstring
*            TABLES
*              binary_tab   = lt_raw.

*          lv_filename = lv_file.
*          lv_flength  = lv_filesize.

          lv_length = xstrlen( lv_xstring ).
          lv_flength = lv_length.

          "----------------------------------------------------------
          " Datei im SAP-Archiv ablegen
          "----------------------------------------------------------
          IF lv_object_id IS NOT INITIAL AND iv_test IS INITIAL.
            CALL FUNCTION 'ARCHIV_CREATE_TABLE'
              EXPORTING
                ar_object                = lv_ar_object
                object_id                = lv_object_id
                sap_object               = iv_sap_ob
                flength                  = lv_flength
                doc_type                 = iv_doc_ty
                document                 = lv_xstring
*                document                 = lv_pdf_xstring
*                mandt                    = iv_client
*                filename                 = lv_filename
              IMPORTING
                outdoc                   = ls_outdoc
              EXCEPTIONS
                error_archiv             = 1
                error_communicationtable = 2
                error_connectiontable    = 3
                error_kernel             = 4
                error_parameter          = 5
                error_user_exit          = 6
                error_mandant            = 7
                blocked_by_policy        = 8
                OTHERS                   = 9.

            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ELSE.
              ls_archivierung-processed = 'X'.
            ENDIF.
          ENDIF.

          "----------------------------------------------------------
          " Verschieben der Datei nach erfolgreicher Archivierung
          "----------------------------------------------------------
          lv_source_file = lv_file.
          lv_target_file = lv_file.
          lv_source_dic  = iv_path.

          IF iv_test IS INITIAL.
            IF ls_archivierung-processed = 'X'.
              lv_target_dic = iv_path && 'verarbeitet'.

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

                DELETE DATASET lv_fullpath.

                IF sy-subrc <> 0.
                  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                ENDIF.

              ENDIF.
            ELSE.
              lv_target_dic = iv_path && 'fehlerhaft'.

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

                DELETE DATASET lv_fullpath.

                IF sy-subrc <> 0.
                  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
                ENDIF.

              ENDIF.
            ENDIF.
          ENDIF.

          " Ergebnisse in interne Tabelle übernehmen
          IF ls_archivierung IS NOT INITIAL.
            INSERT ls_archivierung INTO TABLE lt_archivierung.
          ENDIF.

        ENDIF.

      ENDLOOP.

      "----------------------------------------------------------
      " Schreibvorgang in YFI_ARCHIVIERUNG
      "----------------------------------------------------------
      IF lt_archivierung IS INITIAL.
        LOOP AT lt_archivierung ASSIGNING FIELD-SYMBOL(<ls_arc>).

          INSERT yfi_archivierung FROM <ls_arc>.

          IF sy-subrc = 4.
            " 4 = Duplicate key → Eintrag existiert schon
            MESSAGE 'Eintrag existiert bereits in YFI_ARCHIVIERUNG' TYPE 'I'.
          ELSEIF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

        ENDLOOP.
      ELSE.
        LOOP AT lt_archivierung ASSIGNING FIELD-SYMBOL(<ls_msg>).
          ls_arch_msg-file = <ls_msg>-filename.
          ls_arch_msg-processable = <ls_msg>-processed.
          ls_arch_msg-bukrs = <ls_msg>-bukrs.
          ls_arch_msg-belnr = <ls_msg>-belnr.
          ls_arch_msg-gjahr = <ls_msg>-gjahr.
          IF iv_test IS NOT INITIAL.
            ls_arch_msg-msg = text-010.
          ELSEIF <ls_msg>-processed = abap_true.
            ls_arch_msg-msg = text-011.
          ELSE.
            ls_arch_msg-msg = text-012.
          ENDIF.
          APPEND ls_arch_msg TO lt_arch_msg.
        ENDLOOP.
      ENDIF.

      DATA: lr_table TYPE REF TO cl_salv_table.
      TRY.
          cl_salv_table=>factory(
            IMPORTING
              r_salv_table = lr_table
            CHANGING
              t_table      = lt_arch_msg ).
        CATCH cx_salv_msg.                              "#EC NO_HANDLER
      ENDTRY.
      lr_table->display( ).

      "FISpaf20260323 OSS439004 ende

    ENDIF.
  ENDMETHOD.
