FORM CD_CALL_KLIM           .
   IF   ( UPD_KNKA                           NE SPACE )
     OR ( UPD_KNKK                           NE SPACE )
   .
     CALL FUNCTION 'KLIM_WRITE_DOCUMENT           ' IN UPDATE TASK
        EXPORTING OBJECTID              = OBJECTID
                  TCODE                 = TCODE
                  UTIME                 = UTIME
                  UDATE                 = UDATE
                  USERNAME              = USERNAME
                  PLANNED_CHANGE_NUMBER = PLANNED_CHANGE_NUMBER
                  OBJECT_CHANGE_INDICATOR = CDOC_UPD_OBJECT
                  PLANNED_OR_REAL_CHANGES = CDOC_PLANNED_OR_REAL
                  NO_CHANGE_POINTERS = CDOC_NO_CHANGE_POINTERS
                  O_YKNKA
                      = YKNKA
                  N_KNKA
                      = KNKA
                  UPD_KNKA
                      = UPD_KNKA
                  O_YKNKK
                      = YKNKK
                  N_KNKK
                      = KNKK
                  O_XF02C
                      = *XF02C
                  N_XF02C
                      = XF02C
                  UPD_KNKK
                      = UPD_KNKK
     .
   ENDIF.
   CLEAR PLANNED_CHANGE_NUMBER.
ENDFORM.
