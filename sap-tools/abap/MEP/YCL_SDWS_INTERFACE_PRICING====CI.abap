private section.

  constants MC_CHARE type CHAR1 value 'E' ##NO_TEXT.
  data MV_KUN_WERKS type WERKS_D .

  methods PRICING_PLAUSI_CHECK
    changing
      !CS_IMPORT type YSDWS_PRICING_I_S
      !CT_RETURNS type YSDWS_RETURN_E_TT
    raising
      YCX_SDWS_INTERFACE .
  methods PRICING
    importing
      !IS_IMPORT type YSDWS_PRICING_I_S
    exporting
      !ES_EXPORT type YSDWS_PRICING_E_S
    raising
      YCX_SDWS_INTERFACE .
  methods GET_DEFAULT_PRICING_KALSM
    returning
      value(RV_KALSM) type VBAK-KALSM
    raising
      YCX_SDWS_INTERFACE .
  methods CONVERT_MATNR
    importing
      !IV_MATNR type MATNR
    returning
      value(RV_MATNR) type MATNR
    raising
      YCX_SDWS_INTERFACE .
