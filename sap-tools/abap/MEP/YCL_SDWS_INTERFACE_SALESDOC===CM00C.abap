  METHOD GET_PARTNERS_DATA.

    get_kuagv(
               EXPORTING
                 iv_kunnr  = ms_import-i_kunnr
                 iv_vkorg  = ms_import-i_vkorg
                 iv_vtweg  = ms_import-i_vtweg
                 iv_spart  = ms_import-i_spart
                IMPORTING
                  es_kunwa  = ms_kunag
                CHANGING
                  et_vbpavb = mt_vbpavb ).

    LOOP AT mt_vbpavb ASSIGNING FIELD-SYMBOL(<vbpavb>).

      CASE <vbpavb>-parvw.
        WHEN 'WE'.
          TRY.
              CALL METHOD get_kuwe2
                EXPORTING
                  iv_kunnr = <vbpavb>-kunnr
                  iv_parvw = <vbpavb>-parvw
                  iv_vkorg  = ms_import-i_vkorg
                  iv_vtweg  = ms_import-i_vtweg
                  iv_spart  = ms_import-i_spart
                IMPORTING
                  es_kunwa = ms_kunwe.

            CATCH ycx_sdws_interface .
          ENDTRY.

        WHEN OTHERS.

      ENDCASE.


    ENDLOOP.

  ENDMETHOD.
