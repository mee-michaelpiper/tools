*&---------------------------------------------------------------------*
*&  Include           YSDWSI_DOCUMENT_RESPONSE
*&---------------------------------------------------------------------*
*&----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*&----------------------------------------------------------------------
*Leutbecher |21.06.2017                                     |C242871
* OTF Data in Processklasse zurückgeben                     |
*&----------------------------------------------------------------------
*Leutbecher |19.11.2018                                     |C299719
* Bis hierhin war die Aufbereitung, alles weiter führte    |
*-----------------------------------------------------------------------
CALL METHOD ycl_sdws_interface_document=>set_document_response
  EXPORTING
    it_otf         = gt_otfdata[]
  EXCEPTIONS                                                "C299719
    leave_programm = 1                                      "C299719
    OTHERS         = 2.                                     "C299719

CHECK sy-subrc NE 1.                                        "C299719
