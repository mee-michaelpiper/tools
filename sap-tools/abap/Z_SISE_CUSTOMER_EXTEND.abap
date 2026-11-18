FUNCTION z_sise_customer_extend.
*"----------------------------------------------------------------------
*" Bestehenden Kunden um Buchungskreis und Vertriebsbereich erweitern
*" (z. B. Kunde nur in BUKRS/VKORG 100 -> zusätzlich 298 fürs ES).
*" Per RFC aus dem SiSe-Portal (SAP-API), Entwurf 03.11.2026.
*"
*" Ablauf wie die Neukundenanlage (YCL_SDWS_INTERFACE_CMD), nur mit
*" Kopf-Task 'U' statt 'I' und der bestehenden Kundennummer:
*"   1. Referenzkunde des VK-Büros lesen (CMD_EI_API_EXTRACT=>GET_DATA)
*"   2. Dessen Buchungskreis- und Vertriebsdaten mit Task 'I' an den
*"      bestehenden Kunden hängen, Partnerrollen auf den Kunden selbst
*"   3. CMD_EI_API=>MAINTAIN_BAPI, COMMIT WORK AND WAIT
*"   4. Optional: Kreditdaten (KNKK) des Referenzkunden übernehmen
*" Zentrale Daten (Name, Anschrift, Steuer, Klassifizierung, Bank)
*" bleiben unverändert. Was es schon gibt, wird nicht angefasst.
*"
*" Funktionsgruppe: z. B. ZSISE_CUSTOMER   Abwicklungsart: REMOTEFÄHIG
*" Alle Parameter "Wertübergabe" (Pflicht bei RFC).
*"
*"*"Lokale Schnittstelle:
*"  IMPORTING
*"     VALUE(IV_KUNNR) TYPE  KUNNR
*"     VALUE(IV_REF_KUNNR) TYPE  KUNNR
*"     VALUE(IV_BUKRS) TYPE  BUKRS DEFAULT '298'
*"     VALUE(IV_VKORG) TYPE  VKORG DEFAULT '298'
*"     VALUE(IV_VTWEG) TYPE  VTWEG DEFAULT '00'
*"     VALUE(IV_SPART) TYPE  SPART DEFAULT '00'
*"     VALUE(IV_WITH_CREDIT) TYPE  XFELD DEFAULT 'X'
*"     VALUE(IV_TESTRUN) TYPE  XFELD DEFAULT SPACE
*"  EXPORTING
*"     VALUE(EV_COMPANY_CREATED) TYPE  XFELD
*"     VALUE(EV_SALES_CREATED) TYPE  XFELD
*"     VALUE(EV_CREDIT_CREATED) TYPE  XFELD
*"  TABLES
*"      IT_FIELDS STRUCTURE  BAPIPAREX OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
* IV_REF_KUNNR: Referenz-/Musterkunde des gewählten VK-Büros (dieselbe
*               Zuordnung wie bei der Neuanlage, kommt aus dem Portal).
* IT_FIELDS:    Abweichungen vom Referenzkunden, je Zeile
*                 STRUCTURE  = 'KNB1' oder 'KNVV'
*                 VALUEPART1 = Feldname (wie in CMDS_EI_COMPANY_DATA bzw.
*                              CMDS_EI_SALES_DATA, z. B. ZTERM, VKBUR, KVGR2)
*                 VALUEPART2 = Wert (interne Darstellung)
*               Unbekannte Feldnamen -> Fehler, nichts wird angelegt.
* IV_TESTRUN:   'X' = MAINTAIN_BAPI im Testmodus, ROLLBACK, nichts angelegt.
*
* Zur Prüfung (Hinweise für den Reviewer):
*  - Partnerrollen: übernommen werden nur Rollen, die beim Referenzkunden
*    auf ihn selbst zeigen (AG/RE/RG/WE ...), umgesetzt auf IV_KUNNR.
*    Rollen auf andere Partner (z. B. Vertreter) werden NICHT kopiert.
*  - Kreditdaten: KNKK des Referenzkunden im Kreditkontrollbereich der
*    neuen Vertriebsdaten (KNVV-KKBER, sonst IV_BUKRS) per
*    CREDITLIMIT_CHANGE – wie CREDITLIMIT_CHANGE in der Schnittstelle.
*    Kein Änderungsbeleg KLIM (die Schnittstelle schreibt auch keinen).
*  - Änderungsbelege DEBI schreibt CMD_EI_API selbst (Änderer = RFC-User).

  DATA: lv_kunnr      TYPE kunnr,
        lv_ref        TYPE kunnr,
        lv_has_knb1   TYPE abap_bool,
        lv_has_knvv   TYPE abap_bool,
        ls_in         TYPE cmds_ei_main,
        ls_ref        TYPE cmds_ei_main,
        ls_error      TYPE cvis_message,
        ls_new        TYPE cmds_ei_extern,
        ls_main       TYPE cmds_ei_main,
        ls_correct    TYPE cmds_ei_main,
        ls_msg_ok     TYPE cvis_message,
        ls_defective  TYPE cmds_ei_main,
        ls_msg_err    TYPE cvis_message,
        lv_kkber      TYPE kkber,
        ls_knka       TYPE knka,
        ls_knka_old   TYPE knka,
        ls_knkk       TYPE knkk,
        ls_knkk_old   TYPE knkk,
        lv_upd_knka   TYPE cdpos-chngind.

  CLEAR: ev_company_created, ev_sales_created, ev_credit_created.
  REFRESH et_return.

  PERFORM alpha USING iv_kunnr CHANGING lv_kunnr.
  PERFORM alpha USING iv_ref_kunnr CHANGING lv_ref.

