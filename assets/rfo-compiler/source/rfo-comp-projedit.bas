%-------------------------------------------------------------------
% RFO-Compiler Project-Edit pages
%-------------------------------------------------------------------

%---------------------------------
ver$  = VERSION$()  % version name
verx$ = VERSIONX$() % version code
verx$ = " (" + verx$ + ")"
%---------------------------------

GW_COLOR$="black"
GW_SILENT_LOAD=1
INCLUDE "GW.bas"
INCLUDE "utils_str.bas"
INCLUDE "utils_file.bas"
INCLUDE "utils_xml.bas"
INCLUDE "utils_zip.bas"

e$ = "Welcome to BASIC! Compiler "
e$ += ver$ + verx$
PRINT e$

%-------------------------------------------------------------------
% Remove language files from SD to use freshest ones in assets/
%-------------------------------------------------------------------
FILE.DELETE fid, "labels_EN.txt"
FILE.DELETE fid, "labels_FR.txt"
FILE.DELETE fid, "labels_DE.txt"
FILE.DELETE fid, "labels_RO.txt"

%-------------------------------------------------------------------
DefConst:
%-------------------------------------------------------------------
ARRAY.LOAD tool$[], "+aapt", "android.jar", "cert.x509.pem", "key.pk8"
ARRAY.LOAD con_emptycol$[], "background", "line"
ARRAY.LOAD con_fntsiz$[], "Small", "Medium", "Large"
ARRAY.LOAD con_fnttyp$[], "Monospace", "Sans Serif", "Serif"
ARRAY.LOAD xml_fnttyp$[], "MS", "SS", "S"
ARRAY.LOAD con_scrdir$[], "Variable By Sensors", "Fixed Landscape", "Fixed Reverse Landscape", ~
                          "Fixed Portrait", "Fixed Reverse Portrait"
ARRAY.LOAD file_ico$[], "basic.gif", "archive.gif", "folder.gif", "image.gif", ~
                        "music.gif", "any.gif", "video.gif", "www.gif"
ARRAY.LOAD ico_siz$[], "<b>ldpi</b><br>(~36x36)", "<b>mdpi</b><br>(&ge;48x48)", "<b>hdpi</b><br>(&ge;72x72)", ~
          "<b>xhdpi</b><br>(&ge;96x96)", "<b>xxhdpi</b><br>(&ge;144x144)", "<b>xxxhdpi</b><br>(&ge;192x192)"
ARRAY.LOAD perm_ico$[], "perm1.png", "perm2.png", "perm3.4.5.6.png", "perm7.png", "perm8.png", "perm9.png", ~
                        "perm10.11.png", "perm12.png", "perm13.png", "perm14.15.16.png", "perm17.png", "perm20.png"
ARRAY.LOAD permissions$[], ~
  "01.WRITE_EXTERNAL_STORAGE", ~
  "02.INTERNET", ~
  "03.ACCESS_COARSE_LOCATION", ~
  "04.ACCESS_MOCK_LOCATION", ~
  "05.ACCESS_FINE_LOCATION", ~
  "06.ACCESS_LOCATION_EXTRA_COMMANDS", ~
  "07.VIBRATE", ~
  "08.WAKE_LOCK", ~
  "09.CAMERA", ~
  "10.BLUETOOTH", ~
  "11.BLUETOOTH_ADMIN", ~
  "12.RECORD_AUDIO", ~
  "13.READ_PHONE_STATE", ~
  "14.READ_SMS", ~
  "15.SEND_SMS", ~
  "16.RECEIVE_SMS", ~
  "17.CALL_PHONE", ~
  "18.ACCESS_NETWORK_STATE", ~
  "19.DUMP", ~
  "20.ACCESS_WIFI_STATE", ~
  "21.CHANGE_WIFI_STATE"
ARRAY.LENGTH nperm, permissions$[]
DIM chk_perm[nperm]

% Get the rules "BASIC! Keyword -> Permissions"
kwperm$ = GetFile$("kwperms.txt")
kwperm$ = REPLACE$(kwperm$, CHR$(13), "") % Remove all $CR
SPLIT kwperm$[], kwperm$, "\\n" % split on new line
ARRAY.LENGTH nkwperm, kwperm$[]

% Define immutable paths
rfopath$ = "../../rfo-basic/"
comppath$ = "../../rfo-compiler/"
supath$ = "../../rfo-super-user/data/"
FILE.ROOT data$ : data$ += "/"
sys$ = SYSPATH$() % "/data/data/com.rfo.compiler/" by default
bsys$ = "../../../../../../.." + sys$

% Get device language and Android OS version
DEVICE info
BUNDLE.GET info, "OS", os$
i = IS_IN(".", os$)
i = IS_IN(".", os$, i+1)
IF i THEN os$ = LEFT$(os$, i-1)
BUNDLE.GET info, "Locale", lang$
lang$ = UPPER$(LEFT$(lang$, 2))
LIST.CREATE s, images
LIST.CREATE s, files
LIST.CREATE n, proj_ts % projects timestamps
LIST.CREATE s, proj_fn % projects filenames
LIST.CREATE s, mm_fina % mismatching resource filenames
LIST.CREATE s, mm_desc % mismatching resource description (bas+line where it occurs, etc.)

%-------------------------------------------------------------------
% Start
%-------------------------------------------------------------------
INCLUDE "rfo-comp-fns.bas"
GOSUB InstallResource
GOSUB GetLabels
ARRAY.LOAD con_empty$[], LBL$("bgd_col"), LBL$("lin_col")

%-------------------------------------------------------------------
% Read config file
%-------------------------------------------------------------------
fast_cp = 1 % enable fast re-compile by default
log_act = 1 % enable debug logs by default
TEXT.OPEN r, cfg_id, bsys$ + "compiler.cfg"
IF cfg_id <> -1
  TEXT.READLN cfg_id, e$ : IF IS_NUMBER(e$) THEN drk_thm = VAL(e$) % dark theme
  TEXT.READLN cfg_id, e$ : IF IS_NUMBER(e$) THEN fast_cp = VAL(e$) % fast re-compile
  TEXT.READLN cfg_id, e$ : IF IS_NUMBER(e$) THEN log_act = VAL(e$) % logs activated
  TEXT.READLN cfg_id, e$ : IF IS_NUMBER(e$) THEN vis_imp = VAL(e$) % visually impaired
  TEXT.READLN cfg_id, e$ : IF IS_NUMBER(e$) THEN spr_usr = VAL(e$) % super user
  TEXT.CLOSE cfg_id
ENDIF

%-------------------------------------------------------------------
% Make the 2 theme custos (light & dark)
%-------------------------------------------------------------------
light=GW_NEW_THEME_CUSTO("color='a'")
dark=GW_NEW_THEME_CUSTO("color='b'")

%-------------------------------------------------------------------
% Make the 2 title bars shared by all screens
%-------------------------------------------------------------------
IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
dummy = GW_NEW_PAGE()
% First one :   [        TITLE (Exit) ]
tit$ = LBL$("compiler") + " v" + ver$ + verx$
tibar1$ = GW_ADD_BAR_TITLE$(tit$)
GW_USE_THEME_CUSTO_ONCE("icon=power notext")
tibar1$ += GW_ADD_BAR_RBUTTON$(">EXIT")
% Second one :  [ (Home) TITLE (Exit) ]
GW_USE_THEME_CUSTO_ONCE("icon=home notext")
tibar2$ = GW_ADD_BAR_LBUTTON$(">HOME")
tibar2$ += GW_ADD_BAR_TITLE$(tit$)
GW_USE_THEME_CUSTO_ONCE("icon=power notext")
tibar2$ += GW_ADD_BAR_RBUTTON$(">EXIT")

%-------------------------------------------------------------------
% Detect if RFO BASIC! is on the system and there is at least a .bas
%-------------------------------------------------------------------
INCLUDE "rfo-presence.bas"

%-------------------------------------------------------------------
% Prevent update VIP -> paying
%-------------------------------------------------------------------
FILE.EXISTS fid, bsys$ + "freeforum.usr"
IF fid % illegal update from VIP Compiler (e.g. v.'1900') to paying Compiler (e.g. v.'1901')
  POPUP "Illegal update from VIP"
  EXIT
ENDIF

