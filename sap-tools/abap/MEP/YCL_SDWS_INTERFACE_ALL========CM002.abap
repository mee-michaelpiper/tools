  METHOD check_iso_langu.

    IF iv_langu IS NOT INITIAL.

      " !!! Setzen der Sprache für die zurückzugebenden Nachrichten global:

*      SELECT SINGLE spras INTO mv_message_spras
*      FROM t002
*      WHERE laiso = iv_langu.
      SELECT spras INTO mv_message_spras UP TO 1 ROWS   "FISJL20200429 OSs336178 HANADB
       FROM t002
        WHERE laiso = iv_langu ORDER BY PRIMARY KEY.
      ENDSELECT.

      IF sy-subrc <> 0.
        mv_message_spras = mc_dflt_spras.
        " Der Sprachenschlüssel &1 ist unbekannt!
        RAISE EXCEPTION TYPE ycx_sdws_interface
          EXPORTING
            textid   = ycx_sdws_interface=>langu_unknown
            mv_langu = iv_langu.

      ENDIF.

      SET LOCALE LANGUAGE mv_message_spras.
    ENDIF.

  ENDMETHOD.
