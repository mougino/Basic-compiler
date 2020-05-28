%-------------------------------------------------------------------
% RFO-Compiler shared Subs
%-------------------------------------------------------------------
SetProjPaths:
src$ = prj$ + "src/"
lib$ = prj$ + "libs/"
bin$ = prj$ + "bin/"
res$ = prj$ + "res/"
ast$ = prj$ + "assets/"
RETURN

DeleteProject:
GRABFILE buf$, proj$
j = IS_IN("% app package name", buf$)
IF 0=j THEN RETURN
i = IS_IN("\n", buf$, j-LEN(buf$))
IF 0=i THEN RETURN
p$ = MID$(buf$, i+1, j-i-2)
FILE.DELETE fid, p$ + ".dex"
FILE.DELETE fid, proj$
RETURN

InstallTools:
% New 1935: API 10 needs position-independent-executable
IF VAL(os$) >= 10
  FILE.DELETE fd, bsys$ + "aapt" % force reinstall of aapt
  t$ = "aapt-pie"
  IF log_act THEN DEGUB("    " + REPLACE$(LBL$("chmod"), "XXX", t$))
  FileCopy(t$, "aapt") % copy from assets/ to sdcard/rfo-compiler/data
  CopyFromDataToSys("aapt") % then from sdcard to /data/data/com.rfo.compiler
  GrantExecPerm("aapt")
  FILE.DELETE fid, "aapt" % delete from sdcard/rfo-compiler/data/
ENDIF
% New 1921: build against API >= 27 needs a new android.jar
aas = GetSize("android.jar")         % assets' android.jar size
sas = GetSize(bsys$ + "android.jar") % system' android.jar size
IF log_act
  DEGUB("    Assets 'android.jar' size: " + Sz$(aas))
  DEGUB("    System 'android.jar' size: " + Sz$(sas))
ENDIF
IF sas <> aas
  FILE.DELETE fd, bsys$ + "android.jar" % force reinstall of 'android.jar'
  FILE.EXISTS fe, bsys$ + "android.jar"
  IF fe
    GW_MODIFY(android, "src", "ko.png")
    GW_ENABLE(title_btns)
    STOP(REPLACE$(LBL$("inst_ko"), "XXX", sys$)) % Installation KO!\nCould not copy to XXX
  ENDIF
ENDIF
ARRAY.LENGTH ntools, tool$[]
FILE.EXISTS custom_pem_provided, "cert.x509.pem"
FILE.EXISTS custom_pk8_provided, "key.pk8"
FOR i=1 TO ntools
  IF (custom_pem_provided & custom_pk8_provided) & ~
     (tool$[i] = "cert.x509.pem" | tool$[i] = "key.pk8") THEN  % Custom certificate
    GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("inst_tool"), "XXX", tool$[i] + " (custom)")) % Installing XXX (custom)
    FILE.DELETE fid, bsys$ + tool$[i] % delete any existing cert
    CopyFromDataToSys(tool$[i])       % copy it from sdcard to /data/data/com.rfo.compiler
  ELSEIF !SysExist(tool$[i])
    IF !notif
      notif = 1
      t1 = CLOCK()
      GW_MODIFY(pgb_compil, "text", LBL$("install")) % Installing tools...
    ENDIF
    fe = 0 % assume tool doesn't exist on sdcard beforehand
    IF LEFT$(tool$[i],1) = "+"
      tool$[i] = MID$(tool$[i],2)
      GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("chmod"), "XXX", tool$[i]))  % Installing and Chmoding XXX
      t$ = tool$[i]
      IF t$ = "aapt" & VAL(os$) >= 5.0 THEN t$ = "aapt-pie" % Lollipop needs position-independent-executable
      IF log_act THEN DEGUB("    " + REPLACE$(LBL$("chmod"), "XXX", t$))
      FileCopy(t$, tool$[i]) % copy from assets/ to sdcard/rfo-compiler/data
      CopyFromDataToSys(tool$[i]) % then from sdcard to /data/data/com.rfo.compiler
      GrantExecPerm(tool$[i])
    ELSE
      GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("inst_tool"), "XXX", tool$[i])) % Installing XXX
      IF log_act THEN DEGUB("    " + REPLACE$(LBL$("inst_tool"), "XXX", tool$[i]))
      FILE.EXISTS fe, tool$[i]
      IF !fe THEN FileCopy(tool$[i], tool$[i]) % copy from assets/ to sdcard/rfo-compiler/data
      CopyFromDataToSys(tool$[i]) % then from sdcard to /data/data/com.rfo.compiler
    ENDIF
    IF !fe THEN FILE.DELETE fid, tool$[i] % delete from sdcard/rfo-compiler/data/
    IF !SysExist(tool$[i])
      GW_MODIFY(android, "src", "ko.png")
      GW_ENABLE(title_btns)
      STOP(REPLACE$(LBL$("inst_ko"), "XXX", sys$)) % Installation KO!\nCould not copy to XXX
    ENDIF
  ENDIF
