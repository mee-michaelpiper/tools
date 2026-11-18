  METHOD fetch_data_creditmanagement.

    SELECT SINGLE * FROM knka
     WHERE kunnr = @mv_ref_customer
      INTO @ms_knka.
    IF sy-subrc EQ 0.
      SELECT * FROM knkk
       WHERE  kunnr = @mv_ref_customer
        INTO TABLE @mt_knkk.
    ENDIF.

  ENDMETHOD.
