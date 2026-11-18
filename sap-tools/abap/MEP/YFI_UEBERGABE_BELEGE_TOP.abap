*&---------------------------------------------------------------------*
*& Include YFI_UEBERGABE_BELEGE_TOP                          Report YFI_UEBERGABE_BELEGE_ES2000
*&
*&---------------------------------------------------------------------*
REPORT YFI_UEBERGABE_BELEGE_ES2000.

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-b01.
* Dateityp
PARAMETERS: p_fityp TYPE dxfiletyp OBLIGATORY DEFAULT 'P'.

* Art des Ablageorts
PARAMETERS p_loct TYPE /fis/bc_file_locationtype OBLIGATORY DEFAULT 'L'.

* Pfad fuer Ausgabedateien
PARAMETERS: p_path TYPE catfilnam.
SELECTION-SCREEN: END OF BLOCK b1.
PARAMETERS: p_test TYPE flag AS CHECKBOX DEFAULT 'X',
            p_refpr TYPE flag AS CHECKBOX DEFAULT 'X'.
