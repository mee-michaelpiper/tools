***INCLUDE MF02CFG0 .

*----------------------------------------------------------------------*
*       FORM  GEN_OBJ_SERVICE
*----------------------------------------------------------------------*
*       Generische Objektdienste ermöglichen
*----------------------------------------------------------------------*
FORM GEN_OBJ_SERVICE.
  DATA: BEGIN OF KEYDATA,
     KUNNR LIKE KNKK-KUNNR,
     KKBER LIKE KNKK-KKBER,
  END OF KEYDATA.
  DATA: OBJKEY LIKE SWEINSTCOU-OBJKEY.
  DATA: OBJTYPE(10).

* ------ Objektschlüssel setzen ----------------------------------------
  KEYDATA-KUNNR = RF02L-KUNDE.
  KEYDATA-KKBER = RF02L-KKBER.
  OBJKEY  = KEYDATA.
  OBJTYPE = 'BUS1010'.

* ------ PUBLISH -------------------------------------------------------
  CALL FUNCTION 'SWU_OBJECT_PUBLISH'
       EXPORTING
            OBJTYPE           = OBJTYPE
            OBJKEY            = OBJKEY
       EXCEPTIONS
            OBJTYPE_NOT_FOUND = 1
            OTHERS            = 2.
ENDFORM.
