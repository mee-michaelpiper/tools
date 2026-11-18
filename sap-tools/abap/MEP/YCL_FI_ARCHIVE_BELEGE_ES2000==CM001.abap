  METHOD processing.

    DATA(lo_archive) = NEW ycl_fi_archive_belege_es2000( ).

    lo_archive->read_files_from_directory( iv_path = iv_path  ).

    lo_archive->archive_invoices(
      EXPORTING
        iv_path   = iv_path    " SAP ArchiveLink Dateipfade
        iv_doc_ty = iv_doc_ty    " SAP ArchiveLink: Dokumenttyp
        iv_client = iv_client    " Mandant
        iv_sap_ob = iv_sap_ob    " SAP ArchiveLink: Objekttyp des Business Objekts
        iv_test   = iv_test
    ).

  ENDMETHOD.
