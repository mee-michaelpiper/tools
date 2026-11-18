  METHOD fill_bapi_schedule.

    DATA: ls_item      TYPE bapischdl,
          ls_itemx     TYPE bapischdlx,
          lo_error     TYPE REF TO cx_root,
          ls_nitmvakey TYPE ty_itmvakey,
          ls_itmvakey  TYPE ty_itmvakey.

    LOOP AT it_import ASSIGNING FIELD-SYMBOL(<itm>)
      WHERE vakey CS  mc_sche.

      ls_nitmvakey = <itm>-vakey.

      IF ( ls_itmvakey-itm_number NE ls_nitmvakey-itm_number OR
        ls_itmvakey-itm_key NE ls_nitmvakey-itm_key ) AND
        ls_itmvakey-itm_number NE '000000'.
        MOVE ls_itmvakey-itm_number TO: ls_itemx-itm_number, ls_item-itm_number.
        MOVE ls_itmvakey-itm_key TO: ls_itemx-sched_line, ls_item-sched_line.
        APPEND ls_itemx TO mt_order_schedules_inx.
        APPEND ls_item TO mt_order_schedules_in.


        CLEAR: ls_item, ls_itemx.
      ENDIF.
      ls_itmvakey = <itm>-vakey.

      ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_item TO FIELD-SYMBOL(<fielditm>).
      IF sy-subrc EQ 0 AND <fielditm> IS ASSIGNED.

        TRY.

*CATS_NUMERIC_INPUT_CHECK

* CALL FUNCTION 'MOVE_CHAR_TO_NUM'
*   EXPORTING
*     chr                   =
**  IMPORTING
**    NUM                   =
**  EXCEPTIONS
**    CONVT_NO_NUMBER       = 1
**    CONVT_OVERFLOW        = 2
**    OTHERS                = 3
*           .
* IF sy-subrc <> 0.
** Implement suitable error handling here
* ENDIF.


*          CALL FUNCTION 'G_CONVERT_INPUT'
*            EXPORTING
**             CONVERTED_LENGTH         = 0
**             CONVEXIT                 = ' '
**             DATATYPE                 = 'CHAR'
**             INPUT_LENGTH             = 0
*              input_value              = <itm>-fvalue
**             LENGTH                   = 0
**             LOWERCASE                = 'X'
**             FLAG_CONVERT_SPACE       =
*            IMPORTING
*              converted_value          = <fielditm>
*            EXCEPTIONS
*              date_does_not_exist      = 1
*              date_format_unrecognized = 2
*              illegal_length           = 3
*              input_is_not_numeric     = 4
*              conversion_failure       = 5
*              OTHERS                   = 6.
*          .
*          IF sy-subrc <> 0.
** Implement suitable error handling here
*          ELSE.

            MOVE <itm>-fvalue TO <fielditm>.
            ASSIGN COMPONENT <itm>-qualif OF STRUCTURE ls_itemx TO FIELD-SYMBOL(<fielditmx>).
            MOVE abap_true TO <fielditmx>.
*          ENDIF.
          CATCH cx_sy_conversion_no_number INTO lo_error.

        ENDTRY.

      ENDIF.
    ENDLOOP.

    CHECK sy-subrc EQ 0.
    MOVE ls_itmvakey-itm_number TO: ls_itemx-itm_number, ls_item-itm_number.
    MOVE ls_itmvakey-itm_key TO: ls_itemx-sched_line, ls_item-sched_line..
    APPEND ls_itemx TO mt_order_schedules_inx.
    APPEND ls_item TO mt_order_schedules_in.







  ENDMETHOD.
