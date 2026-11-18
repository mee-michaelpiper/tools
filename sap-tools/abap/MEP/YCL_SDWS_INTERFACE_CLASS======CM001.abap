  method GET_CLASSES.


    CALL FUNCTION 'BAPI_OBJCL_GETCLASSES'
      EXPORTING
        objectkey_imp         = v_objectkey_imp
        objecttable_imp       = v_objecttable_imp
        classtype_imp         = v_classtype_imp
        READ_VALUATIONS       = v_read_valuations
        KEYDATE               = v_keydate
        LANGUAGE              = v_language
      TABLES
        alloclist             = t_alloclist
        ALLOCVALUESCHAR       = t_allocvalueschar
        ALLOCVALUESCURR       = t_allocvaluescurr
        ALLOCVALUESNUM        = t_allocvaluesnum
        return                = t_return.


  endmethod.