NEXT
% Check that Android.jar was correctly installed (is the correct size)
sas = GetSize(bsys$ + "android.jar") % system' android.jar size
IF sas <> aas
  IF log_act
    DEGUB("    System 'android.jar' badly installed!")
    DEGUB("    Trying backup strat...")
  ENDIF
  GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("inst_tool"), "XXX", "android.jar (2)")) % Installing android.jar (2)
  IF log_act THEN DEGUB("    " + REPLACE$(LBL$("inst_tool"), "XXX", "android.jar (2)"))
  BYTE.OPEN r, fid, "android.jar"
  IF fid < 0 THEN GOTO AndroidJarErr
  BYTE.COPY fid, bsys$ + "android.jar" % copy directly from assets to data/data/rfo-compiler
  sas = GetSize(bsys$ + "android.jar") % system' android.jar size
  IF sas <> aas THEN GOTO AndroidJarErr
ENDIF
RETURN

AndroidJarErr:
IF log_act THEN DEGUB("    Unrecoverable error while installing 'android.jar'")
GW_MODIFY(android, "src", "ko.png")
GW_ENABLE(title_btns)
STOP(REPLACE$(LBL$("inst_ko"), "XXX", sys$)) % Installation KO!\nCould not copy to XXX
RETURN

InstallResource:
ARRAY.LENGTH nicos, file_ico$[]
FOR i=1 TO nicos
  MAKE_SURE_IS_ON_SD(file_ico$[i])
NEXT
ARRAY.LENGTH nicos, perm_ico$[]
FOR i=1 TO nicos
  MAKE_SURE_IS_ON_SD(perm_ico$[i])
  IF i=1 % version 1904: new 'perm1' icon
    FILE.SIZE fs, perm_ico$[1]
    IF fs <> 1127
      FILE.DELETE fs, perm_ico$[1]
      MAKE_SURE_IS_ON_SD(perm_ico$[1])
    ENDIF
  ENDIF
NEXT
FOR i=1 TO 6
  MAKE_SURE_IS_ON_SD("quali" + INT$(i) + ".png")
NEXT
MAKE_SURE_IS_ON_SD("diacritics.js")
MAKE_SURE_IS_ON_SD("nobas.png")
MAKE_SURE_IS_ON_SD("noico.png")
MAKE_SURE_IS_ON_SD("new.png")
MAKE_SURE_IS_ON_SD("opendir.png")
MAKE_SURE_IS_ON_SD("install.png")
MAKE_SURE_IS_ON_SD("splash.png")
MAKE_SURE_IS_ON_SD("blank.png")
RETURN

GetLabels:
FILE.EXISTS fid, "rfo-comp-labels-test" % Test label translations
IF fid
  GRABFILE lang$, "rfo-comp-labels-test"
  lang$ = UPPER$(LEFT$(TRIM$(lang$), 2))
ENDIF
TEXT.OPEN r, fid, "labels_" + lang$ + ".txt"
IF fid < 0
  lang$ = "EN"
  TEXT.OPEN r, fid, "labels_" + lang$ + ".txt"
ENDIF
DO
  TEXT.READLN fid, e$
  IF 0 = LEN(TRIM$(e$)) THEN D_U.CONTINUE % skip empty lines
  i = IS_IN("[", e$) : j = IS_IN("]", e$) % lines should be "[key] label"
  IF 0 = i | 0 = j THEN D_U.CONTINUE % if not, skip line
  key$ = LOWER$(TRIM$(MID$(e$, i+1, j-i-1)))
  lbl$ = LTRIM$(MID$(e$, j+1))
  BUNDLE.PUT 1, "lbl_" + key$, lbl$
UNTIL e$ = "EOF"
TEXT.CLOSE fid
RETURN

ListFiles: % list files with extension 'ext$' in path 'path$'
IF RIGHT$(path$,1) <> "/" THEN path$+="/"
LIST.CLEAR files
FILE.EXISTS fid, path$
IF !fid THEN nfiles = 0 : RETURN
FILE.DIR path$, all$[], "/"
ARRAY.LENGTH nfiles, all$[]
FOR i=1 TO nfiles
  IF RIGHT$(all$[i], LEN(ext$)) <> ext$ THEN F_N.CONTINUE
  LIST.ADD files, path$ + all$[i]
NEXT
LIST.SIZE files, nfiles
ARRAY.DELETE all$[]
% New: sort files alphabetically, regardless of case
IF 0=nfiles THEN RETURN
LIST.TOARRAY files, all$[]
FOR i=1 TO nfiles
  FOR j=i+1 TO nfiles
    IF LOWER$(all$[j]) < LOWER$(all$[i])
      SWAP all$[j], all$[i]
    ENDIF
  NEXT
NEXT
LIST.CLEAR files
LIST.ADD.ARRAY files, all$[]
ARRAY.DELETE all$[]
RETURN

