  METHOD pricing.
*-----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*-----------------------------------------------------------------------
*Leutbecher |22.08.2023                                     |C413064
* PositionsID zur besseren Zuordnung von der anfragenden Artikeln      |
*-----------------------------------------------------------------------
    DATA ls_komk  TYPE komk.
    DATA ls_komp  TYPE komp.
    DATA lt_xkomv TYPE va_komv_t.
    DATA lv_knprs TYPE t683-knprs_v.
*    DATA ls_maapv TYPE maapv.
    DATA lt_komk  TYPE STANDARD TABLE OF komk.
    DATA ls_e_kond TYPE ysdws_pricing_kond_e_s.
    DATA lr_relevant_stunr TYPE RANGE OF komv-stunr.

    DATA:
      ls_t001  TYPE t001,
      ls_t001w TYPE t001w,
      ls_t134  TYPE t134        ##NEEDED,
      ls_tvko  TYPE tvko        ##NEEDED,
      ls_tvkov TYPE tvkov,
      ls_tvta  TYPE tvta        ##NEEDED,
      ls_mara  TYPE mara,
      ls_marm  TYPE marm,
      ls_mvke  TYPE mvke,
      ls_mlan  TYPE mlan,
      ls_kuagv TYPE kuagv,
      ls_wrf6  TYPE wrf6,
      ls_pispr TYPE pispr,
      lv_kposn TYPE kalp-kposn VALUE '000010',
      lv_aktnr TYPE komp-aktnr.


    CALL FUNCTION 'PRICING_TYPE_DETERMINE'
      EXPORTING
        popup_i = ' '
        kvewe_i = ycl_sdws_interface_all=>mc_kvewe_a
        kappl_i = ycl_sdws_interface_all=>mc_kappl_v
        kalsm_i = is_import-i_kalsm
      IMPORTING
        knprs_e = lv_knprs.


    LOOP AT is_import-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>).

      CLEAR ls_pispr.
      CLEAR ls_komk.
      CLEAR ls_komp.
      CLEAR lt_xkomv[].

* ---------------------------------------->   Struktur PISPR belegen.
      ls_pispr-kunnr = is_import-i_kunnr.
      ls_pispr-matnr = <ls_mat>-i_matnr.
      IF <ls_mat>-i_vrkme IS NOT INITIAL.
        ls_pispr-vrkme = ycl_sdws_interface_all=>get_instance( )->convert_iso_meins_so_sap_code(
                              iv_isocode_unit = <ls_mat>-i_vrkme ).
      ENDIF.
      ls_pispr-vkorg = ycl_sdws_interface_all=>get_instance( )->mc_default_vkorg.
      ls_pispr-vtweg = ycl_sdws_interface_all=>get_instance( )->mc_default_vtweg.
      ls_pispr-spart = ycl_sdws_interface_all=>get_instance( )->mc_default_spart.
      ls_pispr-werks = is_import-i_werks.
      IF is_import-i_prdat IS INITIAL.
        ls_pispr-prsdt = sy-datlo.
      ELSE.
        ls_pispr-prsdt = is_import-i_prdat.
      ENDIF.

      CALL FUNCTION 'PISPR_FILL'
        EXPORTING
          pi_bukrs_lesen              = 'X'
          pi_matnr_lesen              = 'X'
          pi_vrkme_lesen              = 'X'
          pi_wrf6_lesen               = 'X'
          pi_stack                    = 'X'
        IMPORTING
          pe_i_t001                   = ls_t001
          pe_i_t001w                  = ls_t001w
          pe_i_t134                   = ls_t134
          pe_i_tvko                   = ls_tvko
          pe_i_tvkov                  = ls_tvkov
          pe_i_tvta                   = ls_tvta
          pe_i_mara                   = ls_mara
          pe_i_marm                   = ls_marm
          pe_i_mvke                   = ls_mvke
          pe_i_mlan                   = ls_mlan
          pe_i_kuagv                  = ls_kuagv
          pe_i_wrf6                   = ls_wrf6
        CHANGING
          px_i_spr                    = ls_pispr
        EXCEPTIONS
          plant_not_found             = 1
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