*------- Prüfen -------------------------------------------------------------
  SELECT SINGLE kunnr FROM kna1 INTO lv_kunnr WHERE kunnr = lv_kunnr.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Kunde' lv_kunnr 'gibt es nicht.' ''.
    RETURN.
  ENDIF.

  SELECT SINGLE kunnr FROM knb1 INTO @DATA(lv_knb1)
    WHERE kunnr = @lv_kunnr AND bukrs = @iv_bukrs.
  lv_has_knb1 = xsdbool( sy-subrc = 0 ).
  SELECT SINGLE kunnr FROM knvv INTO @DATA(lv_knvv)
    WHERE kunnr = @lv_kunnr AND vkorg = @iv_vkorg AND vtweg = @iv_vtweg AND spart = @iv_spart.
  lv_has_knvv = xsdbool( sy-subrc = 0 ).
  IF lv_has_knb1 = abap_true AND lv_has_knvv = abap_true.
    PERFORM add_return TABLES et_return USING 'S' 'Kunde' lv_kunnr 'ist bereits in' iv_vkorg.
    RETURN.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'F_KNA1_BUK' ID 'BUKRS' FIELD iv_bukrs ID 'ACTVT' FIELD '01'.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Keine Berechtigung, Kunden in Buchungskreis' iv_bukrs 'anzulegen.' ''.
    RETURN.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'V_KNA1_VKO'
    ID 'VKORG' FIELD iv_vkorg ID 'VTWEG' FIELD iv_vtweg ID 'SPART' FIELD iv_spart ID 'ACTVT' FIELD '01'.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Keine Berechtigung, Kunden in Verkaufsorganisation' iv_vkorg 'anzulegen.' ''.
    RETURN.
  ENDIF.

*------- Referenzkunde lesen (wie FETCH_DATA_CMD der Schnittstelle) --------
  APPEND VALUE #( header-object_instance-kunnr = lv_ref header-object_task = 'M' ) TO ls_in-customers.
  cmd_ei_api_extract=>get_data( EXPORTING is_master_data = ls_in
                                IMPORTING es_master_data = ls_ref
                                          es_error       = ls_error ).
  IF ls_error-is_error = abap_true OR ls_ref-customers IS INITIAL.
    APPEND LINES OF ls_error-messages TO et_return.
    PERFORM add_return TABLES et_return USING 'E' 'Referenzkunde' lv_ref 'nicht lesbar.' ''.
    RETURN.
  ENDIF.
  DATA(ls_ref_cust) = ls_ref-customers[ 1 ].

