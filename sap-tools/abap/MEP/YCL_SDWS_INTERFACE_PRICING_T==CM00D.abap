  METHOD bom_explosion.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA ls_cstmat  TYPE cstmat.
    DATA lv_qty_hdr TYPE gamng.

    lv_qty_hdr = is_ame-umrez / is_ame-umren.

    " Stückliste auflösen
    CALL FUNCTION 'CS_BOM_EXPL_MAT_V2'
      EXPORTING  aufsw                 = ' '
                 mtnrv                 = is_pispr-matnr
                 werks                 = is_pispr-werks
                 datuv                 = is_pispr-prsdt
                 capid                 = 'SD01'
                 ehndl                 = '1'                   " ???
                 emeng                 = lv_qty_hdr
                 mbwls                 = ' '
                 mehrs                 = abap_true             " ???
*                 mehrs                 = space
                 salww                 = abap_true
                 rndkz                 = '2'
*                 stlal                 = da_mastb-stlal
                 aumgb                 = abap_true
      IMPORTING  topmat                = ls_cstmat
      TABLES     stb                   = rt_xstb
      EXCEPTIONS alt_not_found         = 1
                 call_invalid          = 2
                 material_not_found    = 3
                 missing_authorization = 4
                 no_bom_found          = 5
                 no_plant_data         = 6
                 no_suitable_bom_found = 7.
  ENDMETHOD.
