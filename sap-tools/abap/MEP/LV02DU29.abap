FUNCTION BAPI_CUSTOMER_CREATEFROMDATA1.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(PI_PERSONALDATA) LIKE  BAPIKNA101_1 STRUCTURE
*"        BAPIKNA101_1
*"     VALUE(PI_OPT_PERSONALDATA) LIKE  BAPIKNA105 STRUCTURE
*"        BAPIKNA105 OPTIONAL
*"     VALUE(PI_COMPANYDATA) LIKE  BAPIKNA106 STRUCTURE  BAPIKNA106
*"       OPTIONAL
*"     VALUE(PI_OPT_COMPANYDATA) LIKE  BAPIKNA105 STRUCTURE  BAPIKNA105
*"       OPTIONAL
*"     VALUE(PI_CONSUMEREN) LIKE  BAPIKNA107-CONSUMER_FLAG OPTIONAL
*"     VALUE(PI_COPYREFERENCE) LIKE  BAPIKNA102 STRUCTURE  BAPIKNA102
*"     VALUE(PI_CREDIT_CONTROL_FLAG) LIKE  BAPIKNA108-X_FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(CUSTOMERNO) LIKE  BAPIKNA103-CUSTOMER
*"     VALUE(RETURN) LIKE  BAPIRETURN1 STRUCTURE  BAPIRETURN1
*"----------------------------------------------------------------------
*
*-(1) initial routines ------------------------------------------------*
*
*     (i) data declaration: fields, items, tables:
*
  DATA: SUBRC LIKE SY-SUBRC,
        COUNTRY LIKE BAPIKNA101_1-COUNTRY,
        LANGUAGE LIKE BAPIKNA101_1-LANGU_P,
        POSTFLAG LIKE WDL_FLAG-XFLAG,
        CURRENCY LIKE BAPIKNA101_1-CURRENCY,
        REF_KUNNR LIKE TKUNDEVTBER-KUNNR,
        TITLE LIKE  BAPIKNA101_1-TITLE_P,
        PERS_COMP_FLAG TYPE XFELD,
        CONSUMEREN TYPE XFELD,
        CONSUMEREN_INFO TYPE XFELD,
        CREDIT_CONTROL_FLAG like BAPIKNA108-X_FLAG,
        lv_knkk_modify TYPE C,

        I_BAPIKNA101_1 LIKE BAPIKNA101_1,
        I_BAPIKNA102 LIKE BAPIKNA102,
        I_BAPIKNA103 LIKE BAPIKNA103,
        I_BAPIKNA105 LIKE BAPIKNA105,
        I_BAPIKNA105_2 LIKE BAPIKNA105,
        I_BAPIKNA106 LIKE BAPIKNA106,

        I_BAPIADDR1_01 LIKE BAPIADDR1,
        I_BAPIADDR2_01 LIKE BAPIADDR2,

        I_KNA1_01 LIKE KNA1,
        I_KNB1_01 LIKE KNB1,
        I_KNVV_01 LIKE KNVV,

        T_XKNBK_01 LIKE FKNBK OCCURS 0 WITH HEADER LINE,
        T_XKNVI_01 LIKE FKNVI OCCURS 0 WITH HEADER LINE,
        T_XKNVK_01 LIKE FKNVK OCCURS 0 WITH HEADER LINE,
        T_XKNVP_01 LIKE FKNVP OCCURS 0 WITH HEADER LINE,
        T_XKNB5_01 LIKE FKNB5 OCCURS 0 WITH HEADER LINE,
        T_YKNBK_01 LIKE FKNBK OCCURS 0 WITH HEADER LINE,
        T_YKNVI_01 LIKE FKNVI OCCURS 0 WITH HEADER LINE,
        T_YKNVK_01 LIKE FKNVK OCCURS 0 WITH HEADER LINE,
        T_YKNVP_01 LIKE FKNVP OCCURS 0 WITH HEADER LINE,
        T_YKNB5_01 LIKE FKNB5 OCCURS 0 WITH HEADER LINE.
*
*     (ii) reset exporting data and sy-subrc
*
  CLEAR: CUSTOMERNO,
         RETURN,
         SY-SUBRC.

