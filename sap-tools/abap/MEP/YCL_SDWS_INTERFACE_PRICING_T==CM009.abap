  METHOD fill_tkomp.
*      IMPORTING is_import TYPE ysdws_tpricing_i_s
*      RETURNING VALUE(rt_komp) type VA_KOMp_T
*      RAISING   ycx_sdws_interface.

    DATA ls_komk  TYPE komk.
    DATA ls_komp  TYPE komp.

    DATA ls_t001  TYPE t001.
    DATA ls_t001w TYPE t001w.
    DATA ls_t134  TYPE t134 ##NEEDED.
    DATA ls_tvko  TYPE tvko ##NEEDED.
    DATA ls_tvta  TYPE tvta ##NEEDED.
    DATA ls_mara  TYPE mara.
    " TODO: variable is assigned but only used in commented-out code (ABAP cleaner)
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA ls_marm  TYPE marm.
    DATA ls_mvke  TYPE mvke.
    DATA ls_mlan  TYPE mlan.
    " TODO: variable is assigned but never used (ABAP cleaner)
*    DATA ls_kuagv TYPE kuagv.
    DATA ls_wrf6  TYPE wrf6.
    DATA lv_kposn TYPE kalp-kposn.
    DATA lv_aktnr TYPE komp-aktnr.
    DATA ls_mbew  TYPE mbew.
    DATA lv_bwkey TYPE bwkey.

    LOOP AT is_import-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>). "#EC CI_SORTED

      ms_pispr-matnr = <ls_mat>-i_matnr.
      ms_pispr-werks = is_import-i_werks.

      IF ms_pispr-werks IS INITIAL.
        fetch_maapv( is_mtcom = VALUE #( matnr = <ls_mat>-i_matnr
                                         vkorg = is_import-i_vkorg
                                         vtweg = is_import-i_vtweg ) ).
        MOVE-CORRESPONDING ms_maapv TO ms_plant_determination-i.

        ms_pispr-werks = NEW ycl_sdpf_finding_plant( )->get_with_all_routines( is_data = ms_plant_determination ).
        IF ms_pispr-werks IS INITIAL AND mv_kun_werks IS INITIAL. " C415062

          RAISE EXCEPTION TYPE ycx_sdws_interface      " C415062
            EXPORTING      " C415062
                      textid = ycx_sdws_interface=>empty_werks.      " C415062
        ENDIF.
      ENDIF.

      CALL FUNCTION 'DETERMIN_BWKEY_BUKRS_FOR_PLANT'
        EXPORTING werk  = ms_pispr-werks
        IMPORTING bwkey = lv_bwkey.

      CALL FUNCTION 'MBEW_SINGLE_READ'
        EXPORTING
*                   KZRFB             = ' '
*                   MAXTZ             = 0
                   matnr             = ms_maapv-matnr
                   bwkey             = lv_bwkey
                   bwtar             = space
*                   SPERRMODUS        = ' '
*                   STD_SPERRMODUS    = ' '
        IMPORTING  wmbew             = ls_mbew
*                   O_MBEW            =
        EXCEPTIONS lock_on_mbew      = 1
                   lock_system_error = 2
                   wrong_call        = 3
                   not_found         = 4
                   OTHERS            = 5.
      IF sy-subrc <> 0.
        " Implement suitable error handling here
        ls_mbew-peinh = ms_maapv-scmng.
      ENDIF.

      ms_pispr-vrkme = ms_maapv-schme.

      CALL FUNCTION 'PISPR_FILL'
        EXPORTING  pi_bukrs_lesen              = ' '
                   pi_matnr_lesen              = 'X'
                   pi_vrkme_lesen              = 'X'
                   pi_wrf6_lesen               = 'X'
                   pi_stack                    = 'X'
        IMPORTING  pe_i_t001                   = ls_t001
                   pe_i_t001w                  = ls_t001w
                   pe_i_t134                   = ls_t134
*                   pe_i_tvko                   = ls_tvko
*                   pe_i_tvkov                  = ls_tvkov
*                   pe_i_tvta                   = ls_tvta
                   pe_i_mara                   = ls_mara
                   pe_i_marm                   = ls_marm
                   pe_i_mvke                   = ls_mvke
                   pe_i_mlan                   = ls_mlan
