  METHOD  map_class_data.
*  importing it_class type YSDWS_COMITM_TT
*      RAISING
*        ycx_sdws_interface .

    DATA lt_in TYPE ysdws_comhdr_tt.

    DATA(lt_class) = it_class[].

    LOOP AT lt_class ASSIGNING FIELD-SYMBOL(<cls>).
      DATA(lt_flt_class) = lt_class[]. DELETE lt_flt_class WHERE vakey NE <cls>-vakey.
      MOVE-CORRESPONDING lt_flt_class TO lt_in.
      READ TABLE mt_allocvalueschar WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vchar>).
      IF sy-subrc EQ 0.
        set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vchar> ).
      ENDIF.

      READ TABLE mt_allocvaluescurr WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vcurr>).
      IF sy-subrc EQ 0.
        set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vcurr> ).
      ENDIF.

      READ TABLE mt_allocvaluesnum WITH KEY charact = <cls>-vakey ASSIGNING FIELD-SYMBOL(<vnum>).
      IF sy-subrc EQ 0.
        set_data( EXPORTING it_source = lt_in  CHANGING cs_target = <vnum> ).
      ENDIF.

      DELETE lt_class WHERE vakey =  <cls>-vakey.
    ENDLOOP.
  ENDMETHOD.
