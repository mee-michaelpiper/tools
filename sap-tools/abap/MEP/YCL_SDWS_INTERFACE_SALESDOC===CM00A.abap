  METHOD GET_KUAGV.
    DATA: vtcom     TYPE vtcom.
    DATA: da_busobj TYPE swo_objtyp,
          da_objkey TYPE swo_typeid.

    DATA: da_xvbpa type TABLE OF vbpavb.
    DATA: da_xvbadr type TABLE OF sadrvb.
    DATA: da_xvbuv type TABLE OF  VBUVVB.

    CLEAR vtcom.

    SELECT single      * into CORRESPONDING FIELDS OF vtcom
      FROM  tvak
           WHERE  auart  = 'TA'.



    vtcom-kunnr = iv_kunnr.
    vtcom-parvw = iv_parvw.
    vtcom-vkorg = iv_vkorg.
    vtcom-vtweg = iv_vtweg.
    vtcom-spart = iv_spart.


    CALL FUNCTION 'SD_OBJECT_TYPE_DETERMINE'
      EXPORTING
        i_document_type   = vtcom-vbtyp
      IMPORTING
        e_business_object = da_busobj.

    CALL FUNCTION 'VIEW_KUAGV'
      EXPORTING
        comwa          = vtcom
        fif_objecttype = da_busobj
        fif_objectkey  = da_objkey
        fif_no_log     = 'X'
        fif_no_dialog  = 'X'
      IMPORTING
        agwa           = es_kunwa
      TABLES
        vbuv_tab       = da_xvbuv
        xsadr          = da_xvbadr
        xvbpa          = et_vbpavb
      EXCEPTIONS
        no_kna1        = 1
        no_knvv        = 2
        no_kuagv       = 3
        no_tvta        = 4
        no_cpd_address = 5
        no_tpakd       = 6
        OTHERS         = 7.

    CHECK sy-subrc NE 0.
    " Kundennummer &1 zu &2/&3/&4 ist unbekannt!
    RAISE EXCEPTION TYPE ycx_sdws_interface
      EXPORTING
        textid   = ycx_sdws_interface=>kunnr_not_exist
        mv_kunnr = iv_kunnr
        mv_vkorg = iv_vkorg
        mv_vtweg = iv_vtweg
        mv_spart = iv_spart.

  ENDMETHOD.
