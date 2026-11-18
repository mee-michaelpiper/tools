  PRIVATE SECTION.
    CONSTANTS mc_chare TYPE char1 VALUE 'E' ##NO_TEXT.

    TYPES tyt_marm TYPE TABLE OF marm WITH DEFAULT KEY.

    DATA mr_relevant_stunr TYPE RANGE OF komv-stunr.
    data ms_import type ysdws_tpricing_i_s.
    DATA mv_kun_werks TYPE werks_d.
    data mr_stl                  type RANGE OF mtpos_mara.
    data ms_plant_determination  TYPE yif_ex_badi_find_plant=>ty_s_selvar.
    DATA ms_pispr                TYPE pispr.
    data mV_GROUP_LOGIC_REQUIRED TYPE  BOOLEAN.
    data ms_t683v type t683v.

    METHODS pricing_plausi_check
      CHANGING ct_returns TYPE ysdws_return_e_tt
      RAISING  ycx_sdws_interface.

    METHODS pricing
      EXPORTING es_export TYPE ysdws_tpricing_e_s
      RAISING   ycx_sdws_interface.

    METHODS set_default_pricing_kalsm
      RAISING   ycx_sdws_interface.

    METHODS convert_matnr
      IMPORTING iv_matnr        TYPE matnr
      RETURNING VALUE(rv_matnr) TYPE matnr
      RAISING   ycx_sdws_interface.

    METHODS get_marm
      IMPORTING iv_matnr       TYPE matnr
      RETURNING VALUE(rt_marm) TYPE tyt_marm.

    METHODS get_knvp
      IMPORTING is_import      TYPE ysdws_tpricing_i_s
                is_pispr       TYPE pispr
      RETURNING VALUE(rs_knvp) TYPE knvp.

   methods fill_tkomk
      IMPORTING is_import TYPE ysdws_tpricing_i_s
      RETURNING VALUE(rt_komk) type VA_KOMK_T
      RAISING   ycx_sdws_interface.

   methods fill_tkomp
      IMPORTING is_import TYPE ysdws_tpricing_i_s
      RETURNING VALUE(rt_komp) type VA_KOMp_T
      RAISING   ycx_sdws_interface.

   methods prepare_response
    IMPORTING it_result type prct_result_multi_item it_komp type VA_KOMp_T it_xkomv type va_komv_t
      it_komk type  VA_KOMK_T
             RETURNING VALUE(rt_mat) TYPE YSDWS_TPRICING_E_T.

 methods constructor
     IMPORTING is_import TYPE ysdws_tpricing_i_s.

 methods bom_explosion
      IMPORTING is_pispr       TYPE pispr
                is_ame    type marm
     RETURNING VALUE(rt_xstb) TYPE DMS_TBL_STPOX.

methods determine_pricing_type
  RETURNING VALUE(rv_knprs) type  t683-knprs_v.

  methods         add_bom_komponent
  importing is_stpx type STPOX
         changing cs_komp type KOMp.

