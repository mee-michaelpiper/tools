  METHOD get_partners_data.



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
                  iv_kunnr = ms_import-i_kunnr
                  iv_parvw = <vbpavb>-parvw
                  iv_vkorg = ms_import-i_vkorg
                  iv_vtweg = ms_import-i_vtweg
                  iv_spart = ms_import-i_spart
                IMPORTING
                  es_kunwa = ms_kunwe.

              <vbpavb>-cntpa = 1.

              SELECT adrnr, hzuor, knref, p~kunnr, kunn2, land1, lzone,
                  name1, parnr, parvw, spras, telx1, telfx, teltx
                 INTO table @data(lt_we) FROM  knvp AS p
                INNER JOIN kna1 AS k
              ON p~kunn2 = k~kunnr
       WHERE  p~kunnr  = @ms_import-i_kunnr
       AND    p~vkorg  = @ms_import-i_vkorg
       AND    p~vtweg  = @ms_import-i_vtweg
       AND    p~parvw  = @<vbpavb>-parvw
             AND p~kunn2 NE @<vbpavb>-kunnr.


            CATCH ycx_sdws_interface .
          ENDTRY.

        WHEN OTHERS.

      ENDCASE.


    ENDLOOP.


    LOOP AT lt_we ASSIGNING FIELD-SYMBOL(<we>).
      APPEND INITIAL LINE TO mt_vbpavb ASSIGNING <vbpavb>.

      MOVE-CORRESPONDING <we> TO <vbpavb>.
      <vbpavb>-kunnr = <we>-kunn2.

    ENDLOOP.

  ENDMETHOD.
