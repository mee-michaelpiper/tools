  METHOD read_files_from_directory.

    DATA: lt_files TYPE /fisxee/salfldir_t,
          lv_path  TYPE salfile-longname.

    FIELD-SYMBOLS: <ls_file> LIKE LINE OF lt_files.

    lv_path = iv_path.

    CALL FUNCTION 'RZL_READ_DIR_LOCAL'
      EXPORTING
        name           = lv_path
      TABLES
        file_tbl       = lt_files
      EXCEPTIONS
        argument_error = 1
        not_found      = 2
        OTHERS         = 3.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    "delete rows defining directory (which start from '.')
    "or subdirectory (which start from '..')
    LOOP AT lt_files ASSIGNING <ls_file>.

      IF <ls_file>-name(1) = '.'.
        CLEAR <ls_file>-name .
      ENDIF.

    ENDLOOP.

    DELETE lt_files WHERE name = space.

    REFRESH mt_files.
    mt_files = lt_files.
  ENDMETHOD.
