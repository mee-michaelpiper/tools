  METHOD map_import.

    DATA ls_kunnr TYPE LINE OF ycl_sdws_interface_all=>tty_sel_kunnr.
*    DATA ls_bestk TYPE LINE OF YCL_SDWS_INTERFACE_ALL=>tty_sel_bestk.
*   " DATA ls_bstkd TYPE LINE OF YCL_SDWS_INTERFACE_ALL=>tty_sel_bstkd.
    DATA ls_vtweg TYPE LINE OF ycl_sdws_interface_all=>tty_sel_vtweg.
    DATA ls_vkorg TYPE LINE OF ycl_sdws_interface_all=>tty_sel_vkorg.
    DATA ls_ernam TYPE LINE OF ycl_sdws_interface_all=>tty_sel_ernam.
    DATA ls_erdat TYPE LINE OF ycl_sdws_interface_all=>tty_sel_erdat.
*    DATA ls_kommi TYPE LINE OF YSDWS_R_KOMMITEXT.
    DATA ls_matnr TYPE LINE OF ycl_sdws_interface_all=>tty_sel_matnr.
*    DATA ls_aufnr TYPE LINE OF YCL_SDWS_INTERFACE_ALL=>tty_sel_aufnr.
    DATA ls_vbeln TYPE LINE OF ycl_sdws_interface_all=>tty_sel_vbeln.
*
    ls_kunnr = 'IEQ'. ls_kunnr-low = is_import-i_kunnr. APPEND ls_kunnr TO mt_sel_kunnr.
    ls_vkorg = 'IEQ'. ls_vkorg-low = is_import-i_vkorg. APPEND ls_vkorg TO mt_sel_vkorg.
    ls_vtweg = 'IEQ'. ls_vtweg-low = is_import-i_vtweg. APPEND ls_vtweg TO mt_sel_vtweg.

    LOOP AT is_import-it_selopt ASSIGNING FIELD-SYMBOL(<sel>).

      CASE <sel>-qualif.
        WHEN 'MATNR'.
          ls_matnr = 'IEQ'. ls_matnr-low = <sel>-fvalue.
          APPEND ls_matnr TO mt_sel_matnr.
*        WHEN 'AUFNR'.
*          ls_aufnr = 'IEQ'. ls_aufnr-low = <sel>-fvalue.
*          APPEND ls_aufnr TO mt_sel_aufnr.
        WHEN 'VBELN'.
          ls_vbeln = 'IEQ'. ls_vbeln-low = <sel>-fvalue.
          APPEND ls_vbeln TO mt_sel_vbeln.
        WHEN 'ERNAM'.
          ls_ernam = 'IEQ'. ls_ernam-low = <sel>-fvalue.
          APPEND ls_ernam TO mt_sel_ernam.
*        WHEN 'KOMMI'.
*          ls_kommi = 'IEQ'. ls_kommi-low = <sel>-fvalue.
*          APPEND ls_kommi TO mt_sel_kommi.
      ENDCASE.

    ENDLOOP.

    READ TABLE is_import-it_selopt ASSIGNING <sel>
       WITH KEY qualif = 'ERFAB'.
    IF sy-subrc EQ 0.
      ls_erdat-low = <sel>-fvalue.

      READ TABLE is_import-it_selopt ASSIGNING <sel>
         WITH KEY qualif = 'ERFBI'.
      IF sy-subrc EQ 0.
        ls_erdat-high = <sel>-fvalue.
        ls_erdat = 'IBT'.
      ELSE.
        ls_erdat = 'IEQ'.
      ENDIF.
      APPEND ls_erdat TO mt_sel_erdat.
    ENDIF.


  ENDMETHOD.
