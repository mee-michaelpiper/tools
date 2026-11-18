  METHOD check_vtber.

    IF ( iv_vkorg IS NOT INITIAL AND iv_vkorg <> mc_default_vkorg ) OR
       ( iv_vtweg IS NOT INITIAL AND iv_vtweg <> mc_default_vtweg ) OR
       ( iv_spart IS NOT INITIAL AND iv_spart <> mc_default_spart ).


      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>wrong_vtber
          mv_vkorg = mc_default_vkorg
          mv_vtweg = mc_default_vtweg
          mv_spart = mc_default_spart.


    ENDIF.

  ENDMETHOD.
