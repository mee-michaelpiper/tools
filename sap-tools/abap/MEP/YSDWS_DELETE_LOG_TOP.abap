*&---------------------------------------------------------------------*
*&  Include           YSDWS_DELETE_LOG_TOP
*&---------------------------------------------------------------------*

TYPES: BEGIN OF ty_sel,
         guid  TYPE guid_16,
         datum TYPE datum,
       END OF ty_sel.

DATA gs_sel TYPE ty_sel.
DATA gt_time TYPE YSDWS_LOG_TIME_TT.
