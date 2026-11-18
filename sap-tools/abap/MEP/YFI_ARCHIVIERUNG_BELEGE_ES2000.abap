*&---------------------------------------------------------------------*
*& Report  YFI_ARCHIVIERUNG_BELEGE_ES2000
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

INCLUDE yfi_archivierung_belege_top             .    " global Data

ycl_fi_archive_belege_es2000=>processing(
  EXPORTING
    iv_path   = p_path     " SAP ArchiveLink Dateipfade
    iv_doc_ty = p_doc_ty    " SAP ArchiveLink: Dokumenttyp
    iv_client = p_client    " Mandant
    iv_sap_ob = p_sap_ob    " SAP ArchiveLink: Objekttyp des Business Objekts
    iv_test   = p_test
).
