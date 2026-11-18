  method GET_SALESDOCUMENT_DB.
*
**- Tabelle Auftragsköpfe ----------------------------------------------*
**- table order headers ------------------------------------------------*
*  DATA: DA_VBAK type table of VBAK  .
**- Tabelle Auftragspositionen -----------------------------------------*
**- table order items --------------------------------------------------*
*  DATA: DA_VBAPVB type table of VBAPVB  .
**- Tabelle Auftragseinteilungen ---------------------------------------*
**- table order schedules ----------------------------------------------*
*  DATA: DA_VBEPVB type table of VBEPVB   .
**- Tabelle kaufmännische Daten Auftrag --------------------------------*
**- table business data  -----------------------------------------------*
*  DATA: DA_VBKDVB type table of VBKDVB   .
**- Tabelle Auftragspartner --------------------------------------------*
**- table order partners -----------------------------------------------*
*  DATA: DA_VBPAVB type table of VBPAVB  .
**- Tabelle Firmenadresse ---- -----------------------------------------*
**- table company address ----------------------------------------------*
*  DATA: DA_SADRVB type table of SADRVB  .
**- Tabelle Auftrag Kopfstatus -----------------------------------------*
**- table order header status ------------------------------------------*
*  DATA: DA_VBUKVB type table of VBUKVB  .
**- Tabelle Auftrag Positionsstatus  -----------------------------------*
**- table order item status --------------------------------------------*
*  DATA: DA_VBUPVB type table of VBUPVB   .
**- Tabelle Auftragskonditionen ----------------------------------------*
**- table order conditions ---------------------------------------------*
*  DATA: DA_KOMV type table of KOMV   .
**- Tabelle Konditionen (Kopf) -----------------------------------------*
**- table conditions (head)---------------------------------------------*
*  DATA: DA_KONH type table of KONH  .
**- Tabelle Konditionen (Position) -------------------------------------*
**- table conditions (item)---------------------------------------------*
*  DATA: DA_KONP type table of KONP   .
**- Tabelle Konditionen (Mengenstaffel) --------------------------------*
**- table conditions (Quantity Scale) ----------------------------------*
*  DATA: DA_KONM type table of KONM   .
**- Tabelle Konditionen (Wertestaffel)----------------------------------*
**- table conditions  (Quantity Scale) ---------------------------------*
*  DATA: DA_KONW type table of KONW  .
**- Tabelle Auftragsvertragsdaten --------------------------------------*
**- table order contracts ----------------------------------------------*
*  DATA: DA_VEDAVB type table of VEDAVB  .
**- Tabelle Auftrag Text Köpfe -----------------------------------------*
**- table order text headers -------------------------------------------*
*  DATA: DA_THEADVB type table of THEADVB   .
**- Tabelle Auftrag Text Zeilen ----------------------------------------*
**- table order textlines ----------------------------------------------*
*  DATA: DA_TLINE type table of BAPITEXTLI   .
**- Tabelle Auftrag Belegfluss -----------------------------------------*
**- table order flows --------------------------------------------------*
*  DATA: DA_VBFAVB TYPE V45I_VBFA_TABL.
**--CU: Referenz Auftragsposition / Instanz in der Konfiguration -------*
**--Table for External References to Instances of many configurations --*
*  DATA: DA_CUREF type table of BAPICUREFM   .
**--CU: Konfigurationsdaten --------------------------------------------*
**--Table for References to Configurations (Roots) ---------------------*
*  DATA: DA_CUCFG type table of BAPICUCFGM   .
**--CU: Instanzdaten ----------------------------------------------------
**--Table for Instances ------------------------------------------------*
*  DATA: DA_CUINS type table of BAPICUINSM  .
**--CU: PartOf-Daten ----------------------------------------------------
**--Table for Part_Of /Has_Part Relation -------------------------------*
*  DATA: DA_CUPRT type table of BAPICUPRTM  .
**--CU: Merkmalsbewertung ----------------------------------------------*
**--Table for Value Assignments ----------------------------------------*
*  DATA: DA_CUVAL type table of BAPICUVALM  .
**--CU: Konfigurations-BLOB (SCE) --------------------------------------*
**--CU: configurations-BLOB (SCE) --------------------------------------*
*  DATA: DA_CUBLB type table of BAPICUBLBM  .
**--CU: Variantenkondition (SCE) ---------------------------------------*
**--CU: Variant conditions (SCE) ---------------------------------------*
*  DATA: DA_CUVK type table of BAPICUVKM   .
**--Tabelle Fakturierungsplan-------------------------------------------*
**--Table Billing Plan--------------------------------------------------*
*  DATA: DA_FPLAVB type table of FPLAVB   .
**--Tabelle Fakturierungsplan: Datum------------------------------------*
**--Table Billing Plane: Dates------------------------------------------*
*  DATA: DA_FPLTVB type table of FPLTVB   .
**-- View der zu selektierenden Tabellen --------------------------------
**-- View of tables that should be selected -----------------------------
*  DATA: DA_ORDER_VIEW type  ORDER_VIEW.
*
**--Definition des Download-Typs: Initial Download = 005----------------*
**--Definition of the Download-Type: Initial Download = 005-------------*
*  CONSTANTS DA_DOWNLOAD_TYPE(3) VALUE '005'.
*
**- Initialisieren interner Tabellen und Felder ------------------------*
**- intialize internal tables and fields -------------------------------*
*** clear the bapistructures, too.
**  CLEAR:   ORDER_HEADERS_OUT,
**           ORDER_ITEMS_OUT,
**           ORDER_SCHEDULES_OUT,
**           ORDER_BUSINESS_OUT,
**           ORDER_PARTNERS_OUT,
**           ORDER_ADDRESS_OUT,
**           ORDER_STATUSHEADERS_OUT,
**           ORDER_STATUSITEMS_OUT,
**           ORDER_CONDITIONS_OUT,
**           ORDER_COND_HEAD,
**           ORDER_COND_ITEM,
**           ORDER_COND_QTY_SCALE,
**           ORDER_COND_VAL_SCALE,
**           ORDER_CONTRACTS_OUT,
**           ORDER_TEXTHEADERS_OUT,
**           ORDER_TEXTLINES_OUT,
**           ORDER_FLOWS_OUT,
**           ORDER_CFGS_CUREFS_OUT,
**           ORDER_CFGS_CUCFGS_OUT,
**           ORDER_CFGS_CUINS_OUT,
**           ORDER_CFGS_CUPRTS_OUT,
**           ORDER_CFGS_CUVALS_OUT,
**           ORDER_CFGS_CUBLBS_OUT,
**           ORDER_CFGS_CUVKS_OUT,
**           ORDER_BILLINGPLANS_OUT,
**           ORDER_BILLINGDATES_OUT,
**           ORDER_CREDITCARDS_OUT,
**           EXTENSIONOUT.
*
** refresh the bapistructures, too.
*  REFRESH: ORDER_HEADERS_OUT,
*           ORDER_ITEMS_OUT,
*           ORDER_SCHEDULES_OUT,
*           ORDER_BUSINESS_OUT,
*           ORDER_PARTNERS_OUT,
*           ORDER_ADDRESS_OUT,
*           ORDER_STATUSHEADERS_OUT,
*           ORDER_STATUSITEMS_OUT,
*           ORDER_CONDITIONS_OUT,
*           ORDER_COND_HEAD,
*           ORDER_COND_ITEM,
*           ORDER_COND_QTY_SCALE,
*           ORDER_COND_VAL_SCALE,
*           ORDER_CONTRACTS_OUT,
*           ORDER_TEXTHEADERS_OUT,
*           ORDER_TEXTLINES_OUT,
*           ORDER_FLOWS_OUT,
*           ORDER_CFGS_CUREFS_OUT,
*           ORDER_CFGS_CUCFGS_OUT,
*           ORDER_CFGS_CUINS_OUT,
*           ORDER_CFGS_CUPRTS_OUT,
*           ORDER_CFGS_CUVALS_OUT,
*           ORDER_CFGS_CUBLBS_OUT,
*           ORDER_CFGS_CUVKS_OUT,
*           ORDER_BILLINGPLANS_OUT,
*           ORDER_BILLINGDATES_OUT,
*           ORDER_CREDITCARDS_OUT,
*           EXTENSIONOUT.
*
**- Tabellen VBAK und VBKD müssen immer selektiert werden, da sie beim
**- Mapping benötigt werden. --------------------------------------------
**- Tables VBAK and VBKD must be selected every time. They are needed
**- for mapping. --------------------------------------------------------
*  DA_ORDER_VIEW = I_BAPI_VIEW.
*  DA_ORDER_VIEW-HEADER   = 'X'.
*  DA_ORDER_VIEW-BUSINESS = 'X'.
*
**- Massenselect mit Kundenaufträgen -----------------------------------*
**- mass select with order documents -----------------------------------*
*  CALL FUNCTION 'SD_SALES_DOCUMENT_PREFETCH'
*    EXPORTING
*      I_SALES_VIEW             = DA_ORDER_VIEW
*      I_MEMORY_READ            = I_MEMORY_READ
*      I_DET_DYNDAT             = 'X'
*      I_WITH_HEADER_CONDITIONS = I_WITH_HEADER_CONDITIONS
*    TABLES
*      I_VBAK_KEYTAB            = SALES_DOCUMENTS
*      FXVBAK                   = DA_VBAK
*      FXVBAP                   = DA_VBAPVB
*      FXVBEP                   = DA_VBEPVB
*      FXVBKD                   = DA_VBKDVB
*      FXVBPA                   = DA_VBPAVB
*      FXSADR                   = DA_SADRVB
*      FXVBUK                   = DA_VBUKVB
*      FXVBUP                   = DA_VBUPVB
*      FXKOMV                   = DA_KOMV
*      FXKONH                   = DA_KONH
*      FXKONP                   = DA_KONP
*      FXKONM                   = DA_KONM
*      FXKONW                   = DA_KONW
*      FXVEDA                   = DA_VEDAVB
*      FXTHEAD                  = DA_THEADVB
*      FXTLINE                  = DA_TLINE
*      FXVBFA                   = DA_VBFAVB
*      FCUREF                   = DA_CUREF
*      FCUCFG                   = DA_CUCFG
*      FCUINS                   = DA_CUINS
*      FCUPRT                   = DA_CUPRT
*      FCUVAL                   = DA_CUVAL
*      FCUBLB                   = DA_CUBLB
*      FCUVK                    = DA_CUVK
*      FXFPLA                   = DA_FPLAVB
*      FXFPLT                   = DA_FPLTVB.
*
*
*************************************************************************
**- Füllen der Bapistrukturen ------------------------------------------*
**- fill bapistructures ------------------------------------------------*
*************************************************************************
*
*  CALL FUNCTION 'MAP_INT_TO_EXT_STRUCTURE'
*    EXPORTING
*      I_OPERATION    = DA_DOWNLOAD_TYPE
*    TABLES
*      FXVBAK         = DA_VBAK
*      FXVBAP         = DA_VBAPVB
*      FXVBEP         = DA_VBEPVB
*      FXVBKD         = DA_VBKDVB
*      FXVBPA         = DA_VBPAVB
*      FXSADR         = DA_SADRVB
*      FXVBUK         = DA_VBUKVB
*      FXVBUP         = DA_VBUPVB
*      FXKOMV         = DA_KOMV
*      FXKONH         = DA_KONH
*      FXKONP         = DA_KONP
*      FXKONM         = DA_KONM
*      FXKONW         = DA_KONW
*      FXVEDA         = DA_VEDAVB
*      FXCUREFM       = DA_CUREF
*      FXCUCFGM       = DA_CUCFG
*      FXCUINSM       = DA_CUINS
*      FXCUPRTM       = DA_CUPRT
*      FXCUVALM       = DA_CUVAL
*      FXCUBLBM       = DA_CUBLB
*      FXCUVKM        = DA_CUVK
*      FXTHEAD        = DA_THEADVB
*      FXTLINE        = DA_TLINE
*      FXVBFA         = DA_VBFAVB
*      FXFPLA         = DA_FPLAVB
*      FXFPLT         = DA_FPLTVB
*      FXBAPIVBAK     = ORDER_HEADERS_OUT
*      FXBAPIVBAP     = ORDER_ITEMS_OUT
*      FXBAPIVBEP     = ORDER_SCHEDULES_OUT
*      FXBAPIVBKD     = ORDER_BUSINESS_OUT
*      FXBAPIVBPA     = ORDER_PARTNERS_OUT
*      FXBAPISADR     = ORDER_ADDRESS_OUT
*      FXBAPIVBUK     = ORDER_STATUSHEADERS_OUT
*      FXBAPIVBUP     = ORDER_STATUSITEMS_OUT
*      FXBAPIKOMV     = ORDER_CONDITIONS_OUT
*      FXBAPIKONH     = ORDER_COND_HEAD
*      FXBAPIKONP     = ORDER_COND_ITEM
*      FXBAPIKONM     = ORDER_COND_QTY_SCALE
*      FXBAPIKONW     = ORDER_COND_VAL_SCALE
*      FXBAPIVEDA     = ORDER_CONTRACTS_OUT
*      FXBAPITHEAD    = ORDER_TEXTHEADERS_OUT
*      FXBAPITLINE    = ORDER_TEXTLINES_OUT
*      FXBAPIVBFA     = ORDER_FLOWS_OUT
*      FXBAPICUREFM   = ORDER_CFGS_CUREFS_OUT
*      FXBAPICUCFGM   = ORDER_CFGS_CUCFGS_OUT
*      FXBAPICUINSM   = ORDER_CFGS_CUINS_OUT
*      FXBAPICUPRTM   = ORDER_CFGS_CUPRTS_OUT
*      FXBAPICUVALM   = ORDER_CFGS_CUVALS_OUT
*      FXBAPICUBLBM   = ORDER_CFGS_CUBLBS_OUT
*      FXBAPICUVKM    = ORDER_CFGS_CUVKS_OUT
*      FXBAPIFPLA     = ORDER_BILLINGPLANS_OUT
*      FXBAPIFPLT     = ORDER_BILLINGDATES_OUT
*      FXBAPICCARDM   = ORDER_CREDITCARDS_OUT
*      FXEXTENSIONOUT = EXTENSIONOUT.
*
*  IF I_BAPI_VIEW-HEADER IS INITIAL.
*    REFRESH ORDER_HEADERS_OUT.
*    CLEAR   ORDER_HEADERS_OUT.
*  ENDIF.
*
*  IF I_BAPI_VIEW-BUSINESS IS INITIAL.
*    REFRESH ORDER_BUSINESS_OUT.
*    CLEAR   ORDER_BUSINESS_OUT.
*  ENDIF.
*
*

  endmethod.
