  METHOD end_log.
*        IMPORTING
*            is_import_avail type YSDWS_AVAILABILITY_I_S OPTIONAL
*            is_export_avail type YSDWS_AVAILABILITY_E_S optional
*            is_import_pricing TYPE ysdws_pricing_i_s OPTIONAL
*            is_export_pricing TYPE ysdws_pricing_e_s OPTIONAL.
*      !IS_IMPORT_SALESORDER type YSDWS_SALESORDER_I_S optional
*      !IS_EXPORT_SALESORDER type YSDWS_SALESORDER_E_S optional .

    DATA lv_timestampl TYPE timestampl.

    GET TIME STAMP FIELD lv_timestampl.

    WRITE lv_timestampl TIME ZONE 'UTC' TO ms_log_time-timestamp_response.

    DATA(ls_log_time) = ms_log_time.
    DATA(ls_import_avail) = is_import_avail. ##operator.
    DATA(ls_export_avail) = is_export_avail. ##operator.
    DATA(ls_import_pricing) =  is_import_pricing. ##operator.
    DATA(ls_export_pricing) =  is_export_pricing. ##operator.
    DATA(ls_import_salesorder) = is_import_salesorder. ##operator.
    DATA(ls_export_salesorder) = is_export_salesorder. ##operator.

    TRY.
        ycl_stvarvc=>check_selop(
          EXPORTING
            i_pname    =  'LOG'   " Parametername
             i_quali    = mv_caller   "Aufruferanwendung " Qualifier
            i_tcode    = 'YSDWS_INTERFACE'   " Report oder Tranaktion
            i_selvalue = ms_log_time-interface ).

        CALL FUNCTION 'Y_SDWS_LOG_VB' IN UPDATE TASK
          EXPORTING
            is_log_time          = ls_log_time        " Webshop: Log / Protokoll-Tabelle mit Zeitangaben
            is_import_avail      = ls_import_avail    " Webshop: Verfügbarkeitsprüfung - Importstruktur
            is_export_avail      = ls_export_avail    " Webshop: Verffügbarkeitsprüfung - Exportstruktur
            is_import_pricing    = ls_import_pricing  " Webshop: Preisanfrage - Importstruktur
            is_export_pricing    = ls_export_pricing  " Webshop: Preisanfrage - Exportstruktur
            is_import_salesorder = ls_import_salesorder
            is_export_salesorder = ls_export_salesorder.

        COMMIT WORK.

      CATCH ycx_bc_err.
        CLEAR: ls_import_avail, ls_export_avail, ls_import_pricing, ls_export_pricing,
              ls_import_salesorder, ls_export_salesorder.
    ENDTRY.




  ENDMETHOD.
