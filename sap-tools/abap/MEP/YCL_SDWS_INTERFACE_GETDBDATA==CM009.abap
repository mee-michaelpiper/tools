  METHOD set_dynamic_where.

* data declaration for the FM

  DATA:
        t_sel      TYPE se16n_or_t,
        la_sel     LIKE LINE OF t_sel,
        t_sel_tab  TYPE se16n_or_seltab_t,
        la_sel_tab LIKE LINE OF t_sel_tab.


*.selection criteria
    DATA: ls_selfields TYPE se16n_seltab.


    LOOP AT is_import-it_selopt ASSIGNING FIELD-SYMBOL(<field>).

      ls_selfields-field  = <field>-qualif.
      ls_selfields-sign   = 'I'.
      ls_selfields-option = 'EQ'.
      ls_selfields-low    = <field>-fvalue.
      APPEND ls_selfields TO rt_where.

    ENDLOOP.

*

** Fill the main selection table
*  la_sel-pos = 1.
*  la_sel-seltab = t_sel_tab.
*  APPEND la_sel TO t_sel.


*  CALL FUNCTION 'RH_DYNAMIC_WHERE_BUILD'
*     EXPORTING
*      dbtable         = space " can be empty
*     TABLES
*      condtab         = gt_condtab
*      where_clause    = gt_where_clauses
*    EXCEPTIONS
*       empty_condtab   = 01
*       no_db_field     = 02
*       unknown_db      = 03
*       wrong_condition = 04.

  ENDMETHOD.