%-------------------------------------------------------------------
% Projects menu: create page
%-------------------------------------------------------------------
Proj_Menu: % Screen #0
IF !pg_proj
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_proj = GW_NEW_PAGE()
  GW_INSERT_BEFORE(pg_proj, "</head", "<script src='diacritics.js'></script>")
  GW_ADD_LOADING_IMG(pg_proj, "thinking.gif", drk_thm)

  panel$  = "<h2>"+LBL$("opt")+"</h2>"
  panel$ += GW_ADD_CHECKBOX$(LBL$("fast-cp")) % Allow fast re-compile
  chk_fast_cp = GW_LAST_ID()
  panel$ += GW_ADD_CHECKBOX$(LBL$("log-act")) % Activate logs
  chk_log_act = GW_LAST_ID()
  panel$ += GW_ADD_CHECKBOX$(LBL$("vis-imp")) % Dedicated permission screen for the visually impaired
  chk_vis_imp = GW_LAST_ID()
  panel$ += GW_ADD_CHECKBOX$("<span style='color:red'>" + LBL$("sup-opt") + "</span>") % Super User
  chk_spr_usr = GW_LAST_ID()
  panel$ += "<table><thead></thead><tbody><tr><td>"
  panel$ += GW_ADD_TEXT$(LBL$("drk-thm")) % Dark theme
  panel$ += "</td><td>"
  panel$ += GW_ADD_FLIPSWITCH$("", LBL$("no"), LBL$("yes"))
  flip_drk_thm = GW_LAST_ID()
  panel$ += "</td></tr></tbody></table>"
  panel$ += GW_ADD_BUTTON$(LBL$("cust-cert"), "CUSTOCERT")
  panel$ += GW_ADD_BUTTON$(LBL$("policy"), "PRIPO")
  panel$ += GW_ADD_BUTTON$(LBL$("contact"), "EMAIL")
  pnl_proj = GW_ADD_PANEL(pg_proj, panel$)
  GW_ADD_LISTENER(pg_proj, pnl_proj, "close", "SAVPREF")
  GW_USE_THEME_CUSTO_ONCE("icon=gear notext")
  GW_ADD_TITLEBAR(pg_proj, GW_ADD_BAR_LBUTTON$(">" + GW_SHOW_PANEL$(pnl_proj)) + tibar1$)

  ARRAY.LOAD sendlog$[], UPPER$(LBL$("yes")) + ">EMAIL_LOG", LBL$("no") + ">EMAIL_VOID"
  GW_USE_THEME_CUSTO_ONCE("inline")
  dm_send_log = GW_ADD_DIALOG_MESSAGE(pg_proj, LBL$("contact"), LBL$("send-log"), sendlog$[]) % Logs detected. Send them?

  ARRAY.LOAD pjdel$[], UPPER$(LBL$("del")) + ">DEL", LBL$("cancel")
  GW_USE_THEME_CUSTO_ONCE("inline")
  dm_proj_del = GW_ADD_DIALOG_MESSAGE(pg_proj, "", LBL$("del_proj"), pjdel$[]) % Delete this project ?

  e$  = LBL$("sel_proj") + " <small><i>(" % Select a project:
  e$ += LBL$("tap_opt") + ")</i></small>" % long-press for options
  GW_ADD_TEXT(pg_proj, e$)

  style$  = "td{vertical-align:middle} img{display:block;"
  style$ += "max-width:96px;max-height:96px;width:auto;"
  style$ += "height:auto} body{-webkit-user-select:none}"
  GW_INJECT_HTML(pg_proj, "<style>" + style$ + "</style>")

  GW_INJECT_HTML(pg_proj, "<table><thead></thead><tbody>")
  GW_INJECT_HTML(pg_proj, "<tr id='new'><td>")
  GW_ADD_IMAGE(pg_proj, "new.png")
  GW_INJECT_HTML(pg_proj, "</td><td style='width:5px'></td><td>")
  e$  = "<b><i>" + LBL$("new_apk") + "</i></b>\n" % New APK
  e$ += "<hr>" + LBL$("pick_among") + "\n" % Pick among
  e$ += "<b>" + INT$(nbas) + " " + Plural$(LOWER$(LBL$("prog")), nbas) + "</b>\n"                 % N program(s)
  e$ += LBL$("and") + " <b>" + INT$(nres) + " " + Plural$(LOWER$(LBL$("res")), nres) + "</b>\n"   % and N resource(s)
  e$ += LBL$("inc") + " <b>" + INT$(nimg) + " " + Plural$(LOWER$(LBL$("img")), nimg) + "</b>"     % inc. N image(s)
  GW_ADD_TEXT(pg_proj, e$)
  GW_INJECT_HTML(pg_proj, "</td></tr><tr style='height:20px'></tr>")
  GW_INJECT_HTML(pg_proj, "<script>$('#new').click(function(){RFO('NEW');})</script>")
  ph_projects = GW_ADD_PLACEHOLDER(pg_proj) % list of all the projects, single-tap to open / long-press for options
  GW_INJECT_HTML(pg_proj, "</tbody></table>")
ENDIF

%-------------------------------------------------------------------
% Get Super User flavors
%-------------------------------------------------------------------
path$ = supath$
ext$ = ".desc"
GOSUB ListFiles
LIST.INSERT files, 1, "RFO-BASIC " + ver$ + " (standard)"
nflav = nfiles + 1
LIST.TOARRAY files, flav$[]
IF nflav > 1
  FOR i=2 TO nflav
    flav$[i] = LEFT$(FileName$(flav$[i]), -5) % remove .desc extension
  NEXT
ENDIF

%-------------------------------------------------------------------
% List projects (.rfo files) and order them by last time edited
%-------------------------------------------------------------------
LIST.CLEAR proj_fn
LIST.CLEAR proj_ts
path$ = comppath$
ext$ = ".rfo"
GOSUB ListFiles
nproj = nfiles
FOR i=1 TO nproj
  file$ = ELT$(files, i)
  LIST.ADD proj_fn, file$
  LIST.ADD proj_ts, GetProjectTimestamp(file$)
NEXT
% Bubble-sort projects by decreasing timestamp
FOR i=1 TO nproj
  FOR j=i+1 TO nproj
    LIST.GET proj_ts, i, ts1
    LIST.GET proj_ts, j, ts2
    IF ts1 < ts2
      ListSwap(proj_ts, i, j)
      ListSwap(proj_fn, i, j)
    ENDIF
  NEXT
NEXT

%-------------------------------------------------------------------
% Projects menu: populate with actual projects
%-------------------------------------------------------------------
html$ = ""
FOR i=1 TO nproj
  file$ = ELT$(proj_fn, i)
  html$ += "<tr id='p" + INT$(i) + "'><td>"
  html$ += GW_ADD_IMAGE$(GetProjectIcon$(file$))
  html$ += "</td><td style='width:5px'></td><td>" + GetProjectHeader$(file$)
  html$ += "</td></tr><tr style='height:20px'></tr>"
  html$ += "<script>$('#p" + INT$(i) + "').on('taphold',"
  html$ += "function(){RFO('OPT" + INT$(i) + "');});"
  html$ += "$('#p" + INT$(i) + "').click(function()"
  html$ += "{RFO('OPN" + INT$(i) + "');})</script>"
NEXT
GW_FILL_PLACEHOLDER(pg_proj, ph_projects, html$)

%-------------------------------------------------------------------
% Projects menu: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_proj)
IF drk_thm THEN GW_MODIFY(flip_drk_thm, "selected", LBL$("yes"))
IF fast_cp THEN GW_MODIFY(chk_fast_cp, "checked", "1")
IF log_act THEN GW_MODIFY(chk_log_act, "checked", "1")
IF vis_imp THEN GW_MODIFY(chk_vis_imp, "checked", "1")
IF spr_usr THEN GW_MODIFY(chk_spr_usr, "checked", "1")
DO : r$=GW_ACTION$() : UNTIL r$="" % empty event buffer due to last GW_MODIFY(flipswitch)
new_drk_thm=drk_thm
DO
  r$ = GW_WAIT_ACTION$()
  FILE.EXISTS logfile, "../Compiler.log"
  IF r$ = "EMAIL" & logfile THEN r$ = "" : GW_SHOW_DIALOG(dm_send_log) % Logs detected. Send them?
  IF IS_IN("EMAIL", r$) = 1
    IF IS_IN("LOG", r$) THEN body$ = GetFile$("../Compiler.log") ELSE body$ = ""
	EMAIL.SEND "mougino@free.fr", "BASIC! Compiler " + ver$ + verx$ + " feedback", body$
	r$ = ""
  ENDIF
  IF r$ = "PRIPO" THEN r$="" : BROWSE "http://mougino.free.fr/com.rfo.compiler_privacy_policy.txt"
  IF r$ = "CUSTOCERT" THEN r$="" : BROWSE "http://mougino.free.fr/com.rfo.compiler_custom_certificate_howto.htm"
  IF r$ = "EXIT" | r$ = "BACK" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(flip_drk_thm, LBL$("no")) % user switched to light theme
    new_drk_thm=0 : r$=""
  ELSEIF GW_FLIPSWITCH_CHANGED(flip_drk_thm, LBL$("yes")) % user switched to dark theme
    new_drk_thm=1 : r$=""
  ELSEIF r$ = "SAVPREF" % user closed options panel -> save options
    fast_cp = GW_CHECKBOX_CHECKED(chk_fast_cp) % fast re-compile
    log_act = GW_CHECKBOX_CHECKED(chk_log_act) % logs activated
    vis_imp = GW_CHECKBOX_CHECKED(chk_vis_imp) % visually impaired
    spr_usr = GW_CHECKBOX_CHECKED(chk_spr_usr) % super user
    IF new_drk_thm<>drk_thm
      JS("$('.se-pre-con').show()") % show loading gif
      drk_thm=new_drk_thm
      GOSUB SaveConfigFile
      GOSUB ChangeThemeInAllPages
      GOTO Proj_Menu
    ELSE
      GOSUB SaveConfigFile
    ENDIF
    r$=""
  ELSEIF IS_IN("OPT", r$) = 1 % long-press on a project for option
    pjdel$[1] = UPPER$(LBL$("del")) + ">DEL" + MID$(r$, 4)
    proj = VAL(MID$(r$, 4))
    IF !proj THEN D_U.CONTINUE
    proj$ = LTRIM$(RTRIM$(ELT$(proj_fn, proj), ".rfo"), comppath$)
    GW_MODIFY(dm_proj_del, "title", UPPER$(proj$))
    GW_USE_THEME_CUSTO_ONCE("inline")
    GW_AMODIFY(dm_proj_del, "buttons", pjdel$[])
    GW_SHOW_DIALOG_MESSAGE(dm_proj_del)
    r$ = ""
  ELSEIF IS_IN("DEL", r$) = 1 % delete a project
    proj = VAL(MID$(r$, 4))
    IF !proj THEN D_U.CONTINUE
		proj$ = ELT$(proj_fn, proj)
		GOSUB DeleteProject
		proj$ = ""
  ENDIF
UNTIL LEN(r$)
IF IS_IN("DEL", r$) = 1 THEN GOTO Proj_Menu % refresh list of projects
IF IS_IN("OPN", r$) = 1 % user single-tapped on a project -> open it
  proj = VAL(MID$(r$, 4))
  proj$ = ELT$(proj_fn, proj)
  GOSUB InitProject % reset all project fields inc. checked include/resource etc.
  GOSUB LoadProject
ELSE % "NEW"
  appbas$ = ""
  GOSUB InitProject
ENDIF