CleanProject:
FILE.DELETE fid, "classes.dex" % delete classes.dex
FILE.DELETE fid, "temp-unsigned.apk" % delete unsigned apk
FILE.DELETE fid, "temp.apk" % delete aligned apk
DelRecursivePath(appdir$, files, 1) % delete the whole project folder
RETURN

SetAppFieldsRelyingOnAppName:
appdir$ = appnam$
apppkg$ = MakePackageName$(appnam$)
finalApk$ = appnam$ + ".apk"
RETURN

SetAppFieldsRelyingOnAppVersion:
appver$ = MakeValidVersion$(appver$)
appcod$ = MakeVersionCode$(appver$)
RETURN

RefreshAppIco:
GW_MODIFY(ico, "content", appico$)
script$ = "populate('quali'," + CHR$(34) + ImgQualiInfo$(ico_siz$[], appico$) + CHR$(34) + ")"
JS(script$)
RETURN

GetAndFormatMainBas:
bas$ = "\n" + GetFile$(bas$) % read main program
FOR i=1 TO nbas % append include files if any
  IF chk_bas[i] THEN bas$ += "\n" + GetFile$(rfopath$ + "source/" + bas$[i])
NEXT
bas$ = UPPER$(bas$)
bas$ = REPLACE$(bas$, CHR$(13), "") % Remove all $CR
bas$ = REPLACE$(bas$, ":", "\n") % Replace all ':' by $LF
% Split all inline IF/THEN[/ELSE] to multi-line IF/THEN[/ELSE]
bas$ = REPLACE$(bas$, "THEN", "\n")
bas$ = REPLACE$(bas$, "ELSE", "\nELSE\n")
% Supress all tabulations and spaces that start a line
WHILE IS_IN("\n\t", bas$) : bas$ = REPLACE$(bas$, "\n\t", "\n") : REPEAT
WHILE IS_IN("\n ", bas$) : bas$ = REPLACE$(bas$, "\n ", "\n") : REPEAT
% Remove all comment-blocks !! [..] !!
i=IS_IN("\n!!", bas$)
WHILE i
  j=IS_IN("\n!!", bas$, i+1)
  IF j THEN j=IS_IN("\n", bas$, j+1)
  IF 0=j THEN j=LEN(bas$)+1
  bas$=LEFT$(bas$, i-1) + MID$(bas$, j)
  i=IS_IN("\n!!", bas$)
REPEAT
RETURN

AutosetPermissions:
bas$ = rfopath$ + "source/" + appbas$
GOSUB GetAndFormatMainBas % content put in 'bas$'
% Initialize (reset) permissions
ARRAY.FILL chk_perm[], 0
% [1.WRITE_EXTERNAL_STORAGE] always set by default
chk_perm[1] = 1
% All other permissions: use rules specified in "kwperms.txt" (grabbed at beginning of program)
FOR i=1 TO nkwperm STEP 2 % STEP 2 because line #1 = permission / line #2 = keyword(s)
  p$ = TRIM$(UPPER$(kwperm$[i])) % permission
  IF LEFT$(p$,1) <> "[" THEN F_N.CONTINUE % skip malformed permission
  p$ = MID$(p$, 2)
  k$ = TRIM$(UPPER$(kwperm$[i+1])) % keyword(s)
  IF k$ = "" | k$ = "#" THEN F_N.CONTINUE % skip if no keywords provided
  j = IS_IN(".", p$) : IF j <= 0 THEN F_N.CONTINUE % line must be of the form [nn.PERM_NAME]
  p$ = LEFT$(p$, j-1) : perm = VAL(p$)
  j = IS_IN(",", k$)
  WHILE j % treat all keywords separated by comas
    kw$ = LEFT$(k$, j-1)
    k$ = LTRIM$(MID$(k$, j+1))
    IF IS_IN("\n" + kw$, bas$) THEN chk_perm[perm] = 1
    j = IS_IN(",", k$)
  REPEAT
  IF IS_IN("\n" + k$, bas$) THEN chk_perm[perm] = 1 % treat last keyword of the list (or a single keyword on the line)
NEXT
GOSUB SetPermIcoStr
perm_set = 1
RETURN

SetPermIcoStr:
perm_ico_str$ = ""
ARRAY.LENGTH nicos, perm_ico$[]
FOR i=1 TO nicos
  e$ = MID$(perm_ico$[i], 5) % "permN.M.O.png"
  j = IS_IN(".", e$)
  e$ = LEFT$(e$, j-1)
  perm = VAL(e$)
  IF chk_perm[perm]
    perm_ico_str$ += "<img src='" + perm_ico$[i] + "' width='16' height='16' style='filter:invert("
    IF drk_thm THEN perm_ico_str$ += "100%" ELSE perm_ico_str$ += "0%"
    perm_ico_str$ += ")'>"
  ENDIF
NEXT
RETURN

