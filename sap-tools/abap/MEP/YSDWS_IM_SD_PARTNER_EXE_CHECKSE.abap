ENHANCEMENT 1  .
*-----------------------------------------------------------------------
* Changes                                                   |patch
* Name      |Date                                           |K-Korrektur
* Description:                                              |C-ChangeReq
*-----------------------------------------------------------------------
*Leutbecher |22.09.2017                                    |C254822
*Prüfungen bei dieserWebService Methode nicht durchführen|
*-----------------------------------------------------------------------
*

 IF /fis/cl_bc_tools=>check_system_callstack( iv_mainprogram = 'YCL_SDWS_INTERFACE_CUSTOMER===CP'
                                            iv_blockname =  'GET_PARTNERS_DATA' ) = abap_true.
   exit.
 endif.
ENDENHANCEMENT.