%-------------------------------------------------------------------
% Select main .bas: create page
%-------------------------------------------------------------------
Sel_Bas: % Screen #1
IF !pg_sel_bas
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_sel_bas = GW_NEW_PAGE()
  GW_INSERT_BEFORE(pg_sel_bas, "</head", "<script src='diacritics.js'></script>")
  GW_ADD_LOADING_IMG(pg_sel_bas, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_sel_bas, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_sel_bas, bar$)

  e$  = LBL$("has_gw_1") + "\n" % We detected that your app makes use of the GW lib.
  e$ += LBL$("has_gw_2") + "\n" % BASIC! Compiler will attach the correct files...
  e$ += LBL$("has_gw_3") % Cool?
  ARRAY.LOAD cool$[], UPPER$(LBL$("has_gw_4")) % COOL
  dm_sel_bas = GW_ADD_DIALOG_MESSAGE(pg_sel_bas, UPPER$(LBL$("has_gw_0")), e$, cool$[])

  GW_START_CENTER(pg_sel_bas)
  art = GW_ADD_IMAGE(pg_sel_bas, "art.png")
  GW_ADD_LISTENER(pg_sel_bas, art, "longpress", "GOFAST")
  GW_STOP_CENTER(pg_sel_bas)

  box_sel_bas = GW_ADD_SELECTBOX(pg_sel_bas, LBL$("sel_bas"), bas$[]) % Select your main program
  GW_ADD_LISTENER(pg_sel_bas, box_sel_bas, "change", "NEWBAS")
  GW_ADD_TEXT(pg_sel_bas, "")

  GW_INJECT_HTML(pg_sel_bas, "<style>td{text-align:center;vertical-align:middle}</style>")
  GW_INJECT_HTML(pg_sel_bas, "<table><thead></thead><tbody><tr><td>")
  GW_ADD_IMAGE(pg_sel_bas, "hold.png")
  GW_INJECT_HTML(pg_sel_bas, "</td><td>")
  GW_ADD_IMAGE(pg_sel_bas, "juggle.png")
  GW_INJECT_HTML(pg_sel_bas, "</td></tr>")

  GW_INJECT_HTML(pg_sel_bas, "<tr><td>")
  chk_has_inc = GW_ADD_FLIPSWITCH(pg_sel_bas, LBL$("use_inc"), LBL$("no"), LBL$("yes")) % Do you use include files ?
  GW_INJECT_HTML(pg_sel_bas, "</td><td>")
  chk_has_res = GW_ADD_FLIPSWITCH(pg_sel_bas, LBL$("use_res"), LBL$("no"), LBL$("yes")) % Do you use resources ?
  GW_INJECT_HTML(pg_sel_bas, "</td></tr></tbody></table>")
ENDIF

%-------------------------------------------------------------------
% Select main .bas: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_sel_bas)
IF LEN(appbas$)
  ARRAY.SEARCH bas$[], appbas$, bas_idx
  IF bas_idx THEN GW_MODIFY(box_sel_bas, "selected", INT$(bas_idx))
ENDIF
IF has_inc THEN GW_MODIFY(chk_has_inc, "selected", LBL$("yes"))
IF has_res THEN GW_MODIFY(chk_has_res, "selected", LBL$("yes"))

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "GOFAST"
    gofast = 1
    fast_cp = 1
    FILE.EXISTS has_dex, apppkg$ + ".dex"
    JS("$('.se-pre-con').show()") % show loading gif
    GOTO CompileIt
  ENDIF
  IF r$ = "EXIT" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(chk_has_inc, LBL$("no"))  THEN has_inc = 0 : r$ = ""
  IF GW_FLIPSWITCH_CHANGED(chk_has_inc, LBL$("yes")) THEN has_inc = 1 : r$ = ""
  IF GW_FLIPSWITCH_CHANGED(chk_has_res, LBL$("no"))  THEN has_res = 0 : r$ = ""
  IF GW_FLIPSWITCH_CHANGED(chk_has_res, LBL$("yes")) THEN has_res = 1 : r$ = ""
  IF r$ = "NEWBAS"
    bas_idx = GW_GET_VALUE(box_sel_bas)
    IF 0 = bas_idx THEN r$ = "" : D_U.CONTINUE
    FILE.DELETE fd, apppkg$ + ".dex" % disable fast re-compile for this app now that its main .bas has changed
    % new main .bas --> reset app properties
    appbas$ = bas$[bas_idx]
    GOSUB InitProject
    bas$ = rfopath$ + "source/" + appbas$
    GOSUB GetAndFormatMainBas % content put in 'bas$'
    % does it contain an INCLUDE "GW.bas" ?
    IF IS_IN("\nINCLUDE GW.BAS", bas$) | IS_IN("\nINCLUDE " + CHR$(34) + "GW.BAS", bas$)
      ARRAY.SEARCH bas$[], "GW.bas", gw_idx : IF gw_idx THEN chk_bas[gw_idx] = 1
      IF IS_IN("\nINCLUDE GW_PICK_FILE.BAS", bas$) | IS_IN("\nINCLUDE " + CHR$(34) + "GW_PICK_FILE.BAS", bas$)
        ARRAY.SEARCH bas$[], "GW_PICK_FILE.bas", gw_idx : IF gw_idx THEN chk_bas[gw_idx] = 1
      ENDIF
      IF IS_IN("\nINCLUDE GW_GALLERY.BAS", bas$) | IS_IN("\nINCLUDE " + CHR$(34) + "GW_GALLERY.BAS", bas$)
        ARRAY.SEARCH bas$[], "GW_GALLERY.bas", gw_idx : IF gw_idx THEN chk_bas[gw_idx] = 1
      ENDIF
      has_inc = 1 : GW_MODIFY(chk_has_inc, "selected", LBL$("yes"))
      ARRAY.SEARCH res$[], "GW/", gw_idx
      IF gw_idx % GW lib >= V4.3: all resources are in a 'GW' subfolder
        chk_res[gw_idx] = 1
      ELSE
        ARRAY.SEARCH res$[], "jquery-2.1.1.min.js", gw_idx         : IF gw_idx THEN chk_res[gw_idx] = 1
        ARRAY.SEARCH res$[], "jquery.mobile-1.4.5.min.css", gw_idx : IF gw_idx THEN chk_res[gw_idx] = 1
        ARRAY.SEARCH res$[], "jquery.mobile-1.4.5.min.js", gw_idx  : IF gw_idx THEN chk_res[gw_idx] = 1
      ENDIF
      has_res = 1 : GW_MODIFY(chk_has_res, "selected", LBL$("yes"))
      GW_SHOW_DIALOG_MESSAGE(dm_sel_bas) % your app makes use of the GW lib
    ELSE
      IF IS_IN("\nINCLUDE", bas$) % does it contain any other include file(s) ?
        has_inc = 1 : GW_MODIFY(chk_has_inc, "selected", LBL$("yes"))
      ELSE
        has_inc = 0 : GW_MODIFY(chk_has_inc, "selected", LBL$("no"))
      ENDIF % else : does it use resources ?
      IF IS_IN("\nFONT.LOAD", bas$) | IS_IN("\nGR.BITMAP.LOAD", bas$) ~
       | IS_IN("\nAUDIO.LOAD", bas$) | IS_IN("\nSOUNDPOOL.LOAD", bas$) ~ % but *not* ARRAY.LOAD
       | IS_IN("\nTEXT.OPEN", bas$) | IS_IN("\nBYTE.OPEN", bas$) ~
       | IS_IN("\nZIP.OPEN", bas$) | IS_IN("\nGRABFILE", bas$)
        has_res = 1 : GW_MODIFY(chk_has_res, "selected", LBL$("yes"))
      ELSE
        has_res = 0 : GW_MODIFY(chk_has_res, "selected", LBL$("no"))
      ENDIF
    ENDIF
    r$ = ""
  ELSEIF r$ = "NEXT"
    bas_idx = GW_GET_VALUE(box_sel_bas)
    IF bas_idx = 0 THEN POPUP LBL$("need_bas") : r$ = ""
  ENDIF
UNTIL LEN(r$)

JS("$('.se-pre-con').show()") % show loading gif
IF r$ = "BACK" | r$ = "HOME" THEN GOTO Proj_Menu
IF 0 = perm_set THEN GOSUB AutosetPermissions % do it now since we know main .bas
GOSUB SaveProject

%-------------------------------------------------------------------
% Select include files (if any): create page
%-------------------------------------------------------------------
IF !has_inc THEN GOTO Sel_Res
IF !pg_sel_inc
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_sel_inc = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_sel_inc, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_sel_inc, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_sel_inc, bar$)

  GW_START_CENTER(pg_sel_inc)
  GW_ADD_IMAGE(pg_sel_inc, "hold.png")
  GW_STOP_CENTER(pg_sel_inc)

  GW_ADD_TEXT(pg_sel_inc, LBL$("sel_inc")) % Select your include file(s)

  GW_OPEN_GROUP(pg_sel_inc)
  FOR i=1 TO nbas
    IF bas$[i] <> appbas$
      GW_ADD_CHECKBOX(pg_sel_inc, "<img src='basic.gif'> " + bas$[i])
    ELSE
      GW_ADD_PLACEHOLDER(pg_sel_inc) % placeholder so there's no blank
    ENDIF
    IF i = 1 THEN first_chk_bas = GW_LAST_ID() - 1
  NEXT
  GW_CLOSE_GROUP(pg_sel_inc)
ENDIF

%-------------------------------------------------------------------
% Select include files (if any): display page and handle user input
%-------------------------------------------------------------------
Sel_Inc: % Screen #2
GW_RENDER(pg_sel_inc)
chksum$ = ""
FOR i=1 TO nbas % restore check status
  IF chk_bas[i]
    GW_MODIFY(first_chk_bas + i, "checked", "1")
    chksum$ += RIGHT$("0" + HEX$(i), 2)
  ENDIF
NEXT
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
newchksum$ = ""
FOR i=1 TO nbas % save check status
  IF bas$[i] <> appbas$ % we make this test b/c we cannot call GW_CHECKBOX_CHECKED() on the 'dummy' control
    chk_bas[i] = GW_CHECKBOX_CHECKED(first_chk_bas + i)
    IF chk_bas[i] THEN newchksum$ += RIGHT$("0" + HEX$(i), 2)
  ENDIF
