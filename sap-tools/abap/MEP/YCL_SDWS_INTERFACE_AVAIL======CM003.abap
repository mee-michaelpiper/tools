  METHOD availability_check.

    DATA ls_kond  TYPE ysdws_availability_mat_e_s.
    DATA lv_meinh TYPE meinh.
    DATA lt_wmdvsx TYPE STANDARD TABLE OF bapiwmdvs.
    DATA ls_wmdvsx TYPE bapiwmdvs.
    DATA lt_wmdvex TYPE STANDARD TABLE OF bapiwmdve.

*    E_SESSIONID 1 Type  YSDWS_SESSIONID
*    ET_KOND 1 Type  YSDWS_AVAILABILITY_MAT_E_TT
*    ET_RETURNS  1 Type  YSDWS_RETURN_E_TT

    es_export-e_sessionid = is_import-i_sessionid.

    LOOP AT is_import-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>).

      CLEAR lt_wmdvsx[].
      CLEAR lt_wmdvex[].

      IF <ls_mat>-i_vrkme IS NOT INITIAL.
        lv_meinh = ycl_sdws_interface_all=>get_instance( )->convert_iso_meins_so_sap_code( <ls_mat>-i_vrkme ).
      ELSE.
        lv_meinh = ycl_sdws_interface_all=>get_instance( )->get_material_vrkme(
               iv_matnr = <ls_mat>-i_matnr
               iv_vkorg = is_import-i_vkorg
               iv_vtweg = is_import-i_vtweg
           ).
      ENDIF.

      IF <ls_mat>-i_req_date IS NOT INITIAL AND
         <ls_mat>-i_req_qty  IS NOT INITIAL AND
         lv_meinh            IS NOT INITIAL.

        ls_wmdvsx-req_date = <ls_mat>-i_req_date.
        ls_wmdvsx-req_qty  = <ls_mat>-i_req_qty.
        APPEND ls_wmdvsx TO lt_wmdvsx.
      ENDIF.

      CALL FUNCTION 'BAPI_MATERIAL_AVAILABILITY'
        EXPORTING
          plant      = <ls_mat>-i_werks    " Werk
          material   = <ls_mat>-i_matnr    " Materialnummer
          unit       = lv_meinh    " Mengeneinheit für Anzeige
          check_rule = mc_check_rule_a    " Prüfregel
*         stge_loc   =     " Lagerort
*         batch      =     " Charge
*         customer   =     " Kundennummer
*         doc_number =     " Belegnummer
*         itm_number =     " Positionsnummer
*         wbs_elem   =     " PSP-Element
*         stock_ind  =     " Sonderbestandskennzeichen
*         dec_for_rounding   =     " Anzahl Dezimalstellen, auf die gerundet werden soll
*         dec_for_rounding_x =     " Änderungsinformation zum zugehörigen Nutzdatenfeld
*         read_atp_lock      =     " Steuerungskennzeichen für Verfügbarkeitsprüfung
*         read_atp_lock_x    =     " Änderungsinformation zum zugehörigen Nutzdatenfeld
*         material_evg       =
*         sgt_rcat   =     " Bedarfssegment
*        IMPORTING
*         endleadtme =     " Ende der Wiederbeschaffungszeit
*         av_qty_plt =     " Verfügbare Menge auf Werksebene
*         dialogflag =     " Kennzeichen (X=nicht verfügbar, N=keine Prüfung)
*         return     =
        TABLES
          wmdvsx     = lt_wmdvsx    " Eingabetabelle (Termin und Menge)
          wmdvex     = lt_wmdvex.    " Ausgabetabelle (Termin(e) und ATP-Menge(n))

      LOOP AT lt_wmdvex ASSIGNING FIELD-SYMBOL(<ls_wmdvex>).

        CLEAR ls_kond.

        ls_kond-bdcnt    = <ls_mat>-i_bdcnt.
        ls_kond-com_date = <ls_wmdvex>-com_date.

        ycl_sdws_interface_all=>get_instance( )->get_week_from_com_date(
            EXPORTING
              is_wmdvex = <ls_wmdvex>
            CHANGING
              cs_kond = ls_kond ).

        ls_kond-com_qty  = <ls_wmdvex>-com_qty.
        ls_kond-matnr    = <ls_mat>-i_matnr.
        ls_kond-req_date = <ls_wmdvex>-req_date.
        ls_kond-req_qty  = <ls_wmdvex>-req_qty.
        ls_kond-werks    = <ls_mat>-i_werks.

        APPEND ls_kond TO es_export-et_kond.

      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.
