  method SET_DOCUMENT_RESPONSE.
*-----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*-----------------------------------------------------------------------
*Leutbecher |19.11.2018                                     |C299719
* Bis hierhin war die Aufbereitung, weiter führte dazu das  |
* der mailempfänger geprüft wurde, obwohl die nicht notwendig ist
*-----------------------------------------------------------------------

    check mo_instance is not INITIAL.

    mo_instance->mt_otf[] = it_otf[].

    RAISE LEAVE_PROGRAMM.                       "C299719
  endmethod.