* ---------------------------------------------> KOMK füllen
      CALL FUNCTION 'WV_KOMK_FILL_V'
        EXPORTING
          pi_i_spr   = ls_pispr
          pi_i_t001  = ls_t001
          pi_i_t001w = ls_t001w
          pi_i_tvkov = ls_tvkov
          pi_i_kuagv = ls_kuagv
          pi_vorga   = '00'
        IMPORTING
          pe_i_komk  = ls_komk.

* Komk ergänzen:
      MOVE-CORRESPONDING ls_kuagv TO ls_komk.               "#EC ENHOK

      IF is_import-i_prdat IS INITIAL.
        ls_komk-prsdt     = sy-datlo.
      ELSE.
        ls_komk-prsdt     = is_import-i_prdat.
      ENDIF.
      ls_komk-vbtyp     = 'C'.
      ls_komk-kalsm     = is_import-i_kalsm.

* vorliegenedes 01 initialisiert nicht alle Tabellen und schaukeln somit hoch
      ls_komk-kvorg = space.
      " Aussendienstmitarbeiter
*      SELECT SINGLE kunn2 INTO ls_komk-yy_kunya
*        FROM knvp
*        WHERE kunnr = is_import-i_kunnr
*        AND   vkorg = ls_pispr-vkorg
*        AND   vtweg = ls_pispr-vtweg
*        AND   spart = ls_pispr-spart
*        AND   parvw = ycl_sdbf=>mc_parvw_ya.
      SELECT kunn2 INTO ls_komk-yy_kunya  UP TO 1 ROWS     "FISJL20200429  OSS336178  HANADB
       FROM knvp
        WHERE kunnr = is_import-i_kunnr
        AND   vkorg = ls_pispr-vkorg
        AND   vtweg = ls_pispr-vtweg
        AND   spart = ls_pispr-spart
        AND   parvw = ycl_sdbf=>mc_parvw_ya ORDER BY PRIMARY KEY.
      ENDSELECT.
* Pispr ergänzen:
      IF <ls_mat>-i_menge IS NOT INITIAL.
        ls_pispr-mgame = <ls_mat>-i_menge.
      ELSE.
        " FIS/eu 190417 Falls Menge leer...via MARM umrechhnen
*        SELECT SINGLE umrez, umren INTO @DATA(ls_marm2)
*          FROM marm
*          WHERE matnr = @<ls_mat>-i_matnr
*          AND   meinh = @<ls_mat>-i_vrkme.
        IF ls_marm-umrez IS NOT INITIAL AND ls_marm-umren IS NOT INITIAL.
          ls_pispr-mgame = 1 / ls_marm-umrez * ls_marm-umren.
        ELSE.
          ls_pispr-mgame = 1.
        ENDIF.
      ENDIF.

*  ps_komk-taxk1     = '1'.          "Steuerklassifikation Kunde

** Die Kundengruppe 01!!
*  MOVE '01' TO ps_komk-kdgrp.


* ------------------------------------------------> KOMP füllen
      CALL FUNCTION 'WV_KOMP_FILL_V'
        EXPORTING
          pi_kposn   = lv_kposn
          pi_aktnr   = lv_aktnr
          pi_i_spr   = ls_pispr
          pi_i_t001w = ls_t001w
          pi_i_wrf6  = ls_wrf6
          pi_i_t001  = ls_t001
          pi_i_mara  = ls_mara
          pi_i_mvke  = ls_mvke
          pi_i_marm  = ls_marm
          pi_i_mlan  = ls_mlan
          pi_i_komk  = ls_komk
          pi_vorga   = '00'
        IMPORTING
          pe_i_komp  = ls_komp.

* KOMP ergänzen
      ls_komp-taxps = lv_kposn.
      ls_komp-evrwr = 'X'.
      ls_komp-prsok = 'A'.

      " FIS/eu 190417 Falls Menge leer...via MARM umrechhnen
      IF <ls_mat>-i_menge IS NOT INITIAL.
        ls_komp-mgame = <ls_mat>-i_menge.
      ELSE.
        IF ls_marm-umrez IS NOT INITIAL AND ls_marm-umren IS NOT INITIAL.
          ls_komp-mgame = 1 / ls_marm-umrez * ls_marm-umren.
        ELSE.
          ls_komp-mgame = 1.
        ENDIF.
      ENDIF.

      ls_komp-yy_prpa = ycl_sdpf=>get_instance( )->get_price_partner(
                                              iv_kunag = ls_pispr-kunnr
                                              iv_vkorg = ls_pispr-vkorg ).


