  METHOD GET_WEEK_FROM_COM_DATE.

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

      rv_week = lv_scal_week.

    ENDIF.

  ENDMETHOD.