NEXT
JS("$('.se-pre-con').show()") % show loading gif
IF newchksum$ <> chksum$ THEN GOSUB AutosetPermissions % new include file(s) -> scan again for permissions
GOSUB SaveProject
IF r$ = "BACK" THEN GOTO Sel_Bas
IF r$ = "HOME" THEN GOTO Proj_Menu

%-------------------------------------------------------------------
% Select resources: create page
%-------------------------------------------------------------------
Sel_Res: % Screen #3
IF !has_res THEN GOTO Ircm
IF !pg_sel_res
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_sel_res = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_sel_res, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_sel_res, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_sel_res, bar$)

  GW_START_CENTER(pg_sel_res)
  GW_ADD_IMAGE(pg_sel_res, "juggle.png")
  GW_STOP_CENTER(pg_sel_res)

  GW_ADD_TEXT(pg_sel_res, LBL$("sel_res")) % Select your resources

  GW_OPEN_GROUP(pg_sel_res)
  FOR i=1 TO nres
    GW_ADD_CHECKBOX(pg_sel_res, "<img src='" + ext_ico$(res$[i]) + "'> " + RTRIM$(res$[i], "/"))
    IF i = 1 THEN first_chk_res = GW_LAST_ID() - 1
  NEXT
  GW_CLOSE_GROUP(pg_sel_res)
ENDIF

%-------------------------------------------------------------------
% Select resources: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_sel_res)
FOR i=1 TO nres % restore check status
  IF chk_res[i] THEN GW_MODIFY(first_chk_res + i, "checked", "1")
NEXT
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
FOR i=1 TO nres % save check status
  chk_res[i] = GW_CHECKBOX_CHECKED(first_chk_res + i)
NEXT
JS("$('.se-pre-con').show()") % show loading gif
GOSUB SaveProject
IF r$ = "BACK"
  IF has_inc THEN GOTO Sel_Inc ELSE GOTO Sel_Bas
ENDIF
IF r$ = "HOME" THEN GOTO Proj_Menu

%-------------------------------------------------------------------
% Include/resource case mismatch: create page
%-------------------------------------------------------------------
Ircm: % Screen #4
IF !has_res & !has_inc THEN GOTO Fast_Cp
FILE.EXISTS ircm_dbg, "../full_debug.on" % Resource Case-Mismatch Debug
IF ircm_dbg THEN FILE.DELETE fd, "../Compiler.log"
LIST.CLEAR mm_fina % reset mismatching filenames
LIST.CLEAR mm_desc % reset mismatching description (bas+line where it occurs)
bas$ = rfopath$ + "source/" + appbas$ % analyze content of main bas
GOSUB DetectIncResCaseMismatch % mismatching incs/res are added to 'mm_fina' & 'mm_desc' lists
FOR i=1 TO nbas % analyze content of all include files if any
  IF chk_bas[i] THEN
    bas$ = rfopath$ + "source/" + bas$[i]
    GOSUB DetectIncResCaseMismatch
  ENDIF
NEXT
LIST.SIZE mm_fina, ircm % ircm = include/resource case mismatch
IF 0=ircm THEN GOTO Fast_Cp % all inc/res case match -> proceed
IF !pg_ircm
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_ircm = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_ircm, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_ircm, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("cancel") + ">BACK") + GW_ADD_BAR_TITLE$("")
  GW_ADD_FOOTBAR(pg_ircm, bar$)

  GW_START_CENTER(pg_ircm)
  GW_ADD_IMAGE(pg_ircm, "ko.png")
  GW_STOP_CENTER(pg_ircm)
  
  GW_USE_THEME_CUSTO_ONCE("style='color:red'")
  e$  = "<b>We detected errors (case mismatch) in how your program references one or more include / resource files*. "
  e$ += "This will prevent your APK from running correctly.</b>"
  GW_ADD_TEXT(pg_ircm, e$)
  e$  = "<small>* APKs are case <u>sensitive</u> meaning includes / resources need to be referenced with their exact file-name, "
  e$ += "unlike the RFO BASIC! Editor which is case <u>in</u>sensitive because it runs directly on <b>sdcard/</b></small>"
  GW_ADD_TEXT(pg_ircm, e$)
  
  ircm_ph = GW_ADD_PLACEHOLDER(pg_ircm)

  GW_USE_THEME_CUSTO_ONCE("style='color:darkblue'")
  e$  = "<b>The Compiler can try to modify your program so that it calls the correct includes / resources, "
  e$ += "however it is a beta feature and we do not guarantee to solve all problems...</b>"
  GW_ADD_TEXT(pg_ircm, e$)

  GW_USE_THEME_CUSTO_ONCE("icon=check style='background:darkblue;color:white;text-shadow:none'")
  GW_ADD_BUTTON(pg_ircm, "Try automatic changes by Compiler", "AUTO")
  
  GW_USE_THEME_CUSTO_ONCE("style='color:teal'")
  e$  = "<b>Or if you prefer, we can create a text file in the rfo-compiler/ folder listing all problems, "
  e$ += "you can refer to it to modify your program manually and run again the Compiler when everything is fixed:</b>"
  GW_ADD_TEXT(pg_ircm, e$)

  GW_USE_THEME_CUSTO_ONCE("icon=check style='background:teal;color:white;text-shadow:none'")
  GW_ADD_BUTTON(pg_ircm, "Dump .txt and do manual changes", "MANUAL")

  GW_USE_THEME_CUSTO_ONCE("style='color:red'")
  e$  = "<b>Or finally you can ignore these errors and go on with the compilation at your own risk:</b>"
  GW_ADD_TEXT(pg_ircm, e$)

  GW_USE_THEME_CUSTO_ONCE("icon=check style='background:red;color:white;text-shadow:none'")
  GW_ADD_BUTTON(pg_ircm, "Ignore and compile anyway", "IGNORE")
ENDIF

%-------------------------------------------------------------------
% Resource case mismatch: display page and handle user input
%-------------------------------------------------------------------
GOSUB RefreshIncResMismatchInfo % update 'html$' and 'ircm$'
GW_FILL_PLACEHOLDER(pg_ircm, ircm_ph, html$)
GW_RENDER(pg_ircm)
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
JS("$('.se-pre-con').show()") % show loading gif
IF r$ = "AUTO" % automatic fix
  GOSUB FixIncResCaseMismatch
  POPUP CHR$(34) + appbas$ + CHR$(34) + " successfully modified"
  PAUSE 2000
ENDIF
LIST.CLEAR mm_fina : LIST.CLEAR mm_desc % clean-up
IF r$ = "HOME"
  GOTO Proj_Menu
ELSEIF r$ = "BACK"
  IF has_res
    GOTO Sel_Res
  ELSEIF has_inc
    GOTO Sel_Inc
  ELSE
    GOTO Sel_Bas
  ENDIF
ELSEIF r$ = "MANUAL"
  PutFile(ircm$, "../" + appnam$ + "_errors.txt")
  POPUP CHR$(34) + "rfo-compiler/" + appnam$ + "_errors.txt" + CHR$(34) + " created"
  PAUSE 2000
  GOTO Proj_Menu
ENDIF % ELSE r$ = "IGNORE" --> proceed with compilation

%-------------------------------------------------------------------
% Fast re-compile: create page
%-------------------------------------------------------------------
Fast_Cp: % Screen #5
FILE.EXISTS has_dex, apppkg$ + ".dex"
IF 0 = fast_cp | 0 = has_dex THEN GOTO Def_Nam
IF !pg_fast_cp
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_fast_cp = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_fast_cp, "thinking.gif", drk_thm)
  GW_ADD_TITLEBAR(pg_fast_cp, tibar2$)

  html$  = "<table><thead></thead><tbody>"
  html$ += "<tr onclick=javascript:RFO('FAST')><td>"
  GW_INJECT_HTML(pg_fast_cp, html$)
  GW_ADD_IMAGE(pg_fast_cp, "bunnoid.png")
  GW_INJECT_HTML(pg_fast_cp, "</td><td>")
  GW_ADD_TEXT(pg_fast_cp, LBL$("fast"))

  GW_INJECT_HTML(pg_fast_cp, "</td></tr><tr><td colspan='2'>")
  GW_START_CENTER(pg_fast_cp)
  tx_fast_cp = GW_ADD_TEXT(pg_fast_cp, "")
  GW_STOP_CENTER(pg_fast_cp)

  html$  = "</td></tr><tr onclick=javascript:RFO('SLOW')><td>"
  GW_INJECT_HTML(pg_fast_cp, html$)
  GW_ADD_IMAGE(pg_fast_cp, "tortoid.png")
  GW_INJECT_HTML(pg_fast_cp, "</td><td>")
  GW_ADD_TEXT(pg_fast_cp, LBL$("slow"))
  GW_INJECT_HTML(pg_fast_cp, "</td></tr></tbody></table>")
ENDIF

%-------------------------------------------------------------------
% Fast re-compile: display page and handle user input
%-------------------------------------------------------------------
GOSUB CreateProjDesc
GW_RENDER(pg_fast_cp)
GW_MODIFY(tx_fast_cp, "text", projdesc$)
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
JS("$('.se-pre-con').show()") % show loading gif
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ = "BACK"
  IF has_res
    GOTO Sel_Res
  ELSEIF has_inc
    GOTO Sel_Inc
  ELSE
    GOTO Sel_Bas
  ENDIF
ENDIF
IF r$ = "FAST" THEN GOTO CompileIt
IF r$ = "SLOW" THEN FILE.DELETE fd, apppkg$ + ".dex" : has_dex = 0