CreateSumUp:
sumup$  = "<b>" + LBL$("app_nam") + " </b>" + appnam$ + "<br>"            % App name:
IF spr_usr THEN sumup$ += LBL$("using") + " <b>" + appfla$ + "</b><br>"   % App flavor
sumup$ += "<b>" + LBL$("app_ver_str") + " </b>" + appver$ + "<br>"        % App version string:
sumup$ += "<b>" + LBL$("app_ver_cod") + " </b>" + appcod$ + "<br>"        % App version code:
sumup$ += "<b>" + LBL$("app_ico") + " </b>" + FileName$(appico$) + "<br>" % App icon:
sumup$ += "<b>" + LBL$("app_pkg_nam") + " </b>" + apppkg$ + "<br>"        % App package name:
sumup$ += "<b>" + LBL$("app_dir_2") + " </b>" + appdir$ + "<br>"          % App directory:
ARRAY.SUM nchk_bas, chk_bas[]
sumup$ += INT$(nchk_bas) + " " + Plural$(LBL$("inc_files"), nchk_bas) + "<br>" % N include file(s)
ARRAY.SUM nchk_res, chk_res[]
sumup$ += INT$(nchk_res) + " " + Plural$(LBL$("res_files"), nchk_res) + "<br>" % N selected resource(s)
nchk_perm = TALLY(perm_ico_str$, "<img")
sumup$ += INT$(nchk_perm) + " <b>" + Plural$(LBL$("perm_list"), nchk_perm)     % N permission(s)
sumup$ += " </b>" + perm_ico_str$ + "<br>"
RETURN

CreateProjDesc:
projdesc$  = "&#34;" + appnam$ + "&#34;<br>"
projdesc$ += "(<b>" + apppkg$ + "</b>)<br>"
projdesc$ += "v<b>" + appver$ + "</b> (" + appcod$ + ")<br>"
projdesc$ += perm_ico_str$
RETURN

InitProject: % initialize all fields/options of a project based on the only 'appbas$' property
% Initialize app fields
appnam$ = LEFT$(appbas$, IS_IN(".", appbas$, -1)-1)
appnam$ = REPLACE$(appnam$, "_", " ")
IF IS_IN("/", appnam$) THEN appnam$ = MID$(appnam$, IS_IN("/", appnam$, -1)+1)
i = 0 : i$ = ""
DO
  FILE.EXISTS fid, "../" + appnam$ + i$ + ".rfo"
  IF fid THEN i$ = " (" + INT$(++i) + ")"
UNTIL !fid
appnam$ += i$
GOSUB SetAppFieldsRelyingOnAppName % set apppkg$, appdir$ & finalApk$
appver$ = "0.1"
GOSUB SetAppFieldsRelyingOnAppVersion % set appver$, appcod$
appico$ = "hold.png"
% Initialize include files
has_inc = 0
ARRAY.FILL chk_bas[], 0
% Initialize resources
has_res = 0
ARRAY.FILL chk_res[], 0
% Initialize permissions
ARRAY.FILL chk_perm[], 0
perm_set = 0 % will force AutosetPermissions
% Initialize advanced Options
go_adv = 0
adv_sta = 0 % start at boot
adv_dat = 1 % create data/
adv_db = 1  % create databases/
% Initialize super advanced options
sup_adv = 0
adv_acc = 1 % hardware acceleration
adv_mem = 0 % large heap memory
adv_enc = 0 % encrypt .bas files
adv_cpy = 0 % copy resources to sdcard
splash_time = 0 % no splash screen
splash_bgd$ = "#ffffff"
splash_img = 0
splash_img$ = "splash.png"
con_uselin = 1
con_usemenu = 0
con_fntcol$ = "#000000"
con_bgdcol$ = "#ffffff"
con_lincol$ = "#408080"
con_empty = 1
con_fntsiz = 2
con_fnttyp = 1
con_scrdir = 1
adv_reg$ = "" % register extensions
RETURN

SaveProject:
TEXT.OPEN w, fid, "../" + appnam$ + ".rfo"
IF fid < 0 THEN END "Error saving " + appnam$ + ".rfo"
TEXT.WRITELN fid, TimeStamp$()
% Save app fields
TEXT.WRITELN fid, "%% App fields %%"
TEXT.WRITELN fid, appbas$ + " % main .bas"
TEXT.WRITELN fid, appnam$ + " % app name"
TEXT.WRITELN fid, appver$ + " % app version name"
TEXT.WRITELN fid, appcod$ + " % app version code"
TEXT.WRITELN fid, apppkg$ + " % app package name"
TEXT.WRITELN fid, appdir$ + " % app folder on sd"
TEXT.WRITELN fid, appico$ + " % app icon"
TEXT.WRITELN fid, appfla$ + " % compilation flavor"
% Save include files
TEXT.WRITELN fid, "%% Include files %%"
TEXT.WRITELN fid, INT$(has_inc) + " % program has includes: " + TrueFalse$(has_inc)
ARRAY.SUM nchk_bas, chk_bas[]
TEXT.WRITELN fid, INT$(nchk_bas) + " % number of include files"
FOR i=1 TO nbas
  IF chk_bas[i] THEN TEXT.WRITELN fid, bas$[i]
