  METHOD splitt_string2tab.

    DATA text_line1 TYPE tline.
    DATA text_line TYPE tline.
    DATA text_line2 TYPE string.

    REFRESH rt_components.

    SPLIT iv_string AT space INTO TABLE DATA(words).

    LOOP AT words ASSIGNING FIELD-SYMBOL(<word>).

      text_line-TDLINE = text_line-TDLINE && ' ' && <word>.
      text_line2 = text_line2 && ' ' && <word>.

      IF text_line-TDLINE NE text_line2.
        text_line1-tdformat = '*'.
        APPEND text_line1 TO rt_components.
        CLEAR: text_line1, text_line2, text_line.
        text_line2 = text_line1-TDLINE = text_line-TDLINE = <word>.
      ELSE.
        text_line1 = text_line.
      ENDIF.

    ENDLOOP.

    if sy-subrc eq 0.
      text_line1-tdformat = '*'.
      APPEND text_line1 TO rt_components.
    else.
      text_line1-tdformat = '*'.
      text_line1-TDLINE = 'Fehler in der Aufbereitung!'(010).
      APPEND text_line1 TO rt_components.
    endif.

ENDMETHOD.