%-------------------------------------------------------------------
% Define app name, version, and icon: create page
%-------------------------------------------------------------------
Def_Nam: % Screen #6
IF !pg_app_nam
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_app_nam = GW_NEW_PAGE()
  GW_INSERT_BEFORE(pg_app_nam, "</head", "<script src='diacritics.js'></script>")
  GW_ADD_LOADING_IMG(pg_app_nam, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_app_nam, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_app_nam, bar$)

  ARRAY.LOAD ovwccl$[], UPPER$(LBL$("overwrite")) + ">OVW", LBL$("cancel") + ">NOVW"
  e$  = LBL$("app_exist") + "\n" + LBL$("overwrite") + " ?" % This app already exists. Overwrite ?
  GW_USE_THEME_CUSTO_ONCE("inline")
  dm_app_nam = GW_ADD_DIALOG_MESSAGE (pg_app_nam, UPPER$(LBL$("conflict")), e$, ovwccl$[])

  GW_ADD_TEXT(pg_app_nam, LBL$("app_ico")) % App icon:
  GW_INJECT_HTML(pg_app_nam, "<style>td{text-align:center;vertical-align:middle}</style>")
  GW_INJECT_HTML(pg_app_nam, "<table><thead></thead><tbody><tr><td>")
  GW_USE_THEME_CUSTO_ONCE("inline mini")
  GW_ADD_BUTTON(pg_app_nam, LBL$("def_ico"), "STDICO") % Default icon
  GW_INJECT_HTML(pg_app_nam, "</td><td><a onclick=javascript:RFO('NEWICO')>")
  ico = GW_ADD_IMAGE(pg_app_nam, appico$)
  GW_INJECT_HTML(pg_app_nam, "</a></td><td style='width:10px'></td><td><small id='quali'>")
  GW_INJECT_HTML(pg_app_nam, "</small></td></tr></tbody></table>")
  GW_INJECT_HTML(pg_app_nam, "<style>#" + GW_ID$(ico) + "{border:1px solid black;width:64px}</style>")
  GW_INJECT_HTML(pg_app_nam, "<hr style='border-top:1px solid rgba(130,130,130,.3)'>")

  GW_INJECT_HTML(pg_app_nam, "<div>")
  sb_app_fla = GW_ADD_SELECTBOX(pg_app_nam, LBL$("super"), flav$[]) % Flavors
  GW_INJECT_HTML(pg_app_nam, "</div>")

  in_app_nam = GW_ADD_INPUTLINE(pg_app_nam, LBL$("app_nam"), appnam$)   % App name:
  in_app_ver = GW_ADD_INPUTNUMBER(pg_app_nam, LBL$("app_ver"), appver$) % App version:

  chk_go_adv = GW_ADD_FLIPSWITCH(pg_app_nam, LBL$("show_adv"), LBL$("no"), LBL$("yes")) % Use advanced options?

ENDIF

%-------------------------------------------------------------------
% Define app name, version, and icon: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_app_nam)
IF spr_usr
  ARRAY.SEARCH flav$[], appfla$, k
  IF k=0 THEN k=1 % standard RFO-BASIC by default
  GW_MODIFY(sb_app_fla, "selected", INT$(k))
ELSE
  GW_HIDE(sb_app_fla)
  GW_MODIFY(sb_app_fla, "selected", "1")
ENDIF
GW_MODIFY(in_app_nam, "input", appnam$)
GW_MODIFY(in_app_ver, "input", appver$)
GOSUB RefreshAppIco
IF go_adv THEN GW_MODIFY(chk_go_adv, "selected", LBL$("yes"))

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(chk_go_adv, LBL$("no"))  THEN go_adv = 0 : r$ = ""
  IF GW_FLIPSWITCH_CHANGED(chk_go_adv, LBL$("yes")) THEN go_adv = 1 : r$ = ""
  IF r$ = "STDICO" % standard icon
    appico$ = "hold.png"
    GOSUB RefreshAppIco
    POPUP LBL$("def_ico_set") % Default icon set
    r$ = ""
  ELSEIF r$ = "NEXT"
    tmp_appnam$ = TRIM$(GW_GET_VALUE$(in_app_nam))
    tmp_appver$ = TRIM$(GW_GET_VALUE$(in_app_ver))
    IF 0 = CheckValidAppName(tmp_appnam$)
      POPUP LBL$("bad_app_nam") % Illegal app name
      GW_FOCUS(in_app_nam)
      r$ = ""
      D_U.CONTINUE
    ELSEIF tmp_appver$ = ""
      POPUP LBL$("bad_app_ver") % Incorrect version number
      GW_FOCUS(in_app_ver)
      r$ = ""
    ENDIF
    IF tmp_appnam$ <> appnam$ % user changed app name
      FILE.EXISTS fid, comppath$ + tmp_appnam$ + ".rfo"
      IF fid
        GW_SHOW_DIALOG_MESSAGE(dm_app_nam) % this app already exists. overwrite?
        r$ = ""
      ENDIF
    ENDIF
  ELSEIF r$ = "OVW" % overwrite existing project
    FILE.DELETE fid, comppath$ + tmp_appnam$ + ".rfo"
    r$ = "NEXT"
  ELSEIF r$ = "NOVW" % do not overwrite existing project
    POPUP LBL$("ren_app") % Please rename app
    GW_FOCUS(in_app_nam)
    r$ = ""
  ENDIF
UNTIL LEN(r$)

IF tmp_appnam$ <> appnam$ & LEN(tmp_appnam$) % null string can happen if user taps "Back" or "Home"
  FILE.EXISTS fid, comppath$ + appnam$ + ".rfo"
  IF fid THEN FILE.RENAME comppath$ + appnam$ + ".rfo", comppath$ + tmp_appnam$ + ".rfo"
  appnam$ = tmp_appnam$
  GOSUB SetAppFieldsRelyingOnAppName
ENDIF
IF tmp_appver$ <> appver$ & LEN(tmp_appver$) % null string can happen if user taps "Back" or "Home"
  appver$ = tmp_appver$
  GOSUB SetAppFieldsRelyingOnAppVersion
ENDIF
appfla$ = flav$[GW_GET_VALUE(sb_app_fla)]
GOSUB SaveProject

IF r$ = "BACK"
  IF has_res
    GOTO Sel_Res
  ELSEIF has_inc
    GOTO Sel_Inc
  ELSE
    GOTO Sel_Bas
  ENDIF
ENDIF
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ = "NEXT" THEN GOTO Adv_Opt % ELSE IF r$ = "NEWICO" continue below to Pick_Ico

%-------------------------------------------------------------------
% Pick app icon: display page and handle user input
%-------------------------------------------------------------------
Pick_Ico: % Screen #7
GW_RENDER(pg_app_ico)
e$  = LBL$("pick_ico") + " <small><i>("  % Pick your app icon:
e$ += LBL$("tap_info") + ")</i></small>" % long-press for information
GW_MODIFY(tx_ico, "text", e$) 
DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF LEFT$(r$, 1) = "I" & IS_NUMBER(MID$(r$, 2)) THEN % img info
    LIST.GET images, VAL(MID$(r$, 2)), img$
    POPUP FileName$(img$) + "\n" + GW_GET_IMAGE_DIM$(img$)
    r$ = ""
  ELSEIF IS_NUMBER(r$) % img picked
    LIST.GET images, VAL(r$), img$
    appico$ = img$
  ENDIF
UNTIL LEN(r$)
IF r$ = "HOME" THEN GOTO Proj_Menu
GOTO Def_Nam