*------- Neue Daten: Kopf 'U', zentrale Daten leer (= unverändert) --------
  ls_new-header-object_instance-kunnr = lv_kunnr.
  ls_new-header-object_task           = 'U'.

  " Buchungskreis
  IF lv_has_knb1 = abap_false.
    READ TABLE ls_ref_cust-company_data-company INTO DATA(ls_company)
      WITH KEY data_key-bukrs = iv_bukrs.
    IF sy-subrc <> 0.
      PERFORM add_return TABLES et_return USING 'E' 'Referenzkunde' lv_ref 'hat keinen Buchungskreis' iv_bukrs.
      RETURN.
    ENDIF.
    ls_company-task = 'I'.
    CLEAR: ls_company-datax, ls_company-texts.
    " Kundenspezifisches des Referenzkunden nicht übernehmen
    PERFORM clear_fields USING 'SPERR LOEVM NODEL CVP_XBLCK_B ALTKN EIKTO ZSABE KVERM TLFNS TLFXS INTAD PERNR KNRZE KNRZB YYFI_LEITWEGID'
                         CHANGING ls_company-data.
    LOOP AT ls_company-dunning-dunning ASSIGNING FIELD-SYMBOL(<dunning>).
      <dunning>-task = 'I'.
      CLEAR <dunning>-datax.
      " Mahnstand des Referenzkunden nicht übernehmen
      PERFORM clear_fields USING 'MADAT MAHNS GMVDT' CHANGING <dunning>-data.
    ENDLOOP.
    LOOP AT ls_company-wtax_type-wtax_type ASSIGNING FIELD-SYMBOL(<wtax>).
      <wtax>-task = 'I'.
      CLEAR <wtax>-datax.
    ENDLOOP.
    CLEAR: ls_company-dunning-current_state, ls_company-wtax_type-current_state.
    PERFORM apply_fields TABLES it_fields et_return USING 'KNB1' CHANGING ls_company-data.
    APPEND ls_company TO ls_new-company_data-company.
    ev_company_created = abap_true.
  ENDIF.

  " Vertriebsbereich
  IF lv_has_knvv = abap_false.
    READ TABLE ls_ref_cust-sales_data-sales INTO DATA(ls_sales)
      WITH KEY data_key-vkorg = iv_vkorg data_key-vtweg = iv_vtweg data_key-spart = iv_spart.
    IF sy-subrc <> 0.
      PERFORM add_return TABLES et_return USING 'E' 'Referenzkunde' lv_ref 'hat keinen Vertriebsbereich' iv_vkorg.
      RETURN.
    ENDIF.
    ls_sales-task = 'I'.
    CLEAR: ls_sales-datax, ls_sales-texts.
    PERFORM clear_fields USING 'LOEVM AUFSD LIFSD FAKSD CASSD CVP_XBLCK_V EIKTO'
                         CHANGING ls_sales-data.
    " Partnerrollen: nur die auf den Referenzkunden selbst, umgesetzt auf den Kunden
    DATA(lt_functions) = ls_sales-functions-functions.
    CLEAR: ls_sales-functions-functions, ls_sales-functions-current_state.
    LOOP AT lt_functions INTO DATA(ls_function) WHERE data-partner = lv_ref.
      ls_function-task         = 'I'.
      ls_function-data-partner = lv_kunnr.
      CLEAR ls_function-datax.
      APPEND ls_function TO ls_sales-functions-functions.
    ENDLOOP.
    IF ls_sales-functions-functions IS INITIAL.
      " Referenzkunde ohne eigene Rollen: Pflichtrollen auf den Kunden selbst
      LOOP AT VALUE string_table( ( `AG` ) ( `RE` ) ( `RG` ) ( `WE` ) ) INTO DATA(lv_parvw).
        APPEND VALUE #( task = 'I' data_key-parvw = lv_parvw data-partner = lv_kunnr ) TO ls_sales-functions-functions.
      ENDLOOP.
    ENDIF.
    PERFORM apply_fields TABLES it_fields et_return USING 'KNVV' CHANGING ls_sales-data.
    APPEND ls_sales TO ls_new-sales_data-sales.
    lv_kkber = ls_sales-data-kkber.
    ev_sales_created = abap_true.
  ENDIF.

  IF line_exists( et_return[ type = 'E' ] ).
    CLEAR: ev_company_created, ev_sales_created.
    RETURN.
  ENDIF.