NEXT
% Save resources
TEXT.WRITELN fid, "%% Resources %%"
TEXT.WRITELN fid, INT$(has_res) + " % program has resources: " + TrueFalse$(has_res)
ARRAY.SUM nchk_res, chk_res[]
TEXT.WRITELN fid, INT$(nchk_res) + " % number of resource files"
FOR i=1 TO nres
  IF chk_res[i] THEN TEXT.WRITELN fid, res$[i]
NEXT
% Save permissions
TEXT.WRITELN fid, "%% Permissions %%"
ARRAY.SUM nchk_perm, chk_perm[]
TEXT.WRITELN fid, INT$(nchk_perm) + " % number of permissions"
FOR i=1 TO nperm
  IF chk_perm[i] THEN TEXT.WRITELN fid, permissions$[i]
NEXT
% Save advanced Options
TEXT.WRITELN fid, "%% Advanced options %%"
TEXT.WRITELN fid, INT$(go_adv) + " % show advanced: " + TrueFalse$(go_adv)
TEXT.WRITELN fid, INT$(adv_sta) + " % start at boot"
TEXT.WRITELN fid, INT$(adv_dat) + " % create data/ dir"
TEXT.WRITELN fid, INT$(adv_db) + " % create databases/ dir"
TEXT.WRITELN fid, adv_reg$ + " % registered extensions"
% Save super advanced options
TEXT.WRITELN fid, "%% Super advanced options %%"
TEXT.WRITELN fid, INT$(sup_adv) + " % show super advanced: " + TrueFalse$(sup_adv)
TEXT.WRITELN fid, INT$(adv_acc) + " % hardware acceleration"
TEXT.WRITELN fid, INT$(adv_mem) + " % large heap memory"
TEXT.WRITELN fid, INT$(adv_enc) + " % encrypt .bas files"
TEXT.WRITELN fid, INT$(adv_cpy) + " % copy resources to sdcard"
TEXT.WRITELN fid, INT$(splash_time) + " % splash time"
TEXT.WRITELN fid, splash_bgd$ + " % splash background color"
TEXT.WRITELN fid, INT$(splash_img) + " % use image or not"
TEXT.WRITELN fid, splash_img$ + " % splash image name"
TEXT.WRITELN fid, INT$(con_uselin) + " % console has lines or not"
TEXT.WRITELN fid, con_fntcol$ + " % console font color"
TEXT.WRITELN fid, con_bgdcol$ + " % console background color"
TEXT.WRITELN fid, con_lincol$ + " % console line/empty color"
TEXT.WRITELN fid, INT$(con_fntsiz) + " % console font size"
TEXT.WRITELN fid, INT$(con_fnttyp) + " % console font type"
TEXT.WRITELN fid, INT$(con_scrdir) + " % screen orientation"
TEXT.WRITELN fid, INT$(con_usemenu) + " % console has menu or not" % new
TEXT.WRITELN fid, INT$(con_empty) + " % console empty-zone color" % new
TEXT.CLOSE fid
RETURN

LoadProject:
GRABFILE buf$, proj$
TEXT.OPEN r, fid, proj$
% Load app fields
appbas$ = GetStrFromComment$(buf$, "% main .bas")
appnam$ = GetStrFromComment$(buf$, "% app name")
finalApk$ = appnam$ + ".apk"
appver$ = GetStrFromComment$(buf$, "% app version name")
appcod$ = GetStrFromComment$(buf$, "% app version code")
apppkg$ = GetStrFromComment$(buf$, "% app package name")
appdir$ = GetStrFromComment$(buf$, "% app folder on sd")
appico$ = GetStrFromComment$(buf$, "% app icon")
appfla$ = GetStrFromComment$(buf$, "% compilation flavor")
FILE.EXISTS fe, appico$ : IF 0=fe THEN appico$ = "hold.png"
% Load include files
ReadTextFileTillComment(fid, "%% Include files %%")
has_inc = ReadNumberFrom(fid)
nchk_bas = ReadNumberFrom(fid)
FOR i=1 TO nchk_bas
  TEXT.READLN fid, e$
  ARRAY.SEARCH bas$[], e$, k
  IF k THEN chk_bas[k] = 1
NEXT
% Load resources
ReadTextFileTillComment(fid, "%% Resources %%")
has_res = ReadNumberFrom(fid)
nchk_res = ReadNumberFrom(fid)
FOR i=1 TO nchk_res
  TEXT.READLN fid, e$
  ARRAY.SEARCH res$[], e$, k
  IF k
    chk_res[k] = 1
  ELSEIF IS_IN("jquery", e$)=1 % GW lib V4.3 support
    ARRAY.SEARCH res$[], "GW/", k
    IF k THEN chk_res[k] = 1
  ENDIF
NEXT
% Load permissions
ReadTextFileTillComment(fid, "%% Permissions %%")
nchk_perm = ReadNumberFrom(fid)
FOR i=1 TO nchk_perm
  TEXT.READLN fid, e$
  ARRAY.SEARCH permissions$[], e$, k
  IF k THEN chk_perm[k] = 1