%-------------------------------------------------------------------
% Advanced options: create page
%-------------------------------------------------------------------
Adv_Opt: % Screen #8
IF !go_adv THEN GOTO Sum_Up
IF !pg_adv_opt
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_adv_opt = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_adv_opt, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_adv_opt, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_adv_opt, bar$)

  GW_START_CENTER(pg_adv_opt)
  GW_ADD_IMAGE(pg_adv_opt, "opt.png")
  GW_STOP_CENTER(pg_adv_opt)

  GW_INJECT_HTML(pg_adv_opt, "<style>td{vertical-align:middle}</style>")
  GW_INJECT_HTML(pg_adv_opt, "<table><thead></thead><tbody><tr><td style='padding-top:16px;margin:0'>")
  in_adv_dir = GW_ADD_INPUTLINE(pg_adv_opt, LBL$("app_dir"), appdir$) % App folder
  GW_INJECT_HTML(pg_adv_opt, "</td><td style='margin:0'>")
  in_adv_cod = GW_ADD_INPUTNUMBER(pg_adv_opt, LBL$("app_cod"), appcod$) % Version code
  GW_INJECT_HTML(pg_adv_opt, "</td></tr></tbody></table>")
  GW_INJECT_HTML(pg_adv_opt, "<style>div[data-role='fieldcontain']{padding:0;margin:0}</style>")

  ARRAY.LENGTH nicos, perm_ico$[]

  IF vis_imp % use a check-list of permissions for the visually-impaired
    ARRAY.SUM nchk_perm, chk_perm[]
    e$ = RTRIM$(INT$(nchk_perm) + " " + Plural$(LBL$("perm_list"), nchk_perm), ":") % N permission(s)
    GW_INJECT_HTML(pg_adv_opt, "<style>td{vertical-align:middle}</style>")
    GW_INJECT_HTML(pg_adv_opt, "<table><thead></thead><tbody><tr><td style='padding-top:16px;margin:0'>")
    tx_adv_perm = GW_ADD_TEXT(pg_adv_opt, "<span>" + e$ + "</span>")
    GW_INJECT_HTML(pg_adv_opt, "</td><td style='margin:0'>")
    GW_ADD_BUTTON(pg_adv_opt, "Change permissions", "CHPERM")
    GW_INJECT_HTML(pg_adv_opt, "</td></tr></tbody></table>")

    % Create dedicated permissions page
    IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
    pg_perm = GW_NEW_PAGE()
    GW_ADD_LOADING_IMG(pg_perm, "thinking.gif", drk_thm)
    GW_ADD_TITLEBAR(pg_perm, tibar2$)
    bar$ = GW_ADD_BAR_LBUTTON$(LBL$("cancel") + ">BACK") + GW_ADD_BAR_TITLE$("")
    GW_ADD_FOOTBAR(pg_perm, bar$)
    GW_ADD_TEXT(pg_perm, "Choose your permissions:")
    GW_OPEN_GROUP(pg_perm)
    FOR i=1 TO nicos
      e$ = MID$(perm_ico$[i], 5) % "permN.M.O.png" -> "N.M.O.png"
      perm = VAL(LEFT$(e$, IS_IN(".", e$)-1)) % N (first permission #)
      perm$ = REPLACE$(LOWER$(MID$(permissions$[perm], 4)), "_", " ") % "access coarse location"
      perm$ = UPPER$(LEFT$(perm$, 1)) + MID$(perm$, 2)
      IF perm$ = "Access coarse location" THEN perm$ = "Access location"
      j = TALLY(perm_ico$[i], ".")
      IF j > 1 THEN perm$ += " (+" + INT$(j-1) + " others)"     % "Access location (+3 others)"
      perm_chk$ = "<img src='" + perm_ico$[i] + "' width='16' height='16' style='filter:invert("
      IF drk_thm THEN perm_chk$ += "100%" ELSE perm_chk$ += "0%"
      perm_chk$ += ")'> " + perm$
      GW_ADD_CHECKBOX(pg_perm, perm_chk$)
      IF i = 1 THEN first_chk_perm = GW_LAST_ID() - 1
    NEXT
    GW_CLOSE_GROUP(pg_perm)
    GW_USE_THEME_CUSTO_ONCE("icon=check style='background:green;color:white;text-shadow:none'")
    GW_ADD_BUTTON(pg_perm, UPPER$(LBL$("validate")), "VALID") % VALIDATE CHANGES

  ELSE   % normal permission logos
    e$  = "<span>" + LBL$("perm") + " <i><small>("      % Permissions:
    e$ += LBL$("tap_info") + ")</small></i></span><br>" % long-press for information
    GW_INJECT_HTML(pg_adv_opt, e$)
    css$  = "<style>.perm{width:32px;height:32px;padding:10px;opacity:0.2;filter:invert("
    IF drk_thm THEN css$ += "100%" ELSE css$ += "0%"
    css$ += ")} .active{opacity:1 !important}</style>"
    GW_INJECT_HTML(pg_adv_opt, css$)
    FOR i=1 TO nicos
      e$ = MID$(perm_ico$[i], 5) % "permN.M.O.png" -> "N.M.O.png"
      perm = VAL(LEFT$(e$, IS_IN(".", e$)-1)) % N (first permission #)
      IF chk_perm[perm] THEN class$ = " active" ELSE class$ = ""
      ax$ = UPPER$(REPLACE$(REPLACE$(perm_ico$[i], ".png", ""), ".", "-"))
      html$  = "<a onclick=javascript:RFO('" + ax$ + "')>"
      html$ += "<img id='" + ax$ + "' class='perm" + class$ + "' "
      html$ += " src='" + perm_ico$[i] + "'></a><script>$('#" + ax$ + "')"
      html$ += ".on('taphold',function(){RFO('I" + ax$ + "');})</script>"
      GW_INJECT_HTML(pg_adv_opt, html$)
    NEXT
  ENDIF % visually impaired/normal permissions

  GW_OPEN_GROUP(pg_adv_opt)
  chk_adv_sta = GW_ADD_CHECKBOX(pg_adv_opt, LBL$("start_boot"))        % Auto-start app when device boots
  chk_adv_dat = GW_ADD_CHECKBOX(pg_adv_opt, ">" + LBL$("create_data")) % Create sdcard/app_name/data
  chk_adv_db = GW_ADD_CHECKBOX(pg_adv_opt, ">" + LBL$("create_db"))    % Create sdcard/app_name/databases
  GW_CLOSE_GROUP(pg_adv_opt)

  chk_sup_adv = GW_ADD_FLIPSWITCH(pg_adv_opt, LBL$("show_sup_adv"), LBL$("no"), LBL$("yes")) % Show super adv. options
  
ENDIF

%-------------------------------------------------------------------
% Advanced options: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_adv_opt)
IF vis_imp % dedicated permissions screen for the visually impaired
  ARRAY.SUM nchk_perm, chk_perm[]
  e$ = RTRIM$(INT$(nchk_perm) + " " + Plural$(LBL$("perm_list"), nchk_perm), ":") % N permission(s)
  GW_MODIFY(tx_adv_perm, "text", "<span>" + e$ + "</span>")
ELSE   % normal permissions mode (permission logos)
  FOR i=1 TO nicos
    e$ = MID$(perm_ico$[i], 5) % "permN.M.O.png" -> "N.M.O.png"
    perm = VAL(LEFT$(e$, IS_IN(".", e$)-1)) % N (first permission #)
    ax$ = UPPER$(REPLACE$(REPLACE$(perm_ico$[i], ".png", ""), ".", "-")) % "PERMN-M-O"
    IF chk_perm[perm] THEN class$ = "add" ELSE class$ = "remove"
    JS("$('#" + ax$ + "')." + class$ + "Class('active')")
  NEXT
ENDIF
GW_MODIFY(chk_adv_sta, "checked", INT$(adv_sta))
GW_MODIFY(chk_adv_dat, "checked", INT$(adv_dat))
GW_MODIFY(chk_adv_db, "checked", INT$(adv_db))
GW_MODIFY(in_adv_dir, "input", appdir$)
GW_MODIFY(in_adv_cod, "input", appcod$)
IF sup_adv THEN GW_MODIFY(chk_sup_adv, "selected", LBL$("yes"))

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(chk_sup_adv, LBL$("no"))  THEN sup_adv = 0 : r$ = ""
  IF GW_FLIPSWITCH_CHANGED(chk_sup_adv, LBL$("yes")) THEN sup_adv = 1 : r$ = ""
  IF IS_IN("IPERM", r$) = 1 % info on permission
    r$ = MID$(r$, 6)
    e$ = ""
    FOR i=1 TO PARSECOUNT(r$, "-")
      k = VAL(PARSE$(r$, "-", i))
      e$ += MID$(REPLACE$(LOWER$(permissions$[k]), "_", " "), 4) + "\n"
    NEXT
    POPUP LEFT$(e$, -1)
    r$ = ""
  ELSEIF IS_IN("PERM", r$) = 1 % tap on permission
    perm_set = 0
    r$ = MID$(r$, 5)
    FOR i=1 TO PARSECOUNT(r$, "-")
      k = VAL(PARSE$(r$, "-", i))
      chk_perm[k] = 1 - chk_perm[k]
    NEXT
    IF chk_perm[k] THEN class$ = "add" ELSE class$ = "remove"
    JS("$('#PERM" + r$ + "')." + class$ + "Class('active')")
    r$ = ""
  ELSEIF r$ = "NEXT"
    IF IS_IN("/", TRIM$(GW_GET_VALUE$(in_adv_dir)))
      GW_FOCUS(in_adv_dir)
      POPUP LBL$("bad_app_dir") % Not a valid folder name
      r$ = ""
    ELSEIF 0 = CheckValidVerCode(TRIM$(GW_GET_VALUE$(in_adv_cod)))
      GW_FOCUS(in_adv_cod)
      POPUP LBL$("bad_app_cod") % Not a valid version code\n(must be an integer)
      r$ = ""
    ENDIF
  ENDIF
UNTIL LEN(r$)

adv_sta = GW_CHECKBOX_CHECKED(chk_adv_sta)
adv_dat = GW_CHECKBOX_CHECKED(chk_adv_dat) : IF adv_dat & chk_perm[1] = 0 THEN chk_perm[1] = 1
adv_db = GW_CHECKBOX_CHECKED(chk_adv_db)   : IF adv_db  & chk_perm[1] = 0 THEN chk_perm[1] = 1
appdir$ = TRIM$(GW_GET_VALUE$(in_adv_dir))
appcod$ = TRIM$(GW_GET_VALUE$(in_adv_cod))
IF perm_set = 0 THEN perm_set = 1 : GOSUB SetPermIcoStr
GOSUB SaveProject

IF r$ = "BACK" THEN GOTO Def_Nam
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ = "CHPERM" THEN GOTO Ch_Perm

%-------------------------------------------------------------------
% Super advanced options: create page
%-------------------------------------------------------------------
IF !sup_adv THEN GOTO Sum_Up
IF !pg_sup_adv
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_sup_adv = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_sup_adv, "thinking.gif", drk_thm)
  GW_ADD_TITLEBAR(pg_sup_adv, tibar2$)

  ARRAY.LOAD advreg$[], "OK>REG", LBL$("cancel")
  GW_USE_THEME_CUSTO_ONCE("inline")
  di_adv_reg = GW_ADD_DIALOG_INPUT(pg_sup_adv, UPPER$(LBL$("reg")), LBL$("reg_dlg"), "", advreg$[]) % Register extensions

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("") + GW_ADD_BAR_RBUTTON$(LBL$("next") + ">NEXT")
  GW_ADD_FOOTBAR(pg_sup_adv, bar$)

  GW_START_CENTER(pg_sup_adv)
  GW_ADD_IMAGE(pg_sup_adv, "opt2.png")
  GW_STOP_CENTER(pg_sup_adv)

  in_adv_pkg = GW_ADD_INPUTLINE(pg_sup_adv, LBL$("pkg_nam"), apppkg$) % Package name

  GW_USE_THEME_CUSTO_ONCE("icon=comment")
  GW_ADD_BUTTON(pg_sup_adv, LBL$("splash"), "SPLASH") % Splash screen / Loading
  GW_USE_THEME_CUSTO_ONCE("icon=bars")
  GW_ADD_BUTTON(pg_sup_adv, LBL$("con"), "CON") % Console look and feel
  GW_USE_THEME_CUSTO_ONCE("icon=heart")
  GW_ADD_BUTTON(pg_sup_adv, LBL$("reg"), GW_SHOW_DIALOG_INPUT$(di_adv_reg)) % Register extension(s)
  GW_INJECT_HTML(pg_sup_adv, "<hr style='border-top:1px solid rgba(130,130,130,.3);margin-top:15px;margin-bottom:15px'>")

  GW_OPEN_GROUP(pg_sup_adv)
  chk_adv_acc = GW_ADD_CHECKBOX(pg_sup_adv, ">" + LBL$("hw_accel")) % Activate hardware acceleration
  chk_adv_mem = GW_ADD_CHECKBOX(pg_sup_adv, LBL$("mem")) % Use large Heap memory (64 MB)
  chk_adv_enc = GW_ADD_CHECKBOX(pg_sup_adv, LBL$("encrypt")) % Protect (encrypt) .bas files
  chk_adv_cpy = GW_ADD_CHECKBOX(pg_sup_adv, LBL$("copy")) % Copy resources to sdcard
  GW_CLOSE_GROUP(pg_sup_adv)
ENDIF

%-------------------------------------------------------------------
% Super advanced options: display page and handle user input
%-------------------------------------------------------------------
Sup_Adv: % Screen #9
GW_RENDER(pg_sup_adv)
GW_MODIFY(di_adv_reg, "input", adv_reg$)
GW_MODIFY(in_adv_pkg, "input", apppkg$)
GW_MODIFY(chk_adv_acc, "checked", INT$(adv_acc))
GW_MODIFY(chk_adv_mem, "checked", INT$(adv_mem))
GW_MODIFY(chk_adv_enc, "checked", INT$(adv_enc))
GW_MODIFY(chk_adv_cpy, "checked", INT$(adv_cpy))

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF r$ = "REG"
    ext$ = TRIM$(GW_GET_VALUE$(di_adv_reg))
    IF CheckValidExtensions(ext$)
      adv_reg$ = ext$
    ELSE
      POPUP LBL$("bad_reg") % Invalid extensions, please try again
      GW_MODIFY(di_adv_reg, "input", adv_reg$)
    ENDIF
    r$ = ""
  ELSEIF r$ = "NEXT"
    IF 0 = CheckValidPackage(TRIM$(GW_GET_VALUE$(in_adv_pkg)))
      GW_FOCUS(in_adv_pkg)
      POPUP LBL$("bad_pkg_nam") % Not a valid package name
      r$ = ""
    ENDIF
  ENDIF
UNTIL LEN(r$)

apppkg$ = TRIM$(GW_GET_VALUE$(in_adv_pkg))
adv_acc = GW_CHECKBOX_CHECKED(chk_adv_acc)
adv_mem = GW_CHECKBOX_CHECKED(chk_adv_mem)
adv_enc = GW_CHECKBOX_CHECKED(chk_adv_enc)
adv_cpy = GW_CHECKBOX_CHECKED(chk_adv_cpy)
GOSUB SaveProject

IF r$ = "BACK" THEN GOTO Adv_Opt
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ = "SPLASH" THEN GOTO Splash_Scr
IF r$ = "CON" THEN GOTO Console_Scr
IF r$ = "NEXT" THEN GOTO Sum_Up

%-------------------------------------------------------------------
% Splash screen: create page
%-------------------------------------------------------------------
Splash_Scr:
IF !pg_splash
  tmp_splash_time$ = TRIM$(STR$(splash_time))
  tmp_splash_bgd$ = splash_bgd$
  tmp_splash_img = splash_img
  tmp_splash_img$ = splash_img$

  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_splash = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_splash, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_splash, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("cancel") + ">BACK") + GW_ADD_BAR_TITLE$("")
  GW_ADD_FOOTBAR(pg_splash, bar$)

  e$  = LBL$("splash_time_1") + " <small><i>"         % Splash screen time in second
  e$ += "(" + LBL$("splash_time_2") + ")</i></small>" % set to 0 for no splash screen
  in_splash = GW_ADD_INPUTNUMBER(pg_splash, e$, tmp_splash_time$)

  col_splash = GW_ADD_COLORPICKER(pg_splash, LBL$("bgd_col"), splash_bgd$) % Background color

  GW_INJECT_HTML(pg_splash, "<style>td{text-align:center;vertical-align:middle}</style>")
  GW_INJECT_HTML(pg_splash, "<table><thead></thead><tbody><tr><td>")
  chk_splash = GW_ADD_FLIPSWITCH(pg_splash, Plural$(LBL$("img"), 0), LBL$("no"), LBL$("yes")) % Image
  GW_INJECT_HTML(pg_splash, "</td><td style='width:20px'></td><td><a onclick=javascript:RFO('NEWIMG')>")
  splash = GW_ADD_IMAGE(pg_splash, splash_img$)
  GW_INJECT_HTML(pg_splash, "</a></td><td style='width:10px'></td><td>")
  GW_USE_THEME_CUSTO_ONCE("inline mini")
  btn_splash = GW_ADD_BUTTON(pg_splash, LBL$("default"), "STDIMG") % Default
  GW_INJECT_HTML(pg_splash, "</td></tr></tbody></table>")
  GW_INJECT_HTML(pg_splash, "<style>#" + GW_ID$(splash) + "{border:1px solid black;")
  GW_INJECT_HTML(pg_splash, "width:100px;min-height:150px;padding:10px}</style>")
  GW_INJECT_HTML(pg_splash, "<hr style='border-top:1px solid rgba(130,130,130,.3)'>")

  GW_USE_THEME_CUSTO_ONCE("icon=check style='background:green;color:white;text-shadow:none'")
  GW_ADD_BUTTON(pg_splash, UPPER$(LBL$("validate")), "VALID") % VALIDATE CHANGES
