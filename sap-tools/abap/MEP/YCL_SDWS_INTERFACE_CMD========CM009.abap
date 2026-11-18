  METHOD creditlimit_change.

    DATA ls_yknka TYPE knka.
    DATA ls_yknkk TYPE knkk.

    LOOP AT mt_knkk ASSIGNING FIELD-SYMBOL(<knkk>).
      ms_knka-kunnr = iv_newkunnr.
      <knkk>-kunnr = <knkk>-knkli = iv_newkunnr.
      CALL FUNCTION 'CREDITLIMIT_CHANGE'  "UPDATE/INSERT des Kreditlimits
        EXPORTING
          i_knka   = ms_knka
          i_knkk   = <knkk>
          upd_knka = 'I'
          upd_knkk = 'I'
*         xneua    = SPACE    " Kennzeichen: Nur Kreditlimit neu aufbauen?
*         xrefl    = SPACE
          yknka    = ls_yknka
          yknkk    = ls_yknkk.
    ENDLOOP.

  ENDMETHOD.
