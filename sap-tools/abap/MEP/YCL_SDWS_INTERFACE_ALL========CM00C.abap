  METHOD get_week_from_com_date.

    DATA lv_scal_date TYPE scal-date.
    DATA lv_scal_week TYPE scal-week.

    lv_scal_date = is_wmdvex-com_date.

    CALL FUNCTION 'DATE_GET_WEEK'
      EXPORTING
        date         = lv_scal_date     " Datum, für das die Woche ermittelt werden soll
      IMPORTING
        week         = lv_scal_week     " Woche, in der das Datum liegt (Format: YYYYWW)
      EXCEPTIONS
        date_invalid = 1
        OTHERS       = 2.
    IF sy-subrc = 0.

      cs_kond-com_week = lv_scal_week.

    ENDIF.

  ENDMETHOD.
