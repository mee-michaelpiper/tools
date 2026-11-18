  METHOD get_vbeln_vakgu.

    CHECK mv_gltab IS NOT INITIAL OR mv_gltbi IS NOT INITIAL.

    IF mv_gltbi IS INITIAL.
      mv_gltbi = '99991231'.
    ENDIF.


    SELECT DISTINCT vbeln
   INTO TABLE rt_vbeln
   FROM vakgu
   WHERE ( vkorg = ms_import-i_vkorg )
   AND   ( trvog = mv_trvog )
   AND   ( datab GE mv_gltab )
   AND   ( datbi LE mv_gltbi )
*    AND   ( VKBUR IN IVKBUR )
*    AND   ( VKGRP IN IVKGRP )
*    AND   ( ZPERS IN IZPERS )
   AND   ( vtweg = ms_import-i_vtweg )
   AND   ( spart = ms_import-i_spart )
*    AND   ( AUART IN IAUART )
   AND   ( kunnr = ms_import-i_kunnr )
*    AND   ( ERNAM IN IERNAM )
   AND   ( vbeln IN mt_sel_vbeln )
     ORDER BY vbeln.


    IF rt_vbeln[] IS INITIAL.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>no_data_found
          mv_kunnr = ms_import-i_kunnr
          mv_msgv1 = 'Aufträge'(001).
    ENDIF.


*VKORG  VKORG CHAR  4 0 Verkaufsorganisation
*TRVOG  TRVOG CHAR  1 0 Gruppe Transaktionsvorgang
*DATAB  DATAB_VI  DATS  8 0 Angebot bzw. Kontrakt gültig ab
*DATBI  DATBI_VI  DATS  8 0 Angebot bzw. Kontrakt gültig bis
*VKBUR  VKBUR CHAR  4 0 Verkaufsbüro
*VKGRP  VKGRP CHAR  3 0 Verkäufergruppe
*ZPERS  DZPERS  NUMC  8 0 Zuständige Person
*VTWEG  VTWEG CHAR  2 0 Vertriebsweg
*SPART  SPART CHAR  2 0 Sparte
*AUART  AUART CHAR  4 0 Verkaufsbelegart
*KUNNR  KUNAG CHAR  10  0 Auftraggeber
*ERNAM  ERNAM CHAR  12  0 Name des Sachbearbeiters, der das Objekt hinzugefügt hat
*VBELN  VBELN CHAR  10  0 Vertriebsbelegnummer

  ENDMETHOD.
