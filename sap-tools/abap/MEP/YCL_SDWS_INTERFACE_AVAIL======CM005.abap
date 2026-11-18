  METHOD material_availability.

    DATA ls_kond  TYPE ysdws_atp_mat_e_s.
    DATA lv_meinh TYPE meinh.
    DATA lt_wmdvsx TYPE STANDARD TABLE OF bapiwmdvs.
    DATA ls_wmdvsx TYPE bapiwmdvs.
    DATA lt_wmdvex TYPE STANDARD TABLE OF bapiwmdve.
    DATA lt_return TYPE fmfg_t_bapireturn.


    IF is_import-i_vrkme IS NOT INITIAL.
      lv_meinh = ycl_sdws_interface_all=>get_instance( )->convert_iso_meins_so_sap_code( is_import-i_vrkme ).
    ELSEIF ms_maapv-vrkme NE space.
      lv_meinh =  ms_maapv-vrkme.
    ELSE.
      lv_meinh =  ms_maapv-meins.
    ENDIF.

    IF is_import-i_req_date IS NOT INITIAL AND
       is_import-i_req_qty  IS NOT INITIAL AND
       lv_meinh            IS NOT INITIAL.

      ls_wmdvsx-req_date = is_import-i_req_date.
      ls_wmdvsx-req_qty  = is_import-i_req_qty.
      APPEND ls_wmdvsx TO lt_wmdvsx.
    ENDIF.

    CALL FUNCTION 'BAPI_MATERIAL_AVAILABILITY'
      EXPORTING
        plant      = is_import-i_werks    " Werk
        material   = is_import-i_matnr    " Materialnummer
        unit       = lv_meinh    " Mengeneinheit für Anzeige
        check_rule = mc_check_rule_a    " Prüfregel
*       stge_loc   =     " Lagerort
*       batch      =     " Charge
*       customer   =     " Kundennummer
*       doc_number =     " Belegnummer
*       itm_number =     " Positionsnummer
*       wbs_elem   =     " PSP-Element
*       stock_ind  =     " Sonderbestandskennzeichen
*       dec_for_rounding   =     " Anzahl Dezimalstellen, auf die gerundet werden soll
*       dec_for_rounding_x =     " Änderungsinformation zum zugehörigen Nutzdatenfeld
*       read_atp_lock      =     " Steuerungskennzeichen für Verfügbarkeitsprüfung
*       read_atp_lock_x    =     " Änderungsinformation zum zugehörigen Nutzdatenfeld
*       material_evg       =
*       sgt_rcat   =     " Bedarfssegment
*      IMPORTING
*       endleadtme =     " Ende der Wiederbeschaffungszeit
*       av_qty_plt =     " Verfügbare Menge auf Werksebene
*       dialogflag =     " Kennzeichen (X=nicht verfügbar, N=keine Prüfung)
*        return     = lt_return[]
      TABLES
        wmdvsx     = lt_wmdvsx    " Eingabetabelle (Termin und Menge)
        wmdvex     = lt_wmdvex.    " Ausgabetabelle (Termin(e) und ATP-Menge(n))

    LOOP AT lt_wmdvex ASSIGNING FIELD-SYMBOL(<ls_wmdvex>).

      CLEAR ls_kond.

      ls_kond-bdcnt    = is_import-i_bdcnt.
      ls_kond-com_date = <ls_wmdvex>-com_date.

      ls_kond-com_week = get_week_from_com_date( <ls_wmdvex> ).

      ls_kond-com_qty  = <ls_wmdvex>-com_qty.
*        ls_kond-matnr    = is_import-i_matnr.
      ls_kond-req_date = <ls_wmdvex>-req_date.
      ls_kond-req_qty  = <ls_wmdvex>-req_qty.
      ls_kond-werks    = is_import-i_werks.

      APPEND ls_kond TO et_export.


    ENDLOOP.




  ENDMETHOD.