NEXT
perm_set = 1
GOSUB SetPermIcoStr % used in sum-up
% Load advanced Options
go_adv   = GetNbFromComment  (buf$, "% show advanced:")
adv_sta  = GetNbFromComment  (buf$, "% start at boot")
adv_dat  = GetNbFromComment  (buf$, "% create data/ dir")
adv_db   = GetNbFromComment  (buf$, "% create databases/ dir")
adv_reg$ = GetStrFromComment$(buf$, "% registered extensions")
IF adv_reg$ = "" % backup compatibility for BC < 1930
  ReadTextFileTillComment(fid, "% create databases/ dir")
  TEXT.READLN fid, adv_reg$
ENDIF
IF LEFT$(adv_reg$, 1) <> "." THEN adv_reg$ = ""
% Load super advanced options
sup_adv     = GetNbFromComment  (buf$, "% show super advanced:")
adv_acc     = GetNbFromComment  (buf$, "% hardware acceleration")
adv_mem     = GetNbFromComment  (buf$, "% large heap memory")
adv_enc     = GetNbFromComment  (buf$, "% encrypt .bas files")
adv_cpy     = GetNbFromComment  (buf$, "% copy resources to sdcard")
splash_time = GetNbFromComment  (buf$, "% splash time")
splash_bgd$ = GetStrFromComment$(buf$, "% splash background color")
splash_img  = GetNbFromComment  (buf$, "% use image or not")
splash_img$ = GetStrFromComment$(buf$, "% splash image name")
con_uselin  = GetNbFromComment  (buf$, "% console has lines or not")
con_fntcol$ = GetStrFromComment$(buf$, "% console font color")
con_bgdcol$ = GetStrFromComment$(buf$, "% console background color")
con_lincol$ = GetStrFromComment$(buf$, "% console line/empty color")
con_fntsiz  = GetNbFromComment  (buf$, "% console font size")
con_fnttyp  = GetNbFromComment  (buf$, "% console font type")
con_scrdir  = GetNbFromComment  (buf$, "% screen orientation")
con_usemenu = GetNbFromComment  (buf$, "% console has menu or not")
con_empty   = GetNbFromComment  (buf$, "% console empty-zone color")
TEXT.CLOSE fid
RETURN

SaveConfigFile:
TEXT.OPEN w, cfg_id, bsys$ + "compiler.cfg"
TEXT.WRITELN cfg_id, INT$(drk_thm) % dark theme
TEXT.WRITELN cfg_id, INT$(fast_cp) % fast re-compile
TEXT.WRITELN cfg_id, INT$(log_act) % logs activated
TEXT.WRITELN cfg_id, INT$(vis_imp) % visually impaired
TEXT.WRITELN cfg_id, INT$(spr_usr) % super user
TEXT.CLOSE cfg_id
RETURN

ChangeThemeInAllPages:
srcthm$ = "='b'"  : tgtthm$ = "='a'"
srccol$ = "#000}" : tgtcol$ = "#fff}"
srcprm$ = "invert(100%)" : tgtprm$ = "invert(0%)"
IF drk_thm
  SWAP srcthm$, tgtthm$
  SWAP srccol$, tgtcol$
ENDIF
ARRAY.LOAD pages[], pg_no_rfo, pg_no_bas, pg_app_ico, pg_proj, pg_sel_bas, pg_sel_inc, pg_sel_res ~
  pg_fast_cp, pg_app_nam, pg_adv_opt, pg_perm, pg_sup_adv, pg_splash, pg_con, pg_sum_up, pg_compil
ARRAY.LENGTH npg, pages[]
FOR k=1 TO npg
  pg = pages[k]
  IF pg
    p$ = GW_PAGE$(pg)
    p$ = REPLACE$(p$, srcthm$, tgtthm$)
    p$ = REPLACE$(p$, srccol$, tgtcol$)
    p$ = REPLACE$(p$, srcprm$, tgtprm$)
    GW_SET_SKEY("page", pg, p$)
  ENDIF
NEXT
RETURN

%-------------------------------------------------------------------
% New: resource case-mismatch detection system
%-------------------------------------------------------------------
DetectIncResCaseMismatch:
nbas$ = GetFile$(bas$) % read program
ubas$ = UPPER$(nbas$)  % make an upper case version
bas$  = MID$(bas$, LEN(rfopath$ + "source/")+1) % only keep bas name, remove path
IF ircm_dbg THEN DEGUB("DetectIncResCaseMismatch for '"+bas$+"'")
% 1. Detect errors in referencing INCLUDEs
FOR j=1 TO nbas % for each include (its case is exact since it comes from a FILE.DIR)
  IF chk_bas[j] THEN
    file$ = bas$[j]
    GOSUB AnalyzeMismatch
  ENDIF
