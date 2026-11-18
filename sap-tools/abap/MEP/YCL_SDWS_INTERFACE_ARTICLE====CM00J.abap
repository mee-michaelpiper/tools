  method GET_LANGTEXT.

 DATA: BEGIN OF HILF,
          MATNR LIKE MARA-MATNR,
          VKORG LIKE MVKE-VKORG,
          VTWEG LIKE MVKE-VTWEG,
       END OF HILF,

       BEGIN OF HILF2,
          MATNR LIKE MARA-MATNR,
          SPACE,
          WERKS LIKE MARC-WERKS,
       END OF HILF2,

*       HILF1 LIKE BAPI_MLTX_GA-TEXT_NAME,
       hilf1 type TDOBNAME,

*       OBJ LIKE BAPI_MLTX_GA-APPLOBJECT,
        obj type TDOBJECT,
        sel type THEAD,
        t_sel type BBPT_THEAD,
        lin type tline,
        t_lin type TLINE_T,
        MLTX type bapi_mltx_ga.
*       BEGIN OF SEL OCCURS 10.
*          INCLUDE STRUCTURE THEAD.
*  DATA: END OF SEL,
*       lin type TLINE_T with HEADER LINE.
*        BEGIN OF LIN OCCURS 10.
*          INCLUDE STRUCTURE TLINE.
*  DATA: END OF LIN.

  HILF-MATNR = P_MATERIAL.
* Vertriebstexte
  IF P_ID = '0001'.                      " Vertriebstext
    HILF-VKORG = P_SALESORG.
    HILF-VTWEG = P_DISTR_CHAN.
    HILF1 = HILF.
* Materialnotiz
  ELSEIF P_ID = 'LTXT'.
    HILF2-MATNR = P_MATERIAL.
    HILF2-WERKS = P_PLANT.
    HILF1 = HILF2.
* Bestelltext/Prueftext/Grunddatentext/Interner Vermerk
  ELSE.
    HILF-VKORG = '*'.
    HILF1 = HILF.
  ENDIF.

* thk 40: Spezielle Objects verwenden, ist schneller
  IF P_ID = '0001'.
    OBJ = 'MVKE'.
  ELSEIF P_ID = 'BEST' OR P_ID = 'GRUN' OR P_ID = 'PRUE' OR P_ID =
'IVER'.
    OBJ = 'MATERIAL'.
  ELSEIF P_ID = 'LTXT'.
    OBJ = 'MDTXT'.
  ENDIF.

* alle Texte zum Objekt/Material/ID selektieren

  CALL FUNCTION 'SELECT_TEXT'
    EXPORTING
      ID                      = P_ID
      LANGUAGE                = '*'
      NAME                    = HILF1
      OBJECT                  = OBJ
    TABLES
      SELECTIONS              = t_SEL
    EXCEPTIONS
      WRONG_ACCESS_TO_ARCHIVE = 01.

* Selektieren der Formate und Textzeilen
  IF SY-SUBRC = 0.

    LOOP AT t_SEL into sel.

      CALL FUNCTION 'READ_TEXT'
        EXPORTING
          ID       = SEL-TDID
          LANGUAGE = SEL-TDSPRAS
          NAME     = SEL-TDNAME
          OBJECT   = SEL-TDOBJECT
        TABLES
          LINES    = t_LIN
        EXCEPTIONS
          OTHERS   = 07.

      IF SY-SUBRC = 0.

        LOOP AT t_LIN into lin.

          MLTX-APPLOBJECT = SEL-TDOBJECT.
          MLTX-TEXT_NAME  = SEL-TDNAME.
          MLTX-TEXT_ID    = SEL-TDID.
          MLTX-LANGU      = SEL-TDSPRAS.


          CALL FUNCTION 'CONVERSION_EXIT_ISOLA_OUTPUT'
            EXPORTING
              INPUT  = SEL-TDSPRAS
            IMPORTING
              OUTPUT = MLTX-LANGU_ISO
            EXCEPTIONS
              OTHERS = 1.


          MLTX-FORMAT_COL      = LIN-TDFORMAT.
          MLTX-TEXT_LINE      =  LIN-TDLINE.

          APPEND mltx to P_MLTX.

        ENDLOOP.

      ENDIF.

    ENDLOOP.
  ENDIF.




  endmethod.