ENDIF

%-------------------------------------------------------------------
% Splash screen: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_splash)
GW_MODIFY(in_splash, "input", tmp_splash_time$)
GW_MODIFY(col_splash, "input", tmp_splash_bgd$)
GW_MODIFY(splash, "style:background", tmp_splash_bgd$)
IF tmp_splash_img THEN e$ = LBL$("yes") ELSE e$ = LBL$("no")
GW_MODIFY(chk_splash, "selected", e$)
IF tmp_splash_img THEN e$ = tmp_splash_img$ ELSE e$ = "blank.png"
GW_MODIFY(splash, "src", e$)
IF 0 = tmp_splash_img THEN GW_DISABLE(btn_splash)

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(chk_splash, LBL$("no"))
    tmp_splash_img = 0
    GW_MODIFY(splash, "src", "blank.png")
    GW_DISABLE(btn_splash)
    r$ = ""
  ELSEIF GW_FLIPSWITCH_CHANGED(chk_splash, LBL$("yes"))
    tmp_splash_img = 1
    GW_MODIFY(splash, "src", tmp_splash_img$)
    GW_ENABLE(btn_splash)
    r$ = ""
  ELSEIF r$ = "STDIMG"
    tmp_splash_img = 1
    tmp_splash_img$ = "splash.png"
    GW_MODIFY(splash, "src", tmp_splash_img$)
    r$ = ""
  ELSEIF IS_IN (GW_ID$(col_splash), r$) = 1 THEN % color picker change
    tmp_splash_bgd$ = MID$ (r$, IS_IN(":", r$)+1) % extract '#rrggbb' out of 'CtlId:#rrggbb'
    GW_MODIFY(splash, "style:background", tmp_splash_bgd$)
    r$ = ""
  ELSEIF r$ = "VALID"
    tmp_splash_time$ = GW_GET_VALUE$(in_splash)
    tmp_splash_time$ = REPLACE$(tmp_splash_time$, ",", ".")
    IF !IS_NUMBER(tmp_splash_time$)
      GW_FOCUS(in_splash)
      POPUP LBL$("bad_time") % Not a valid time
      r$ = ""
    ENDIF
  ENDIF
UNTIL LEN(r$)

IF r$ = "VALID" % save temp options as real ones
  splash_time = VAL(tmp_splash_time$)
  splash_bgd$ = tmp_splash_bgd$
  splash_img = tmp_splash_img
  splash_img$ = tmp_splash_img$
ELSEIF r$ = "BACK" | r$ = "HOME" % re-init temp options if user cancels then comes back
  tmp_splash_time$ = TRIM$(STR$(splash_time))
  tmp_splash_bgd$ = splash_bgd$
  tmp_splash_img = splash_img
  tmp_splash_img$ = splash_img$
ENDIF
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ <> "NEWIMG" THEN GOTO Sup_Adv
tmp_splash_time$ = GW_GET_VALUE$(in_splash)

%-------------------------------------------------------------------
% Pick splash screen image: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_app_ico)
e$  = LBL$("pick_splash") + " <small><i>(" % Pick splash screen:
e$ += LBL$("tap_info") + ")</i></small>"   % long-press for information
GW_MODIFY(tx_ico, "text", e$)
DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF LEFT$(r$, 1) = "I" & IS_NUMBER(MID$(r$, 2)) THEN % img info
    LIST.GET images, VAL(MID$(r$, 2)), img$
    POPUP FileName$(img$) + "\n" + GW_GET_IMAGE_DIM$(img$)
    r$ = ""
  ELSEIF IS_NUMBER(r$) % img picked
    LIST.GET images, VAL(r$), img$
    tmp_splash_img$ = img$
  ENDIF
UNTIL LEN(r$)
IF r$ = "HOME" THEN GOTO Proj_Menu
GOTO Splash_Scr