NEXT
% 2. Detect errors in referencing RESOURCEs
FOR j=1 TO nres
  IF chk_res[j] % for each resource (its case is exact since it comes from a FILE.DIR)
    IF RIGHT$(res$[j], 1) = "/"   % do (recursively) for resource subfolders
      LIST.CLEAR files
      RecursiveDir(rfopath$ + "data/" + res$[j], files)
      LIST.SIZE files, nfiles
      FOR k=1 TO nfiles
        r$ = GW_ACTION$() % read (and ignore) user input
        LIST.GET files, k, file$
        IF RIGHT$(file$, 1) = "/" THEN F_N.CONTINUE % skip folders
        file$ = MID$(file$, LEN(rfopath$ + "data/")+1) % only keep res name, remove path
        GOSUB AnalyzeMismatch % only analyze subfolders' files
      NEXT
    ELSE                  % do for single resource file
      file$ = res$[j]
      GOSUB AnalyzeMismatch
    ENDIF
  ENDIF
NEXT
nbas$ = "" : ubas$ = "" % clean-up
RETURN

AnalyzeMismatch:
IF ircm_dbg
  IF RIGHT$(UPPER$(file$), 3) = "BAS" THEN r$ = "inc" ELSE r$ = "res"
  DEGUB("  - AnalyzeMismatch "+r$+":'"+file$+"'")
ENDIF
v = IS_IN(UPPER$(file$), ubas$)
WHILE v % for each case-insensitive occurence of this filename in the program
  IF file$ <> MID$(nbas$,v,LEN(file$)) % check if there's a case mismatch
    LIST.SEARCH mm_fina, file$, m
    IF 0=m % first time we see a mismatch for this resource -> add it to mm_fina
      IF ircm_dbg THEN DEGUB("    Found a bad reference! (case mismatch)")
      LIST.ADD mm_fina, file$
      LIST.ADD mm_desc, ""
      LIST.SIZE mm_fina, m
    ELSE
      IF ircm_dbg THEN DEGUB("    Found *another* bad reference!")
    ENDIF
    LIST.GET mm_desc, m, desc$ % in any case, enrich the description in mm_desc
    u = IS_IN("@ "+bas$, desc$)
    IF u>0
      u = IS_IN(")", desc$, u) % bas already listed -> only add new mismatch line
      desc$ = LEFT$(desc$,u-1) + "," + INT$(TALLY(LEFT$(nbas$,v),"\n")+1) + MID$(desc$,u)
    ELSE                       % new bas -> add it + mismatch line
      desc$ += ", @ " + bas$ + " (L:" + INT$(TALLY(LEFT$(nbas$,v),"\n")+1) + ")"
    ENDIF
    IF LEFT$(desc$,2) = ", " THEN desc$ = MID$(desc$,2)
    LIST.REPLACE mm_desc, m, desc$
    IF ircm_dbg THEN DEGUB("    Added extra info: '"+desc$+"'")
  ELSE
    IF ircm_dbg THEN DEGUB("    Found a correct reference - Nothing to do")
  ENDIF
  v = IS_IN(UPPER$(file$), ubas$, v+1) % continue to next occurence
REPEAT
RETURN

FixIncResCaseMismatch:
bas$ = ""
LIST.SIZE mm_fina, ircm % ircm = include/resource case mismatch
IF ircm_dbg THEN DEGUB("FixIncResCaseMismatch for "+INT$(ircm)+" bad reference(s)")
FOR i=1 TO ircm
  LIST.GET mm_fina, i, r$ % include or resource name
  LIST.GET mm_desc, i, d$ % description
  nbas$ = TRIM$(InBetween$(d$, "@", "("))
  IF nbas$ <> bas$
    IF bas$ <> ""
      IF ircm_dbg THEN DEGUB("  - Writing '"+bas$+"' ("+INT$(LEN(buf$))+" B.)")
      PutFile(buf$, rfopath$ + "source/" + bas$)
    ENDIF
    bas$ = nbas$
    buf$ = GetFile$(rfopath$ + "source/" + bas$)
    IF ircm_dbg THEN DEGUB("  - Reading '"+bas$+"' ("+INT$(LEN(buf$))+" B.)")
  ENDIF
  k = IS_IN(UPPER$(r$), UPPER$(buf$))
  WHILE k % for each case-insensitive occurence of this resource
    IF ircm_dbg THEN DEGUB("    Replacing bad reference (#"+INT$(i)+") to '"+r$+"' at offset #"+INT$(k))
    buf$ = LEFT$(buf$, k-1) + r$ + MID$(buf$, k+LEN(r$)) % replace its call
    k = IS_IN(UPPER$(r$), UPPER$(buf$), k+1)
  REPEAT
NEXT
IF ircm_dbg THEN DEGUB("  - Writing '"+bas$+"' ("+INT$(LEN(buf$))+" B.)")
PutFile(buf$, rfopath$ + "source/" + bas$)
RETURN