*------- Anlegen -------------------------------------------------------------
  APPEND ls_new TO ls_main-customers.
  cmd_ei_api=>initialize( ).
  cmd_ei_api=>maintain_bapi( EXPORTING iv_test_run              = iv_testrun
                                       iv_collect_messages      = abap_true
                                       is_master_data           = ls_main
                             IMPORTING es_master_data_correct   = ls_correct
                                       es_message_correct       = ls_msg_ok
                                       es_master_data_defective = ls_defective
                                       es_message_defective     = ls_msg_err ).
  APPEND LINES OF ls_msg_ok-messages TO et_return.
  APPEND LINES OF ls_msg_err-messages TO et_return.
  IF ls_msg_err-is_error = abap_true OR ls_msg_ok-is_error = abap_true OR ls_defective-customers IS NOT INITIAL.
    ROLLBACK WORK.
    CLEAR: ev_company_created, ev_sales_created.
    PERFORM add_return TABLES et_return USING 'E' 'Kunde' lv_kunnr 'nicht erweitert.' ''.
    RETURN.
  ENDIF.

  IF iv_testrun = abap_true.
    ROLLBACK WORK.
    PERFORM add_return TABLES et_return USING 'S' 'Testlauf: Kunde' lv_kunnr 'könnte erweitert werden um' iv_vkorg.
    RETURN.
  ENDIF.

*------- Kreditdaten (optional, wie CREDITLIMIT_CHANGE der Schnittstelle) --
  IF iv_with_credit = abap_true.
    IF lv_kkber IS INITIAL.
      lv_kkber = iv_bukrs.
    ENDIF.
    SELECT SINGLE * FROM knkk INTO ls_knkk_old WHERE kunnr = lv_kunnr AND kkber = lv_kkber.
    IF sy-subrc <> 0.
      SELECT SINGLE * FROM knkk INTO ls_knkk WHERE kunnr = lv_ref AND kkber = lv_kkber.
      IF sy-subrc = 0.
        SELECT SINGLE * FROM knka INTO ls_knka_old WHERE kunnr = lv_kunnr.
        IF sy-subrc = 0.
          ls_knka = ls_knka_old.
          lv_upd_knka = space.
        ELSE.
          SELECT SINGLE * FROM knka INTO ls_knka WHERE kunnr = lv_ref.
          ls_knka-kunnr = lv_kunnr.
          lv_upd_knka = 'I'.
        ENDIF.
        ls_knkk-kunnr = ls_knkk-knkli = lv_kunnr.
        ls_knkk-erdat = sy-datum.
        ls_knkk-ernam = sy-uname.
        " Nur Stammdaten (Limit, Risikoklasse, Gruppe) übernehmen – keine Obligos, Zahlungshistorie, Prüfdaten
        PERFORM clear_fields USING 'AEDAT AENAM AETXT ABSBT CASHA CASHC CASHD CRBLB DTREV NXTRV KRAUS PAYDB DBPAY DBRAT DBRTG DBMON DBEKR DBWAE REVDB SBDAT SAUFT SKFOR SSOBL UEDAT XCHNG'
                             CHANGING ls_knkk.
        CLEAR: ls_knkk_old, ls_knka_old.
        CALL FUNCTION 'CREDITLIMIT_CHANGE' IN UPDATE TASK
          EXPORTING
            i_knka   = ls_knka
            i_knkk   = ls_knkk
            upd_knka = lv_upd_knka
            upd_knkk = 'I'
            yknka    = ls_knka_old
            yknkk    = ls_knkk_old.
        ev_credit_created = abap_true.
      ELSE.
        PERFORM add_return TABLES et_return USING 'W' 'Referenzkunde hat keine Kreditdaten im Bereich' lv_kkber '– Kreditdaten nicht angelegt.' ''.
      ENDIF.
    ENDIF.
  ENDIF.

  COMMIT WORK AND WAIT.
  IF sy-subrc <> 0.
    PERFORM add_return TABLES et_return USING 'E' 'Verbuchung fehlgeschlagen (SM13 prüfen).' '' '' ''.
    RETURN.
  ENDIF.

  PERFORM add_return TABLES et_return USING 'S' 'Kunde' lv_kunnr 'erweitert um' iv_vkorg.