** Einkäufergruppe FIS/eu 050106
*  MOVE p_ekgrp TO ps_komp-yyekgrp.

* Zeitraum-Felder versorgen
      ls_komp-anz_tage   = 1.
      ls_komp-anz_monate = 1.
      ls_komp-anz_jahre  = 1.
      ls_komp-anz_wochen = 1.
      ls_komp-stf_tage   = 1.
      ls_komp-stf_monate = 1.
      ls_komp-stf_jahre  = 1.
      ls_komp-stf_wochen = 1.

      ls_komp-aupos   = lv_kposn.
      ls_komp-ix_komk = ls_komk-ix_komk.

      "FISHD20240506 OSS425607 -->
      ycl_sdpf=>get_instance( )->get_price_for_gross( EXPORTING
                                                        iv_matnr         = ls_komp-matnr
                                                        iv_vrkme         = ls_komp-vrkme
                                                        iv_meins         = ls_komp-meins
                                                        iv_kwmeng        = CONV #( ls_komp-mgame )
                                                      CHANGING
                                                        cv_yy_scale_prio = ls_komp-yy_scale_prio ).
      "FISHD20240506 OSS425607 <--

      CALL FUNCTION 'PRICING_REFRESH'
        TABLES
          tkomk = lt_komk
          tkomv = lt_xkomv.

      CALL FUNCTION 'PRICING'
        EXPORTING
          calculation_type = lv_knprs
          comm_head_i      = ls_komk
          comm_item_i      = ls_komp
        IMPORTING
          comm_head_e      = ls_komk
          comm_item_e      = ls_komp
        TABLES
          tkomv            = lt_xkomv.

      CALL FUNCTION 'PRICING_DIALOG_PAI'
        EXPORTING
          comm_head_i = ls_komk
          comm_item_i = ls_komp
        IMPORTING
          comm_head_e = ls_komk
          comm_item_e = ls_komp
        TABLES
          tkomv       = lt_xkomv.


      IF is_import-i_all_detail IS INITIAL.

        TRY.
            CALL METHOD ycl_stvarvc=>get_selop
              EXPORTING
                i_pname  = 'YSDWS_INTERFACE_PRICING'
                i_quali  = 'STUNR'
              IMPORTING
                et_selop = lr_relevant_stunr.
          CATCH ycx_bc_err      ##no_handler.
        ENDTRY.

      ENDIF.

      LOOP AT lt_xkomv ASSIGNING FIELD-SYMBOL(<ls_xkomv>) WHERE stunr IN lr_relevant_stunr.

        CLEAR ls_e_kond.
        ls_e_kond-bdcnt = <ls_mat>-i_bdcnt.                 "C413064
        ls_e_kond-matnr = <ls_mat>-i_matnr.
        ls_e_kond-konms = <ls_xkomv>-konms.
        ls_e_kond-vrkme = <ls_mat>-i_vrkme.
        ls_e_kond-stunr = <ls_xkomv>-stunr.
        ls_e_kond-kwert = <ls_xkomv>-kwert.
        ls_e_kond-kschl = <ls_xkomv>-kschl.
        ls_e_kond-kawrt = <ls_xkomv>-kawrt.
        ls_e_kond-kbetr = <ls_xkomv>-kbetr.
        ls_e_kond-waers = <ls_xkomv>-waers.
        ls_e_kond-kkurs = <ls_xkomv>-kkurs.
        ls_e_kond-kpein = <ls_xkomv>-kpein.
        ls_e_kond-kmein = <ls_xkomv>-kmein.

        APPEND ls_e_kond TO es_export-et_kond.

      ENDLOOP.

    ENDLOOP.

    es_export-e_sessionid = is_import-i_sessionid.

  ENDMETHOD.
