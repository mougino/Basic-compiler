%-------------------------------------------------------------------
% Detect if RFO BASIC! is on the system
%-------------------------------------------------------------------
FILE.EXISTS rfo, rfopath$
IF !rfo
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_no_rfo = GW_NEW_PAGE()
  GW_ADD_TITLEBAR(pg_no_rfo, tibar1$)

  GW_START_CENTER(pg_no_rfo)
  GW_ADD_IMAGE(pg_no_rfo, "rfo.png")
  GW_STOP_CENTER(pg_no_rfo)

  GW_ADD_TEXT(pg_no_rfo, LBL$("no_rfo_1")) % RFO BASIC! was not detected on your device.
  GW_ADD_TEXT(pg_no_rfo, LBL$("no_rfo_2")) % You can install it from here:

  GW_START_CENTER(pg_no_rfo)
  GW_INJECT_HTML(pg_no_rfo, "<a onclick=javascript:RFO('LNK')>")
  GW_ADD_IMAGE(pg_no_rfo, "goo.png")
  GW_ADD_TEXT(pg_no_rfo, "RFO BASIC!")
  GW_INJECT_HTML(pg_no_rfo, "</a>")
  GW_STOP_CENTER(pg_no_rfo)

  GW_ADD_BUTTON(pg_no_rfo, LBL$("exit"), "BACK") % Exit
  GW_ADD_LINK(pg_no_rfo, "-" + LBL$("policy") + "-", "PRIPO")

  GW_RENDER(pg_no_rfo)

  r$ = GW_WAIT_ACTION$()
  IF r$ = "LNK" THEN BROWSE "https://play.google.com/store/apps/details?id=com.rfo.Basic"
  IF r$ = "PRIPO" THEN BROWSE "http://mougino.free.fr/com.rfo.compiler_privacy_policy.txt"
  EXIT
ENDIF

%-------------------------------------------------------------------
% List .bas in source/ and its subfolders
%-------------------------------------------------------------------
LIST.CLEAR files
path$ = rfopath$ + "source/"
RecursiveDirWithoutPaths(path$, files, LEN(path$))
LIST.SIZE files, nfiles

%-------------------------------------------------------------------
% Special case: no .bas in source/
%-------------------------------------------------------------------
IF !nfiles
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_no_bas = GW_NEW_PAGE()
  GW_ADD_TITLEBAR(pg_no_bas, tibar1$)

  GW_START_CENTER(pg_no_bas)
  GW_ADD_IMAGE(pg_no_bas, "rfo.png")
  GW_STOP_CENTER(pg_no_bas)

  GW_ADD_TEXT(pg_no_bas, LBL$("no_bas_1")) % There is no BASIC! program in <b>rfo-basic/source</b>.
  GW_ADD_TEXT(pg_no_bas, LBL$("no_bas_2")) % You need to use the RFO BASIC! Editor to create one.

  GW_ADD_BUTTON(pg_no_bas, LBL$("exit"), "BACK") % Exit
  GW_ADD_LINK(pg_no_bas, "-" + LBL$("policy") + "-", "PRIPO")

  GW_RENDER(pg_no_bas)
  r$ = GW_WAIT_ACTION$()
  IF r$ = "PRIPO" THEN BROWSE "http://mougino.free.fr/com.rfo.compiler_privacy_policy.txt"
  EXIT
ELSE
  LIST.TOARRAY files, bas$[]
  ARRAY.LENGTH nbas, bas$[]
  DIM chk_bas[nbas]
ENDIF

%-------------------------------------------------------------------
% List resources in rfo-basic/data/
%-------------------------------------------------------------------
FILE.DIR rfopath$ + "data", res$[], "/"
ARRAY.LENGTH nres, res$[]
DIM chk_res[nres]    % include resource in app
DIM cp_startup[nres] % copy resource at startup

%-------------------------------------------------------------------
% Build list of images from resource
%-------------------------------------------------------------------
LIST.CLEAR images
FOR i=1 TO nres
  IF RIGHT$(res$[i], 1) = "/" THEN F_N.BREAK % reached folders > we're out
  k = IS_IN(".", res$[i], -1)
  IF k <= 0 THEN F_N.CONTINUE % skip files w/o extension
  ext$ = LOWER$(MID$(res$[i], k+1))
  IF IS_IN("|"+ext$+"|", "|bmp|gif|png|jpg|jpeg|") THEN LIST.ADD images, rfopath$ + "data/" + res$[i]
NEXT
LIST.SIZE images, nimg

%-------------------------------------------------------------------
% Pick app icon / Pick splash screen image: create page
%-------------------------------------------------------------------
IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
pg_app_ico = GW_NEW_PAGE()
GW_ADD_LOADING_IMG(pg_app_ico, "thinking.gif", drk_thm)

GW_ADD_TITLEBAR(pg_app_ico, tibar2$)

bar$ = GW_ADD_BAR_LBUTTON$(LBL$("cancel") + ">BACK") + GW_ADD_BAR_TITLE$("")
GW_ADD_FOOTBAR(pg_app_ico, bar$)

tx_ico = GW_ADD_TEXT(pg_app_ico, "Pick image:") % will be replaced by either "Pick icon" or "Pick splash screen"

IF nimg = 0
  GW_START_CENTER(pg_app_ico)
  GW_USE_THEME_CUSTO_ONCE("style='color:blue'")
  GW_ADD_TEXT(pg_app_ico, "<b>[ " + LBL$("no_img") + " ]</b>") % no image in rfobasic/data
  GW_STOP_CENTER(pg_app_ico)
ELSE
  FOR i=1 TO nimg
    LIST.GET images, i, img$
    html$  = "<a onclick=javascript:RFO('" + INT$(i) + "')><img id='i" + INT$(i)
    html$ += "' style='border:1px solid black;width:64px;margin:5px 5px 5px 5px' "
    html$ += "src='" + img$ + "' /></a><script>$('#i" + INT$(i) + "')"
    html$ += ".on('taphold',function(){RFO('I" + INT$(i) + "');})</script>"
    GW_INJECT_HTML(pg_app_ico, html$)
  NEXT
ENDIF
