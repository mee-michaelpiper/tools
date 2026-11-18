private section.

  constants MC_DFLT_SPRAS type SPRAS value 'E' ##NO_TEXT.
  constants MC_TABIX_1 type SY-TABIX value 1 ##NO_TEXT.
  constants MC_INTF_TYPE_IN type YSDWS_INTERFACE_TYPE value 'I' ##NO_TEXT.
  constants MC_INTF_TYPE_OUT type YSDWS_INTERFACE_TYPE value 'O' ##NO_TEXT.
  class-data MS_LOG_TIME type YSDWS_LOG_TIME .

  methods SPLITT_STRING2TAB
    importing
      !IV_STRING type ANY
    exporting
      !RT_COMPONENTS type TEXT_LINES .
  methods GET_LOG_VALUES_FROM_STRUCTURE
    importing
      !IS_STRUCTURE type ANY
      !IS_LOG_TIME type YSDWS_LOG_TIME
      !IV_INTERFACE_TYPE type YSDWS_INTERFACE_TYPE
      !IV_TABIX type SY-TABIX
    changing
      !CT_LOG_VALUE type YSDWS_LOG_VALUE_TT .
  methods CHECK_FOR_EXISTING_SESSIONID
    importing
      !IV_SESSIONID type YSDWS_SESSIONID
    raising
      YCX_SDWS_INTERFACE .
  methods CHECK_CALLER
    importing
      !IV_SESSIONID type YSDWS_SESSIONID
    raising
      YCX_SDWS_INTERFACE .
