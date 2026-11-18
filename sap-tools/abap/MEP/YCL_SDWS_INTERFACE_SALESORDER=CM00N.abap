  METHOD change_import_data.


** Sonderlocke Verkaufsbüro /Verkäufergruppe
*if ms_order_header_in-SALES_GRP or ms_order_header_in-SALES_OFF.
*  if ms_order_header_in-SALES_OFF is INITIAL.
*    SELECT single vkbur into ms_order_header_in-SALES_OFF FROM  knvv
*           WHERE  kunnr  =
*           AND    vkorg  = ms_order_header_in-SALES_ORG.
*  endif.
*
*  SELECT        * FROM  ysdsls_idocvkgrv
*         WHERE  auart  = ___
*         AND    vkbur  = ___
*         AND    vkgrp  = ___.
*
*  ENDSELECT.
*
*endif.

  ENDMETHOD.
