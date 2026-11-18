  method CHECK_KOMMITXT_IN_SEL.

    rv_result = abap_true.

    ASSIGN COMPONENT '/FIS/KOMMI_TEXT1' of STRUCTURE is_wa to FIELD-SYMBOL(<f1>).
    ASSIGN COMPONENT '/FIS/KOMMI_TEXT1' of STRUCTURE is_wa to FIELD-SYMBOL(<f2>).

    check <f1> is assigned and <f2> is ASSIGNED.

    if <f1> not in mt_sel_kommi and <f2> not in mt_sel_kommi.
      clear rv_result.
    endif.
  endmethod.