ENDFUNCTION.

*----------------------------------------------------------------------*
* In ein Include der Funktionsgruppe (z. B. LZSISE_CUSTOMERF01).
* ADD_RETURN wie in Z_SISE_CREDITLIMIT_SET (gleiche Funktionsgruppe
* möglich – dann nur einmal anlegen).
*----------------------------------------------------------------------*
FORM add_return TABLES ct_return STRUCTURE bapiret2
                USING  iv_type TYPE bapi_mtype
                       iv_v1 iv_v2 iv_v3 iv_v4.
  DATA ls_return TYPE bapiret2.
  ls_return-type       = iv_type.
  ls_return-id         = '00'.
  ls_return-number     = '001'.          " &1&2&3&4&5&6&7&8
  ls_return-message_v1 = iv_v1.
  ls_return-message_v2 = iv_v2.
  ls_return-message_v3 = iv_v3.
  ls_return-message_v4 = iv_v4.
  CONCATENATE iv_v1 iv_v2 iv_v3 iv_v4 INTO ls_return-message SEPARATED BY space.
  CONDENSE ls_return-message.
  APPEND ls_return TO ct_return.
ENDFORM.

FORM alpha USING iv_in TYPE kunnr CHANGING cv_out TYPE kunnr.
  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input  = iv_in
    IMPORTING
      output = cv_out.
ENDFORM.

" Felder (Namen mit Leerzeichen getrennt) leeren; fehlende Felder überspringen
FORM clear_fields USING iv_names TYPE csequence CHANGING cs_data TYPE any.
  SPLIT iv_names AT space INTO TABLE DATA(lt_names).
  LOOP AT lt_names INTO DATA(lv_name) WHERE table_line IS NOT INITIAL.
    ASSIGN COMPONENT lv_name OF STRUCTURE cs_data TO FIELD-SYMBOL(<field>).
    IF sy-subrc = 0.
      CLEAR <field>.
    ENDIF.
  ENDLOOP.
ENDFORM.

" Abweichungen aus IT_FIELDS (STRUCTURE = KNB1/KNVV) setzen
FORM apply_fields TABLES it_fields STRUCTURE bapiparex
                         ct_return STRUCTURE bapiret2
                  USING  iv_table TYPE csequence
                  CHANGING cs_data TYPE any.
  LOOP AT it_fields INTO DATA(ls_field) WHERE structure = iv_table.
    DATA(lv_name) = to_upper( condense( ls_field-valuepart1 ) ).
    ASSIGN COMPONENT lv_name OF STRUCTURE cs_data TO FIELD-SYMBOL(<field>).
    IF sy-subrc = 0.
      <field> = ls_field-valuepart2.
    ELSE.
      PERFORM add_return TABLES ct_return USING 'E' 'Feld' lv_name 'gibt es nicht in' iv_table.
    ENDIF.
  ENDLOOP.
ENDFORM.
