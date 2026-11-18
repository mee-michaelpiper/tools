  METHOD pricing_plausi_check.
*-----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*-----------------------------------------------------------------------
*Leutbecher |22.08.2023                                     |C413064
* PositionsID zur besseren Zuordnung von der anfragenden Artikeln      |
*-----------------------------------------------------------------------

    DATA lv_werks TYPE werks_d.
    DATA lo_error TYPE REF TO ycx_sdws_interface.
    DATA ls_return TYPE ysdws_return_e_s.
    DATA yls_plant TYPE yif_ex_badi_find_plant=>ty_s_selvar.

    ycl_sdws_interface_all=>get_instance( )->check_session_id( cs_import-i_sessionid ).

    get_default_values( CHANGING  cs_zielstr = cs_import ).

*    " Vertriebsbereich
*    ycl_sdws_interface_all=>get_instance( )->check_vtber( EXPORTING iv_vkorg = cs_import-i_vkorg
*                                                                    iv_vtweg = cs_import-i_vtweg
*                                                                    iv_spart = cs_import-i_spart ).

    " Werksermittlung + -prüfung.
    mv_kun_werks = ycl_sdws_interface_all=>get_instance( )->check_kunnr(
                            EXPORTING iv_kunnr = cs_import-i_kunnr
                                      iv_vkorg = cs_import-i_vkorg
                                      iv_vtweg = cs_import-i_vtweg
                                      iv_spart = cs_import-i_spart ).

    IF cs_import-i_werks IS NOT INITIAL.
      ycl_sdws_interface_all=>get_instance( )->check_werks( cs_import-i_werks ).
*    ELSEIF cs_import-i_werks IS INITIAL AND mv_kun_werks IS INITIAL.       "C415062
*      RAISE EXCEPTION TYPE ycx_sdws_interface      "C415062
*        EXPORTING      "C415062
*          textid = ycx_sdws_interface=>empty_werks.      "C415062
    ENDIF.

    "FISHD20240506 OSS425607 -->
    IF cs_import-i_kalsm IS INITIAL.
      SELECT SINGLE kalks
        FROM knvv
        INTO @DATA(lv_kalks)
       WHERE kunnr = @cs_import-i_kunnr
         AND vkorg = @cs_import-i_vkorg
         AND vtweg = @cs_import-i_vtweg
         AND spart = @cs_import-i_spart.
      IF sy-subrc = 0.
        CASE lv_kalks.
          "Meesenburg Standard (alt)
          WHEN 'M'.
            cs_import-i_kalsm = 'YVAA00'.
            "Meesenburg neu
          WHEN 'A'.
            cs_import-i_kalsm = 'YVAANP'.
          WHEN OTHERS.
        ENDCASE.
      ENDIF.
    ENDIF.
    "FISHD20240506 OSS425607 <--

    " Kalkulationsschema
    IF cs_import-i_kalsm IS INITIAL.
      cs_import-i_kalsm = get_default_pricing_kalsm( ).
    ENDIF.
    IF cs_import-i_kalsm IS NOT INITIAL.
      ycl_sdws_interface_all=>get_instance( )->check_kalsm( cs_import-i_kalsm ).
    ENDIF.

    fetch_kuwe2( is_vtcom = CORRESPONDING #( cs_import MAPPING kunnr = i_kunnr vkorg = i_vkorg vtweg = i_vtweg spart = i_spart ) ).
    MOVE-CORRESPONDING ms_knvv TO yls_plant.
    CLEAR yls_plant-dwerk.

    " Plausi-Check auf Materialeinträge -> Hier bei Fehler nicht komplett abbrechen, sondern nur je Zeile.
    " Rest bleibt in cs_import-it_mat - Tabelle für Pricing!
    LOOP AT cs_import-it_mat ASSIGNING FIELD-SYMBOL(<ls_mat>).

      DATA(lv_tabix) = sy-tabix.

      TRY.

          ycl_sdws_interface_all=>get_instance( )->check_matnr( <ls_mat>-i_matnr ).

          IF cs_import-i_werks IS INITIAL.
            fetch_maapv( is_mtcom = VALUE #( matnr = <ls_mat>-i_matnr vkorg = cs_import-i_vkorg vtweg = cs_import-i_vtweg ) ).
*            lv_werks = mv_kun_werks.         "C415062
            MOVE-CORRESPONDING ms_maapv TO yls_plant-i.


            lv_werks = NEW ycl_sdpf_finding_plant( )->get_with_all_routines( is_data = yls_plant ). "C415062
*            lv_werks = NEW ycl_sdpf_finding_plant( )->GET_with_all_routines( is_data = VALUE #( kunnr = cs_import-i_kunnr matnr = <ls_mat>-i_matnr vkorg = cs_import-i_vkorg vtweg = cs_import-i_vtweg  ) ). "C415062
            IF lv_werks IS INITIAL AND mv_kun_werks IS INITIAL. "C415062

              RAISE EXCEPTION TYPE ycx_sdws_interface      "C415062
                EXPORTING      "C415062
                  textid = ycx_sdws_interface=>empty_werks.      "C415062
            ENDIF.
          ELSE.
            lv_werks = cs_import-i_werks.
          ENDIF.

          IF <ls_mat>-i_vrkme IS NOT INITIAL.
            ycl_sdws_interface_all=>get_instance( )->check_marm_entry( iv_matnr     = <ls_mat>-i_matnr
                                                                       iv_vrkme_iso = <ls_mat>-i_vrkme ).
          ENDIF.

          ycl_sdws_interface_all=>get_instance( )->check_iso_code_unit( <ls_mat>-i_vrkme ).

        CATCH ycx_sdws_interface INTO lo_error.

          ls_return-message = lo_error->get_exception_text_with_langu( ycl_sdws_interface_all=>get_instance( )->mv_message_spras ).

          ls_return-type    = mc_chare.

*         Fehler anhand des zugeordneten verwenden, wenn dieser mitgegeben wurde           "C413064
          IF <ls_mat>-i_bdcnt IS INITIAL.                   "C413064
            ls_return-posnr   = lv_tabix.
          ELSE.                                             "C413064
            ls_return-posnr   = <ls_mat>-i_bdcnt.           "C413064
          ENDIF.                                            "C413064

          APPEND ls_return TO ct_returns.

          " Für Pricing nicht mehr benötigt, da fehlerhaft. -> löschen.
          DELETE cs_import-it_mat INDEX lv_tabix.
      ENDTRY.


    ENDLOOP.


  ENDMETHOD.