*
*     (iii) fill temporary interface data i_bapikna1_0x, i_bapikna10x
*           (in the following: importing data unchanged, work only with
*            temporary interface data)
*
  MOVE-CORRESPONDING PI_PERSONALDATA TO I_BAPIKNA101_1.
  MOVE-CORRESPONDING PI_OPT_PERSONALDATA TO I_BAPIKNA105.
  MOVE-CORRESPONDING PI_COPYREFERENCE TO I_BAPIKNA102.
  MOVE-CORRESPONDING PI_COMPANYDATA TO I_BAPIKNA106.
  MOVE-CORRESPONDING PI_OPT_COMPANYDATA TO I_BAPIKNA105_2.
  CONSUMEREN = PI_CONSUMEREN.
  CREDIT_CONTROL_FLAG = PI_CREDIT_CONTROL_FLAG.
*
*     (iv) reset data of function kernel
*
  CLEAR: I_KNA1_01,
         I_KNB1_01,
         I_KNVV_01,
         I_BAPIADDR2_01,
         I_BAPIADDR1_01,
         I_BAPIKNA103.
  REFRESH: T_XKNBK_01,
           T_XKNVI_01,
           T_XKNVK_01,
           T_XKNVP_01,
           T_XKNB5_01,
           T_YKNBK_01,
           T_YKNVI_01,
           T_YKNVK_01,
           T_YKNVP_01,
           T_YKNB5_01.
*
*-(2) work routines ---------------------------------------------------*
*
*     (i) call "check function"
*
  CALL FUNCTION 'SD_CUSTOMER_CHECK_1'
       EXPORTING
            PI_BAPIKNA101_1    = I_BAPIKNA101_1
            PI_BAPIKNA105      = I_BAPIKNA105
            PI_BAPIKNA102      = I_BAPIKNA102
            PI_CUSTOMER        = SPACE
            PI_BAPIKNA106      = I_BAPIKNA106
            PI_BAPIKNA105_2    = I_BAPIKNA105_2
            PI_CONSUMEREN      = CONSUMEREN
       IMPORTING
            PE_COUNTRY         = COUNTRY
            PE_LANGUAGE        = LANGUAGE
            PE_CURRENCY        = CURRENCY
            PE_REF_KUNNR       = REF_KUNNR
*           PE_CONSUMEREN      = CONSUMEREN
            PE_PERS_COMP_FLAG  = PERS_COMP_FLAG
            PE_BAPIKNA105      = I_BAPIKNA105
            PE_TITLE           = TITLE
            PE_RETURN1         = RETURN
       EXCEPTIONS
            ERROR_MESSAGE      = 2
            OTHERS             = 1.
*
*         error-handling
*
  IF NOT RETURN IS INITIAL
  OR SY-SUBRC = 2.
*
*         set return value "return" and leave the function          --->
*
    PERFORM BAPIRETURN_FILL_1 USING SY-MSGID
                                    SY-MSGNO
                                    SY-MSGV1
                                    SY-MSGV2
                                    SY-MSGV3
                                    SY-MSGV4
                           CHANGING RETURN.
  ENDIF.

  CHECK RETURN IS INITIAL.
*
*     (ii) fill exporting data of "kernel function"
*
  PERFORM FILLEDFK_1 TABLES  T_XKNVK_01
                             T_XKNVI_01
                             T_XKNB5_01
                  USING      CONSUMEREN
                             PERS_COMP_FLAG
                             REF_KUNNR
                             COUNTRY
                             LANGUAGE
                             CURRENCY
                             TITLE
                             I_BAPIKNA105
                             I_BAPIKNA102
                             I_BAPIKNA103
                    CHANGING I_BAPIKNA101_1
                             I_BAPIKNA106
                             I_BAPIADDR1_01
                             I_BAPIADDR2_01
                             I_KNA1_01
                             I_KNB1_01
                             I_KNVV_01.
