*&---------------------------------------------------------------------*
*& Report  YFI_UEBERGABE_BELEGE_ES2000
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*

INCLUDE yfi_uebergabe_belege_top                .    " global Data
INCLUDE yfi_uebergabe_belege_lcl.


INITIALIZATION.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  lcl_fi_upload=>get_instance( )->f4_path(
    EXPORTING
      iv_path_fn = 'P_PATH'
      iv_fityp   = p_fityp
    CHANGING
      cv_path    = p_path
  ).

START-OF-SELECTION.
  lcl_fi_upload=>get_instance( )->read_file(
    EXPORTING
      iv_loct = p_loct
      iv_path = p_path
  ).

END-OF-SELECTION.
  lcl_fi_upload=>get_instance( )->processing( ).