RefreshIncResMismatchInfo:
ircm$  = ""
html$  = "<style>tr.border_bottom td{height:15px;border-bottom:3px dotted silver}</style>"
html$ +="<br><table><thead></thead><tbody>"
FOR i=1 TO ircm
  LIST.GET mm_fina, i, r$ % resource name
  LIST.GET mm_desc, i, d$ % description
  d$ = REPLACE$(d$, "@", "in")
  html$ += "<tr><td><img src='"+ext_ico$(r$)+"'></td><td>"+CHR$(34)+"<b>"+r$+"</b>"+CHR$(34)+"</td></tr>"
  html$ += "<tr><td></td><td><small>"+d$+"</small></td></tr>"
  html$ += "<tr class='border_bottom'><td></td><td></td></tr>"
  d$ = REPLACE$(d$, ",", ", ")
  ircm$  += "Case mismatch referencing " + CHR$(34) + r$ + CHR$(34) + d$ + "\n"
NEXT
html$ += "</tbody></table><br>"
RETURN

CopyAssetsSrc:
IF adv_enc % super advanced option "encrypt .bas files" is checked
  e$ = ENCODE$("ENCRYPT_RAW", apppkg$, GetFile$(rfopath$ + "source/" + appbas$))
  PutFile(e$, ast$ + appdir$ + "/source/" + appbas2$)
  FOR i=1 TO nbas
    IF chk_bas[i]
      e$ = ENCODE$("ENCRYPT_RAW", apppkg$, GetFile$(rfopath$ + "source/" + bas$[i]))
      PutFile(e$, ast$ + appdir$ + "/source/" + bas$[i])
    ENDIF
  NEXT
ELSE % normal copy (not encrypted)
  FileCopy(rfopath$ + "source/" + appbas$, ast$ + appdir$ + "/source/" + appbas2$)
  FOR i=1 TO nbas
    IF chk_bas[i] THEN FileCopy(rfopath$ + "source/" + bas$[i], ast$ + appdir$ + "/source/" + bas$[i])
  NEXT
ENDIF
RETURN

CopyAssetsData:
FOR i=1 TO nres
  IF chk_res[i]
    IF RIGHT$(res$[i], 1) = "/" % copy (recursively) resource subfolder
      LIST.CLEAR files
      RecursiveDir(rfopath$ + "data/" + res$[i], files)
      LIST.SIZE files, nfiles
      FOR j=1 TO nfiles
        r$ = GW_ACTION$() % read (and ignore) user input during compilation
        LIST.GET files, j, file$
        IF RIGHT$(file$, 1) = "/" THEN F_N.CONTINUE % skip folders
        tgt$ = REPLACE$(file$, rfopath$ + "data/", ast$ + appdir$ + "/data/")
        FileCopy(file$, tgt$)
      NEXT
    ELSE                        % copy single resource file
      FileCopy(rfopath$ + "data/" + res$[i], ast$ + appdir$ + "/data/" + res$[i])
    ENDIF
  ENDIF
NEXT
RETURN

MakeResItems:
Items$ = "\n"
FOR i=1 TO nres
  IF chk_res[i]
    IF RIGHT$(res$[i], 1) = "/" % list (recursively) resource subfolders
      LIST.CLEAR files
      RecursiveDir(rfopath$ + "data/" + res$[i], files)
      LIST.SIZE files, nfiles
      FOR j=1 TO nfiles
        r$ = GW_ACTION$() % read (and ignore) user input during compilation
        LIST.GET files, j, file$
        IF RIGHT$(file$, 1) = "/" THEN F_N.CONTINUE % skip folders
        file$ = REPLACE$(file$, rfopath$ + "data/", "")
        file$ = REPLACE$(file$, "&", "&amp;")
        Items$ += "      <item>" + REPLACE$(file$,"&","&amp;") + "</item>\n"
      NEXT
    ELSE                        % list single resource file
        file$ = REPLACE$(res$[i], "&", "&amp;")
        Items$ += "      <item>" + REPLACE$(file$,"&","&amp;") + "</item>\n"
    ENDIF
  ENDIF
NEXT
RETURN

DblCheckUnsignedApk: % check presence of the unsigned apk both with FILES.EXISTS and SHELL LS
FILE.EXISTS unsigned, "temp-unsigned.apk"
IF !unsigned
  IF log_act THEN DEGUB("    Error: rfo-compiler/data/temp-unsigned.apk not found with FILE.EXISTS! Retrying after 2 seconds")
  PAUSE 2000
  FILE.EXISTS unsigned, "temp-unsigned.apk"
  IF !unsigned
    IF log_act THEN DEGUB("    Error: temp-unsigned.apk still not found! Retrying with shell command ls...")
    SHELL("ls " + DQ$(data$ + "temp-unsigned.apk"))
    IF log_act THEN DEGUB("    Result of ls "+data$+"temp-unsigned.apk: "+SYSLOG$())
    IF IS_IN("no such file", LOWER$(SYSLOG$())) THEN unsigned=0 ELSE unsigned=1
  ENDIF
ENDIF
RETURN