*
*     (iii) call "kernel function" post synchron (postflag = X)
*
  CONSUMEREN_INFO = CONSUMEREN.
  IF NOT I_BAPIADDR1_01 IS INITIAL.
    CLEAR CONSUMEREN_INFO.
  ENDIF.
  POSTFLAG = 'X'.
  CALL FUNCTION 'SD_CUSTOMER_MAINTAIN_ALL'
       EXPORTING
            I_KNA1                  = I_KNA1_01
            I_KNB1                  = I_KNB1_01
            I_KNVV                  = I_KNVV_01
            I_BAPIADDR1             = I_BAPIADDR1_01
            I_BAPIADDR2             = I_BAPIADDR2_01
            I_KNB1_REFERENCE        = CONSUMEREN_INFO
            I_CUSTOMER_IS_CONSUMER  = CONSUMEREN_INFO
            PI_POSTFLAG             = POSTFLAG
       IMPORTING
            E_KUNNR                 = I_BAPIKNA103-CUSTOMER
       TABLES
            T_XKNBK                 = T_XKNBK_01
            T_XKNB5                 = T_XKNB5_01
            T_XKNVI                 = T_XKNVI_01
            T_XKNVK                 = T_XKNVK_01
            T_XKNVP                 = T_XKNVP_01
            T_YKNBK                 = T_YKNBK_01
            T_YKNB5                 = T_YKNB5_01
            T_YKNVI                 = T_YKNVI_01
            T_YKNVK                 = T_YKNVK_01
            T_YKNVP                 = T_YKNVP_01
       EXCEPTIONS
            CLIENT_ERROR            = 1
            KNA1_INCOMPLETE         = 2
            KNB1_INCOMPLETE         = 3
            KNB5_INCOMPLETE         = 4
            KNVV_INCOMPLETE         = 5
            KUNNR_NOT_UNIQUE        = 6
            SALES_AREA_NOT_UNIQUE   = 7
            SALES_AREA_NOT_VALID    = 8
            INSERT_UPDATE_CONFLICT  = 9
            NUMBER_ASSIGNMENT_ERROR = 10
            NUMBER_NOT_IN_RANGE     = 11
            NUMBER_RANGE_NOT_EXTERN = 12
            NUMBER_RANGE_NOT_INTERN = 13
            ACCOUNT_GROUP_NOT_VALID = 14
            PARNR_INVALID           = 15
            BANK_ADDRESS_INVALID    = 16
            TAX_DATA_NOT_VALID      = 17
            NO_AUTHORITY            = 18
            COMPANY_CODE_NOT_UNIQUE = 19
            DUNNING_DATA_NOT_VALID  = 20
            KNB1_REFERENCE_INVALID  = 21
            CAM_ERROR               = 22
            OTHERS                  = 25.
*
*     (iv) insert the credit control data
*
  IF CREDIT_CONTROL_FLAG = 'X'
  AND SY-SUBRC = 0.
    IF NOT CONSUMEREN_INFO IS INITIAL
     AND NOT I_BAPIKNA102-REF_CUSTMR IS INITIAL
     AND NOT I_BAPIKNA103-CUSTOMER IS INITIAL
     AND NOT REF_KUNNR IS INITIAL.
      lv_knkk_modify = 'X'.
    ENDIF.
    CALL FUNCTION 'SD_CUSTOMER_MAINTAIN_KNKA_K'
        EXPORTING
            PI_REF_CUSTOMER   = I_BAPIKNA102-REF_CUSTMR
            PI_CUSTOMER       = I_BAPIKNA103-CUSTOMER
            PI_KNKK_MODIFY    = lv_knkk_modify
        EXCEPTIONS
            KNKA_INSERT_ERROR = 23
            KNKK_INSERT_ERROR = 24.
  ENDIF.
*
*     (v) return-value "kernel function"
*
*           (1) reset data of function kernel
*
  CLEAR: I_KNA1_01,
         I_KNB1_01,
         I_KNVV_01,
         I_BAPIADDR1_01,
         I_BAPIADDR2_01.
*
*           (2) error-handling
*               return value sy-subrc, only in case sy-subrc = 0
*               the exporting data customer_number (customerno)
*               will be changed
*
  SUBRC = SY-SUBRC.
  CLEAR SY-SUBRC.
*
*-(3) set return values and leave the function ------------------------*
*     customerno (key-field of BO KNA1), pe_customer, return
*
  PERFORM RETURNSUBRC_1
             USING    SUBRC
                      I_BAPIKNA103-CUSTOMER
             CHANGING CUSTOMERNO
                      RETURN.

ENDFUNCTION.
