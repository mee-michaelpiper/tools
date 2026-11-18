*&---------------------------------------------------------------------*
*& Report  YSDWS_CALL_DRUCKPRG
* Entwickler:     Thomas Leutbecher
* Datum:          13.7.2017
*
* Beschreibung:   Testprogramm, Baustein ruft Druckprogramm
*
*                 FIS/OSS: 254822
*----------------------------------------------------------------------*
* Änderungshistorie: (alt nach neu)
*Entwickler Datum                                                  Patch
*Beschreibung                              (K)orrektur (C)hangereq OssNr
*----------------------------------------------------------------------*
REPORT ysdws_call_druckprg.

DATA gs_import TYPE  ysdws_document_data_i_s.
DATA gs_export TYPE  ysdws_document_e_s.

PARAMETERS: p_sid   TYPE ysdws_document_data_i_s-i_sessionid OBLIGATORY,
            p_kunnr TYPE ysdws_document_data_i_s-i_kunnr  OBLIGATORY,
       "     p_langu TYPE ysdws_document_data_i_s-i_langu DEFAULT sy-langu,
            p_objky TYPE ysdws_document_data_i_s-i_objky OBLIGATORY,
            p_kschl TYPE ysdws_document_data_i_s-i_kschl OBLIGATORY.
INITIALIZATION.

p_sid = 'DATAHUB' && sy-uname && sy-datum && sy-uzeit.


START-OF-SELECTION.

  gs_import-i_kschl = p_kschl.
  gs_import-i_kunnr = P_kunnr.
"  gs_import-i_langu = p_langu.
  gs_import-i_objky = p_objky.
  gs_import-i_sessionid = p_sid.

  CALL FUNCTION 'Y_SDWS_GET_DOCUMENT'
    EXPORTING
      is_import = gs_import
    IMPORTING
      es_export = gs_export.
