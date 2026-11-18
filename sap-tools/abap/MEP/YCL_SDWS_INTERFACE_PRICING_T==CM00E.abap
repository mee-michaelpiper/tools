  METHOD add_bom_komponent.
    DATA ls_komk  TYPE komk.
    DATA ls_komp  TYPE komp.

    DATA ls_t001  TYPE t001.
    DATA ls_t001w TYPE t001w.
    DATA ls_t134  TYPE t134 ##NEEDED.
    DATA ls_tvko  TYPE tvko ##NEEDED.
    DATA ls_tvta  TYPE tvta ##NEEDED.
    DATA ls_mara  TYPE mara.
    DATA ls_marm  TYPE marm.
    DATA ls_mvke  TYPE mvke.
    DATA ls_mlan  TYPE mlan.
    DATA ls_wrf6  TYPE wrf6.
    DATA lv_aktnr TYPE komp-aktnr.

    ms_pispr-matnr = is_stpx-idnrk.
    ms_pispr-mgame = is_stpx-menge.
    ms_pispr-vrkme = is_stpx-meins.

    CALL FUNCTION 'PISPR_FILL'
      EXPORTING  pi_bukrs_lesen              = ' '
                 pi_matnr_lesen              = 'X'
                 pi_vrkme_lesen              = 'X'
                 pi_wrf6_lesen               = 'X'
                 pi_stack                    = 'X'
      IMPORTING  pe_i_t001                   = ls_t001
                 pe_i_t001w                  = ls_t001w
                 pe_i_t134                   = ls_t134
*                 pe_i_tvko                   = ls_tvko
*                 pe_i_tvkov                  = ls_tvkov
*                 pe_i_tvta                   = ls_tvta
                 pe_i_mara                   = ls_mara
                 pe_i_marm                   = ls_marm
                 pe_i_mvke                   = ls_mvke
                 pe_i_mlan                   = ls_mlan
                 pe_i_wrf6                   = ls_wrf6
      CHANGING   px_i_spr                    = ms_pispr
      EXCEPTIONS plant_not_found             = 1
                 org_structure_not_completed = 2
                 vkorg_not_found             = 3
                 no_bukrs_found              = 4
                 material_not_found          = 5
                 other_error                 = 6
                 OTHERS                      = 7.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    " ------------------------------------------------> KOMP füllen
    CALL FUNCTION 'WV_KOMP_FILL_V'
      EXPORTING pi_kposn   = cs_komp-kposn
                pi_aktnr   = lv_aktnr
                pi_i_spr   = ms_pispr
                pi_i_t001w = ls_t001w
                pi_i_wrf6  = ls_wrf6
                pi_i_t001  = ls_t001
                pi_i_mara  = ls_mara
                pi_i_mvke  = ls_mvke
                pi_i_marm  = ls_marm
                pi_i_mlan  = ls_mlan
                pi_i_komk  = ls_komk
                pi_vorga   = '00'
      IMPORTING pe_i_komp  = ls_komp.

    " KOMP ergänzen
    ls_komp-taxps      = cs_komp-kposn.
    ls_komp-evrwr      = 'X'.
    ls_komp-prsok      = 'A'.
    ls_komp-yy_prpa    = ycl_sdpf=>get_instance( )->get_price_partner( iv_kunag = ms_pispr-kunnr
                                                                       iv_vkorg = ms_pispr-vkorg ).

    " Zeitraum-Felder versorgen
    ls_komp-anz_tage   = 1.
    ls_komp-anz_monate = 1.
    ls_komp-anz_jahre  = 1.
    ls_komp-anz_wochen = 1.
    ls_komp-stf_tage   = 1.
    ls_komp-stf_monate = 1.
    ls_komp-stf_jahre  = 1.
    ls_komp-stf_wochen = 1.

    ls_komp-aupos      = cs_komp-kposn.
    ls_komp-ix_komk    = ls_komk-ix_komk.

    " Ermitteln Preislistentyp aus Kondition YPLE-für Naturtalrabattfindung
    ycl_sd_natrab=>mo_singleton->set_pltyp_for_pricing( EXPORTING iv_trtyp = 'V'
                                                                  is_komk  = ls_komk
                                                                  is_komp  = ls_komp
                                                                  iv_kalsm = ls_komk-kalsm
                                                                  iv_kalnb = ms_t683v-kalnb
                                                        CHANGING  cv_pltyp = ls_komp-/fis/pltyp_kompazd ).
  ENDMETHOD.
