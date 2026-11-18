  METHOD check_caller.

    DATA lv_mvgrn TYPE BALMSGV1.

    SELECT  domvalue_l INTO TABLE @DATA(lt_domvalue) FROM  dd07l
           WHERE  domname     = 'YSDWS_CALLER'.

    LOOP AT lt_domvalue ASSIGNING FIELD-SYMBOL(<value>).
      FIND FIRST OCCURRENCE OF <value> IN iv_sessionid.
      IF sy-subrc EQ 0.
        TRY.
            CALL METHOD ycl_stvarvc=>check_selop
              EXPORTING
                i_pname    = 'ACTIVE.CALLER'
                i_tcode    = 'YSDWS'
                i_selvalue = <value>.
            MOVE <value> TO mv_caller.
            EXIT.                         "#EC CI_NOORDER    "FISJL20200505  OSS327918 HANADB
          CATCH ycx_bc_err .
            MOVE <value> TO lv_mvgrn.
            RAISE EXCEPTION TYPE ycx_sdws_interface
              EXPORTING
                textid   = ycx_sdws_interface=>caller_is_deactivated
                mv_msgv1 = lv_mvgrn.
        ENDTRY.
      ELSE.
        CLEAR <value>.
      ENDIF.
    ENDLOOP.

    IF <value> IS NOT ASSIGNED.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>unknown_caller.
    ELSEIF <value> EQ space.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid = ycx_sdws_interface=>unknown_caller.
    ENDIF.

  ENDMETHOD.
