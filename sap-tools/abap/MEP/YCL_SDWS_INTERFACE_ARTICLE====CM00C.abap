  METHOD read_material.

    DATA material TYPE matnr.
    DATA aktvstatus TYPE pstat_d.
    DATA manbr TYPE manbr.
    data h_waers type waers.


* Schlüssel übergeben an Struktur für zentralen Lesebaustein
    DATA rmmg1 TYPE rmmg1.
    rmmg1-matnr = material = is_import-i_objky.
    rmmg1-bukrs = is_import-companycode.
    rmmg1-spras = sy-langu.
    rmmg1-werks = is_import-plant.
    rmmg1-bwkey = is_import-valuationarea.
    rmmg1-bwtar = is_import-valuationtype.
    rmmg1-lgort = is_import-storagelocation.
    rmmg1-vkorg = is_import-salesorganisation.
    rmmg1-vtweg = is_import-distributionchannel.
    rmmg1-lgnum = is_import-warehousenumber.
    rmmg1-lgtyp = is_import-storagetype.

*        companycode                = is_import-companycode
*        valuationarea              = is_import-valuationarea
*        valuationtype              = is_import-valuationtype
*        plant                      = is_import-plant
*        storagelocation            = is_import-storagelocation
*        salesorganisation          = is_import-salesorganisation
*        distributionchannel        = is_import-distributionchannel
*        warehousenumber            = is_import-warehousenumber
*        storagetype                = is_import-storagetype


    CALL FUNCTION 'MATERIAL_READ_ALL'
      EXPORTING
        herkunft      = 'Z'   "HERKUNFT_MATL
        aktyp         = 'A'   "AKTYPA
        wrmmg1        = rmmg1
        tcode         = 'MM03'
        kz_berprf     = 'X'
        kz_status_det = 'X'
        kzrfb         = 'X'   "LV_KZRFB                "note 1027624
        call_mode     = 'X'   "CALL_MODE_BAPI
      IMPORTING
        aktvstatus    = aktvstatus
        wrmmg1        = rmmg1
        rmmg2_manbr   = manbr
        tmara         = mara
        tmarc         = marc
        tmpgd         = mpgd
        tmard         = mard
        tmbew         = mbew
        tmfhm         = mfhm
        tmlgn         = mlgn
        tmlgt         = mlgt
        tmpop         = mpop
        tmvke         = mvke
        tmyms         = myms
        t001_waers    = h_waers
      TABLES
*        mtab          = mtab_ausw
        meinh         = MT_UNITSOFMEASURE "Mengeneinheiten
        ktext         = MT_MATERIALDESCRIPTION   "ktext
*        steuertab     = steuertab
*        steummtab     = steummtab
*        mean_me_tab   = mean_me_tab
*        amerrdat      = amerrdat
      EXCEPTIONS
        error_message = 01
        OTHERS        = 02.

*    CALL FUNCTION 'BAPI_MATERIAL_GETALL'
*      EXPORTING
*        material                   = lv_matnr
*        companycode                = is_import-companycode
*        valuationarea              = is_import-valuationarea
*        valuationtype              = is_import-valuationtype
*        plant                      = is_import-plant
*        storagelocation            = is_import-storagelocation
*        salesorganisation          = is_import-salesorganisation
*        distributionchannel        = is_import-distributionchannel
*        warehousenumber            = is_import-warehousenumber
*        storagetype                = is_import-storagetype
**       LIFOVALUATIONLEVEL         =
**       MATERIAL_EVG               =
**       KZRFB_ALL                  =
*      IMPORTING
*        clientdata                 = ms_clientdata
*        plantdata                  = ms_plantdata
*        forecastparameters         = ms_forecastparameters
*        planningdata               = ms_planningdata
*        storagelocationdata        = ms_storagelocationdata
*        valuationdata              = ms_valuationdata
*        warehousenumberdata        = ms_warehousenumberdata
*        salesdata                  = ms_salesdata
*        storagetypedata            = ms_storagetypedata
*        productionresourcetooldata = ms_productionresourcetooldata
*        lifovaluationdata          = ms_lifovaluationdata
*      TABLES
*        materialdescription        = mt_materialdescription
*        unitsofmeasure             = mt_unitsofmeasure
*        internationarticlenumbers  = mt_internationarticlenumbers
*        materialtext               = mt_materialtext
*        taxclassifications         = mt_taxclassifications
*        extensionout               = mt_extensionout
*        return                     = mt_returns.


    IF sy-subrc NE 0.
      RAISE EXCEPTION TYPE ycx_sdws_interface
        EXPORTING
          textid   = ycx_sdws_interface=>matnr_not_exist
          mv_matnr = material.
    ENDIF.

* MATERIALLONGTEXT füllen

* Grunddatentexte versorgen
 get_langtext(
  EXPORTING
    p_id       = GRUNDDTEXT_TDID
    p_material = MATERIAL
  CHANGING
    p_mltx     = MT_MATERIALTEXT ).

* Bestelltexte versorgen
 get_langtext(
  EXPORTING
    p_id       = BESTELLTEXT_TDID
    p_material = MATERIAL
  CHANGING
    p_mltx     = MT_MATERIALTEXT ).

* Prueftexte versorgen
 get_langtext(
  EXPORTING
    p_id       = PRUEFTEXT_TDID
    p_material = MATERIAL
  CHANGING
    p_mltx     = MT_MATERIALTEXT ).

* Interner Vermerk versorgen
 get_langtext(
  EXPORTING
    p_id       = IVERMTEXT_TDID
    p_material = MATERIAL
  CHANGING
    p_mltx     = MT_MATERIALTEXT ).

* Vertriebstext versorgen
 get_langtext(
  EXPORTING
    p_id       = VERTRIEBSTEXT_TDID
    p_material = MATERIAL
    P_SALESORG = is_import-salesorganisation
    P_DISTR_CHAN = is_import-distributionchannel
  CHANGING
    p_mltx     = mt_materialtext ).

* Materialnotiz versorgen
 get_langtext(
  EXPORTING
    p_id       = MATNOTIZ_TDID
    p_material = MATERIAL
    P_plant = is_import-PLANt
  CHANGING
    p_mltx     = mt_materialtext ).




  ENDMETHOD.
