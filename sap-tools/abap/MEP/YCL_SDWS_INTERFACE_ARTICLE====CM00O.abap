  method SEARCH_SOURCE_OF_SUPPLY.

  DATA  ls_comim TYPE bqpim.
data  ls_comex TYPE bqpex.


  MOVE iv_matnr    TO ls_comim-matnr.
  MOVE iv_werks TO ls_comim-werks.
  IF iv_datum IS SUPPLIED.
    move iv_datum     to ls_comim-nedat.
  ELSE.
    MOVE sy-datum     TO ls_comim-nedat.
  ENDIF.
  MOVE 'X'          TO ls_comim-noaus.
  MOVE 'X'          TO ls_comim-nomei.

  CALL FUNCTION 'ME_SEARCH_SOURCE_OF_SUPPLY'
    EXPORTING
      comim = ls_comim
    IMPORTING
      comex = ls_comex.

  re_flief = ls_comex-flief.

  endmethod.