%-------------------------------------------------------------------
% Change Permissions (check-list): display page and handle user input
%-------------------------------------------------------------------
Ch_Perm:
GW_RENDER(pg_perm)
FOR i=1 TO nicos % restore check status
  e$ = MID$(perm_ico$[i], 5) % "permN.M.O.png" -> "N.M.O.png"
  perm = VAL(LEFT$(e$, IS_IN(".", e$)-1)) % N (first permission #)
  IF chk_perm[perm] THEN GW_MODIFY(first_chk_perm + i, "checked", "1")
NEXT
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
IF r$ = "BACK" THEN GOTO Adv_Opt % "Cancel"
perm_set = 0     % will force call to SetPermIcoStr
FOR i=1 TO nicos % save check status
  checked = GW_CHECKBOX_CHECKED(first_chk_perm + i)
  perms$ = REPLACE$(REPLACE$(MID$(perm_ico$[i],5), ".png", ""), ".", "-") % "N-M-O"
  FOR j=1 TO PARSECOUNT(perms$, "-")
    k = VAL(PARSE$(perms$, "-", j))
    chk_perm[k] = checked
  NEXT
NEXT
JS("$('.se-pre-con').show()") % show loading gif
GOSUB SaveProject
IF r$ = "HOME" THEN GOTO Proj_Menu
GOTO Adv_Opt % r$ = "VALID"

%-------------------------------------------------------------------
% Console customization: create page
%-------------------------------------------------------------------
Console_Scr:
IF !pg_con
  tmp_con_uselin = con_uselin
  tmp_con_usemenu = con_usemenu
  tmp_con_fntcol$ = con_fntcol$
  tmp_con_bgdcol$ = con_bgdcol$
  tmp_con_lincol$ = con_lincol$
  tmp_con_empty = con_empty
  tmp_con_fntsiz = con_fntsiz
  tmp_con_fnttyp = con_fnttyp
  tmp_con_scrdir = con_scrdir

  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_con = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_con, "thinking.gif", drk_thm)

  GW_ADD_TITLEBAR(pg_con, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("cancel") + ">BACK") + GW_ADD_BAR_TITLE$("")
  GW_ADD_FOOTBAR(pg_con, bar$)

  GW_INJECT_HTML(pg_con, "<style>td{vertical-align:middle}</style>")

  GW_INJECT_HTML(pg_con, "<table><thead></thead><tbody><tr><td>")
    chk_uselin = GW_ADD_FLIPSWITCH(pg_con, LBL$("has_lines"), LBL$("no"), ">" + LBL$("yes")) % Lined Console
  GW_INJECT_HTML(pg_con, "</td><td style='width:10px'></td><td>")
    chk_usemenu = GW_ADD_FLIPSWITCH(pg_con, LBL$("has_menu"), LBL$("no"), LBL$("yes")) % Console Menu
  GW_INJECT_HTML(pg_con, "</td></tr>")

  GW_INJECT_HTML(pg_con, "<tr><td>")
    col_fnt = GW_ADD_COLORPICKER(pg_con, LBL$("fnt_col"), con_fntcol$) % Font color
  GW_INJECT_HTML(pg_con, "</td><td style='width:10px'></td><td>")
    col_bgd = GW_ADD_COLORPICKER(pg_con, LBL$("bgd"), con_bgdcol$)     % Background
  GW_INJECT_HTML(pg_con, "</td></tr>")

  GW_INJECT_HTML(pg_con, "<tr><td>")
    col_lin = GW_ADD_COLORPICKER(pg_con, LBL$("lin"), con_lincol$)   % Lines
  GW_INJECT_HTML(pg_con, "</td><td style='width:10px'></td><td>")
    box_empty = GW_ADD_SELECTBOX(pg_con, LBL$("empty"), con_empty$[]) % Empty zone
    GW_ADD_LISTENER(pg_con, box_empty, "change", "NEWEMPT")
  GW_INJECT_HTML(pg_con, "</td></tr></tbody></table>")
  GW_INJECT_HTML(pg_con, "<hr style='border-top:1px solid rgba(130,130,130,.3)'>")

  GW_INJECT_HTML(pg_con, "<table><thead></thead><tbody><tr><td>")
    box_fntsiz = GW_ADD_SELECTBOX(pg_con, LBL$("fnt_siz"), con_fntsiz$[]) % Font Size
    GW_ADD_LISTENER(pg_con, box_fntsiz, "change", "NEWSIZ")
  GW_INJECT_HTML(pg_con, "</td><td style='width:10px'></td><td>")
    box_fnttyp = GW_ADD_SELECTBOX(pg_con, LBL$("fnt_typ"), con_fnttyp$[]) % Font Typeface
    GW_ADD_LISTENER(pg_con, box_fnttyp, "change", "NEWTYP")
  GW_INJECT_HTML(pg_con, "</td></tr></tbody></table>")

  box_scrdir = GW_ADD_SELECTBOX(pg_con, LBL$("scr_dir"), con_scrdir$[]) % Screen Orientation
  GW_ADD_LISTENER(pg_con, box_scrdir, "change", "NEWSCR")

  GW_USE_THEME_CUSTO_ONCE("icon=check style='background:green;color:white;text-shadow:none'")
  GW_ADD_BUTTON(pg_con, UPPER$(LBL$("validate")), "VALID") % VALIDATE CHANGES
ENDIF

%-------------------------------------------------------------------
% Console customization: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_con)
GW_MODIFY(col_fnt, "input", tmp_con_fntcol$)
GW_MODIFY(col_bgd, "input", tmp_con_bgdcol$)
GW_MODIFY(col_lin, "input", tmp_con_lincol$)
GW_MODIFY(box_empty, "selected", INT$(tmp_con_empty))
GW_MODIFY(box_fntsiz, "selected", INT$(tmp_con_fntsiz))
GW_MODIFY(box_fnttyp, "selected", INT$(tmp_con_fnttyp))
GW_MODIFY(box_scrdir, "selected", INT$(tmp_con_scrdir))
IF tmp_con_uselin THEN e$ = LBL$("yes") ELSE e$ = LBL$("no")
GW_MODIFY(chk_uselin, "selected", e$)
IF tmp_con_usemenu THEN e$ = LBL$("yes") ELSE e$ = LBL$("no")
GW_MODIFY(chk_usemenu, "selected", e$)

DO
  r$ = GW_WAIT_ACTION$()
  IF r$ = "EXIT" THEN EXIT
  IF GW_FLIPSWITCH_CHANGED(chk_uselin, LBL$("no"))
    tmp_con_uselin = 0
    r$ = ""
  ELSEIF GW_FLIPSWITCH_CHANGED(chk_uselin, LBL$("yes"))
    tmp_con_uselin = 1
    r$ = ""
  ELSEIF GW_FLIPSWITCH_CHANGED(chk_usemenu, LBL$("no"))
    tmp_con_usemenu = 0
    r$ = ""
  ELSEIF GW_FLIPSWITCH_CHANGED(chk_usemenu, LBL$("yes"))
    tmp_con_usemenu = 1
    r$ = ""
  ELSEIF IS_IN (GW_ID$(col_fnt), r$) = 1 THEN % color picker change
    tmp_con_fntcol$ = MID$ (r$, IS_IN(":", r$)+1) % extract '#rrggbb' out of 'CtlId:#rrggbb'
    r$ = ""
  ELSEIF IS_IN (GW_ID$(col_bgd), r$) = 1 THEN % color picker change
    tmp_con_bgdcol$ = MID$ (r$, IS_IN(":", r$)+1) % extract '#rrggbb' out of 'CtlId:#rrggbb'
    r$ = ""
  ELSEIF IS_IN (GW_ID$(col_lin), r$) = 1 THEN % color picker change
    tmp_con_lincol$ = MID$ (r$, IS_IN(":", r$)+1) % extract '#rrggbb' out of 'CtlId:#rrggbb'
    r$ = ""
  ELSEIF r$ = "NEWEMPT"
    tmp_con_empty = GW_GET_VALUE(box_empty)
    r$ = ""
  ELSEIF r$ = "NEWSIZ"
    tmp_con_fntsiz = GW_GET_VALUE(box_fntsiz)
    r$ = ""
  ELSEIF r$ = "NEWTYP"
    tmp_con_fnttyp = GW_GET_VALUE(box_fnttyp)
    r$ = ""
  ELSEIF r$ = "NEWSCR"
    tmp_con_scrdir = GW_GET_VALUE(box_scrdir)
    r$ = ""
  ENDIF
UNTIL LEN(r$)

IF r$ = "VALID" % save temp options as real ones
  con_uselin = tmp_con_uselin
  con_usemenu = tmp_con_usemenu
  con_fntcol$ = tmp_con_fntcol$
  con_bgdcol$ = tmp_con_bgdcol$
  con_lincol$ = tmp_con_lincol$
  con_empty = tmp_con_empty
  con_fntsiz = tmp_con_fntsiz
  con_fnttyp = tmp_con_fnttyp
  con_scrdir = tmp_con_scrdir
ELSEIF r$ = "BACK" | r$ = "HOME" % re-init temp options if user cancels then comes back
  tmp_con_uselin = con_uselin
  tmp_con_usemenu = con_usemenu
  tmp_con_fntcol$ = con_fntcol$
  tmp_con_bgdcol$ = con_bgdcol$
  tmp_con_lincol$ = con_lincol$
  tmp_con_empty = con_empty
  tmp_con_fntsiz = con_fntsiz
  tmp_con_fnttyp = con_fnttyp
  tmp_con_scrdir = con_scrdir
ENDIF
IF r$ = "HOME" THEN GOTO Proj_Menu
GOTO Sup_Adv

%-------------------------------------------------------------------
% Sum-up: create page
%-------------------------------------------------------------------
Sum_Up: % Screen #10
IF !pg_sum_up
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_sum_up = GW_NEW_PAGE()
  GW_ADD_LOADING_IMG(pg_sum_up, "thinking.gif", drk_thm)
  GW_ADD_TITLEBAR(pg_sum_up, tibar2$)

  bar$ = GW_ADD_BAR_LBUTTON$(LBL$("prev") + ">BACK") + GW_ADD_BAR_TITLE$("")
  GW_ADD_FOOTBAR(pg_sum_up, bar$)

  GW_START_CENTER(pg_sum_up)
  GW_ADD_IMAGE(pg_sum_up, "rfo.png")
  GW_STOP_CENTER(pg_sum_up)

  GW_START_CENTER(pg_sum_up)
  GW_INJECT_HTML(pg_sum_up, "<h2 style='display:inline-block'>" + LBL$("ready") + "</h2>") % Ready to compile:
  GW_STOP_CENTER(pg_sum_up)

  tx_sum_up = GW_ADD_TEXT(pg_sum_up, "")

  GW_ADD_TEXT(pg_sum_up, "<i>" + LBL$("hit_back") + "</i>") % Hit Back to make modifications.
  GW_ADD_BUTTON(pg_sum_up, UPPER$(LBL$("compile")), "GO")          % COMPILE !
ENDIF

%-------------------------------------------------------------------
% Sum-up: display page and handle user input
%-------------------------------------------------------------------
GW_RENDER(pg_sum_up)
GOSUB CreateSumUp
GW_MODIFY(tx_sum_up, "text", sumup$)
r$ = GW_WAIT_ACTION$()
IF r$ = "EXIT" THEN EXIT
IF r$ = "HOME" THEN GOTO Proj_Menu
IF r$ = "BACK"
  IF sup_adv
    GOTO Sup_Adv
  ELSEIF go_adv
    GOTO Adv_Opt
  ELSE
    GOTO Def_Nam
  ENDIF
ENDIF
