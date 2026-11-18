  METHOD set_class_attributes.



    mo_class->v_objecttable_imp = ms_import-class_objtbl.
    mo_class->v_read_valuations = abap_true.
    mo_class->v_objectkey_imp = ms_import-material.
    mo_class->v_classtype_imp = ms_import-classtype.




  ENDMETHOD.