*                   pe_i_kuagv                  = ls_kuagv
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

      DATA(lt_marm) = get_marm( ls_mara-matnr ).         "#EC CI_SORTED

*      CLEAR lv_kposn.

      LOOP AT lt_marm ASSIGNING FIELD-SYMBOL(<ame>)
           WHERE    yy_scale_prio > 0
                 OR meinh         = ms_pispr-vrkme.
*        meinh = ls_mara-meins OR
*        meinh = ls_mvke-vrkme.

        IF     <ame>-meinh    = ls_mara-meins
           AND ls_mvke-vrkme <> space
           AND ls_mvke-vrkme <> ls_mara-meins.
          CONTINUE.
        ENDIF.

        DATA(lv_rest) = lv_kposn MOD 10.
        IF lv_rest <> 0.
          lv_kposn = lv_kposn - lv_rest.
        ENDIF.
        lv_kposn = lv_kposn + 10.

        IF <ame>-yy_scale_prio > 0.
          ms_pispr-vrkme = <ame>-meinh.
          ms_pispr-mgame = <ame>-umren.
"        ELSEIF ms_maapv-schme <> space AND ms_maapv-scmng > 0.
        ELSEIF ms_maapv-schme <> space AND ls_mbew-peinh > 0.
          ms_pispr-vrkme = ms_maapv-schme.
*          ms_pispr-mgame = ms_maapv-scmng.
          ms_pispr-mgame = ls_mbew-peinh.
        ELSE.
          ms_pispr-vrkme = <ame>-meinh.
          ms_pispr-mgame = <ame>-umren.
        ENDIF.

        IF ms_maapv-mtpos_mara IN mr_stl.
          DATA(lt_stpx) = bom_explosion( is_pispr = ms_pispr
                                         is_ame   = <ame> ).
        ENDIF.

        " ------------------------------------------------> KOMP füllen
        CALL FUNCTION 'WV_KOMP_FILL_V'
          EXPORTING pi_kposn   = lv_kposn
                    pi_aktnr   = lv_aktnr
                    pi_i_spr   = ms_pispr
                    pi_i_t001w = ls_t001w
                    pi_i_wrf6  = ls_wrf6
                    pi_i_t001  = ls_t001
                    pi_i_mara  = ls_mara
                    pi_i_mvke  = ls_mvke
                    pi_i_marm  = <ame>
                    pi_i_mlan  = ls_mlan
                    pi_i_komk  = ls_komk
                    pi_vorga   = '00'
          IMPORTING pe_i_komp  = ls_komp.

        " KOMP ergänzen
        ls_komp-taxps      = lv_kposn.
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

        ls_komp-aupos      = lv_kposn.
        ls_komp-ix_komk    = 1.     " ls_komk-ix_komk.

        " Ermitteln Preislistentyp aus Kondition YPLE-für Naturtalrabattfindung
        ycl_sd_natrab=>mo_singleton->set_pltyp_for_pricing( EXPORTING iv_trtyp = 'V'
                                                                      is_komk  = ls_komk
                                                                      is_komp  = ls_komp
                                                                      iv_kalsm = ls_komk-kalsm
                                                                      iv_kalnb = ms_t683v-kalnb
                                                            CHANGING  cv_pltyp = ls_komp-/fis/pltyp_kompazd ).

        APPEND ls_komp TO rt_komp.

        LOOP AT lt_stpx ASSIGNING FIELD-SYMBOL(<stpx>).
          mv_group_logic_required = abap_true.
          IF ls_komp-uepos IS INITIAL.
            ls_komp-uepos = ls_komp-kposn.
          ENDIF.
          lv_kposn = lv_kposn + 1.
          ls_komp-kposn = lv_kposn.
          ls_komp-matnr = <stpx>-idnrk.
          add_bom_komponent( EXPORTING is_stpx = <stpx>
                             CHANGING  cs_komp = ls_komp  ).
          APPEND ls_komp TO rt_komp.
        ENDLOOP.

        REFRESH lt_stpx.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
