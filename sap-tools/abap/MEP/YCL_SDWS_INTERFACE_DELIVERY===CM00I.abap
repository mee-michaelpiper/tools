  METHOD modify_deliveries.

* Aufruf über WebService
    CHECK ms_import IS NOT INITIAL.

    LOOP AT ix_deliveries ASSIGNING FIELD-SYMBOL(<dlv>).

      DATA(ind) = sy-tabix.

      IF <dlv>-head-/fis/kommi_text1 NOT IN mt_sel_kommi AND
        <dlv>-head-/fis/kommi_text2 NOT IN mt_sel_kommi.
        DELETE et_delivery_header WHERE vbeln = <dlv>-head-vbeln.
        DELETE et_delivery_header_sts WHERE vbeln = <dlv>-head-vbeln.
        DELETE et_document_flow WHERE vbeln = <dlv>-head-vbeln.
        CONTINUE.
      ENDIF.

    ENDLOOP.


  ENDMETHOD.
