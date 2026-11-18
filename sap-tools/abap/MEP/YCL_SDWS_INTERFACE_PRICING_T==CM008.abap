  METHOD fill_tkomk.
*      IMPORTING is_import TYPE ysdws_tpricing_i_s
*      RETURNING VALUE(rt_komk) type VA_KOMK_T
*      RAISING   ycx_sdws_interface.

    DATA ls_t001  TYPE t001.
    DATA ls_t001w TYPE t001w.
    DATA ls_t134  TYPE t134 ##NEEDED.
    DATA ls_tvko  TYPE tvko ##NEEDED.
    DATA ls_tvkov TYPE tvkov.
    DATA ls_tvta  TYPE tvta ##NEEDED.
    DATA ls_kuagv TYPE kuagv.
    DATA ls_komk  TYPE komk.

    CLEAR ms_pispr.
    " ---------------------------------------->   Struktur PISPR belegen.
    ms_pispr-kunnr = is_import-i_kunnr.
    ms_pispr-vkorg = is_import-i_vkorg.
    ms_pispr-vtweg = is_import-i_vtweg.
    ms_pispr-spart = is_import-i_spart.
    ms_pispr-werks = is_import-i_werks.
    IF ms_pispr-werks IS INITIAL.
    ENDIF.

    ms_pispr-prsdt = is_import-i_prdat.
    IF ms_pispr-prsdt IS INITIAL.
      ms_pispr-prsdt = sy-datlo.
    ENDIF.

    CALL FUNCTION 'PISPR_FILL'
      EXPORTING  pi_bukrs_lesen              = 'X'
*                 pi_matnr_lesen              = 'X'
*                 pi_vrkme_lesen              = 'X'
*                 pi_wrf6_lesen               = 'X'
                 pi_stack                    = 'X'
      IMPORTING  pe_i_t001                   = ls_t001
                 pe_i_t001w                  = ls_t001w
                 pe_i_t134                   = ls_t134
                 pe_i_tvko                   = ls_tvko
                 pe_i_tvkov                  = ls_tvkov
                 pe_i_tvta                   = ls_tvta
*                 pe_i_mara                   = ls_mara
*                 pe_i_marm                   = ls_marm
*                 pe_i_mvke                   = ls_mvke
*                 pe_i_mlan                   = ls_mlan
                 pe_i_kuagv                  = ls_kuagv
*                 pe_i_wrf6                   = ls_wrf6
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

    MOVE-CORRESPONDING ms_pispr TO ms_plant_determination.
    MOVE-CORRESPONDING ls_kuagv TO ms_plant_determination.

    " ---------------------------------------------> KOMK füllen
    CALL FUNCTION 'WV_KOMK_FILL_V'
      EXPORTING pi_i_spr   = ms_pispr
                pi_i_t001  = ls_t001
                pi_i_t001w = ls_t001w
                pi_i_tvkov = ls_tvkov
                pi_i_kuagv = ls_kuagv
                pi_vorga   = '00'
      IMPORTING pe_i_komk  = ls_komk.

    ls_komk-prsdt = is_import-i_prdat.
    IF ls_komk-prsdt IS INITIAL.
      ls_komk-prsdt = sy-datlo.
    ENDIF.
    ls_komk-vbtyp    = 'C'.
    ls_komk-kalsm    = is_import-i_kalsm.
    ls_komk-kvorg    = space.
    ls_komk-yy_kunya = get_knvp( is_import = is_import
                                 is_pispr  = ms_pispr )-kunn2.

    APPEND ls_komk TO rt_komk.
  ENDMETHOD.
