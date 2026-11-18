*&---------------------------------------------------------------------*
*& Include YFI_ARCHIVIERUNG_BELEGE_TOP                       Report YFI_ARCHIVIERUNG_BELEGE_ES2000
*&
*&---------------------------------------------------------------------*
REPORT YFI_ARCHIVIERUNG_BELEGE_ES2000.

CONSTANTS: gc_invoice_path   TYPE sapb-sappfad     VALUE ' ',
           gc_archive_object TYPE toa01-sap_object VALUE 'YIFINVOICE',
           gc_repository     TYPE toa01-archiv_id  VALUE 'FD',
           gc_document_type  TYPE saedoktyp        VALUE 'PDF',
           gc_client         TYPE mandt            VALUE '100',
           gc_sap_object     TYPE toa01-sap_object VALUE 'BKPF',
           gc_reserve        TYPE toa01-reserve    VALUE 'PDF'.

*DATA: go_invoice_manager TYPE REF TO lcl_invoice_manager.

*selection-screen
PARAMETER: p_path     TYPE sapb-sappfad     DEFAULT gc_invoice_path   OBLIGATORY,
*           p_ar_ob    TYPE toa01-sap_object DEFAULT gc_archive_object OBLIGATORY,
*           p_repos    TYPE toa01-archiv_id  DEFAULT gc_repository     OBLIGATORY,
           p_doc_ty   TYPE saedoktyp        DEFAULT gc_document_type  OBLIGATORY,
           p_client   TYPE mandt            DEFAULT gc_client         OBLIGATORY,
           p_sap_ob   TYPE toa01-sap_object DEFAULT gc_sap_object     OBLIGATORY,
           p_test TYPE flag AS CHECKBOX DEFAULT 'X'.
