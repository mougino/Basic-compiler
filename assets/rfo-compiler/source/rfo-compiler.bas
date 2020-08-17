INCLUDE "rfo-comp-projedit.bas"

%-------------------------------------------------------------------
% Compilation: create page
%-------------------------------------------------------------------
CompileIt:
IF !pg_compil
  IF drk_thm THEN GW_USE_THEME_CUSTO(dark) ELSE GW_USE_THEME_CUSTO(light)
  pg_compil = GW_NEW_PAGE()
  GW_INSERT_BEFORE(pg_compil, "</head", "<script src='diacritics.js'></script>")
  GW_ADD_LOADING_IMG(pg_compil, "thinking.gif", drk_thm)
  GW_ADD_TITLEBAR(pg_compil, tibar2$)
  title_btns = GW_NEW_CLASS("ui-btn")

  GW_START_CENTER(pg_compil)
  android = GW_ADD_IMAGE(pg_compil, "compiling.gif")
  GW_STOP_CENTER(pg_compil)

  MAKE_SURE_IS_ON_SD("ok.png")
  MAKE_SURE_IS_ON_SD("ko.png")

  pgb_compil = GW_ADD_PROGRESSBAR(pg_compil, LBL$("unpack")) % Unpacking project...

  % Script to auto-update progress-bar
  % Usage: 1. call JS("var pgini=20")
  %        2. call JS("autoIncreasePgBar(+50, 3000)") % increase progress bar of 50 % in 3 seconds
  pg$ = GW_ID$(pgb_compil)
  e$ ="var pgcur=0; var interval;function doPg(tgt)"
  e$+="{pgcur+=0.1;$('#"+pg$+"').val(parseFloat(pgini)"
  e$+="+parseFloat(pgcur));$('input[name="+pg$+"]').slider"
  e$+="('refresh');if(pgcur>=tgt){clearInterval(interval);}}"
  e$+="function autoIncreasePgBar(tgtDelta, tgtTime){"
  e$+="interval=setInterval(function(){doPg(tgtDelta);},"
  e$+="0.1*tgtTime/tgtDelta);}"
  GW_INJECT_HTML(pg_compil, "<script>"+e$+"</script>")

  GW_USE_THEME_CUSTO_ONCE("style='color:red'")
  err_tx = GW_ADD_TEXT(pg_compil, "")
  BUNDLE.PUT 1, "err_tx", err_tx
ENDIF

%-------------------------------------------------------------------
% Compilation: display page and proceed to compilation
%-------------------------------------------------------------------
GW_RENDER(pg_compil)
GW_DISABLE(title_btns)
GW_MODIFY(pgb_compil, "text", LBL$("prepare")) % Preparing...
IF log_act
  FILE.DELETE fd, "../Compiler.log"
  e$ = "--  BASIC! Compiler "
  e$ += ver$ + verx$ + "  --"
  DEGUB(e$)
  DEGUB("OS version " + os$)
  DEGUB("Locale: " + lang$)
  DEGUB("SysPath: " + SYSPATH$())
  DEGUB("LibPath: " + LIBPATH$())
  DEGUB("00. Clean any previous project & install tools...")
ENDIF
appdir$ = ResolveDiacritics$(appdir$) % remove unicode characters in app folder
appbas2$ = ResolveDiacritics$(appbas$) % xml-safe version of main .bas name
GOSUB CleanProject
GOSUB InstallTools
FILE.DELETE fid, "../" + finalApk$
tot = 0 % re-init progress bar
t0 = CLOCK()

% Define changeable paths
IF spr_usr & LEN(appfla$) & appfla$ <> flav$[1]   % custom flavor
  prj$ = supath$ + appfla$ + "/"
  TEXT.OPEN r, fid, LEFT$(prj$, -1) + ".desc"
  IF fid < 0 THEN END "Fatal error opening " + LEFT$(prj$, -1) + ".desc"
  TEXT.READLN fid, pkg$           % read package name from .desc file
  TEXT.CLOSE fid
  pkg$ = REPLACE$(pkg$, ".", "/") + "/"
ELSE                              % standard RFO BASIC flavor
  prj$ = "Basic-" + ver$ + "/"    % folder of project to compile in sdcard/rfo-compiler/data
  pkg$ = "com/rfo/basic/"
ENDIF
GOSUB SetProjPaths

%============================= STEP 01 =============================
GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("unpack"), "XXX", appfla$)) % Unpacking project XXX...
newpkg$ = REPLACE$(apppkg$, ".", "/") + "/"

IF log_act
  DEGUB("01. Unpack project " + appfla$ + "...")
  DEGUB("    Getting list of files from " + LEFT$(REPLACE$(prj$, supath$, ""), -1) + ".lst")
ENDIF

projFiles$ = GetFile$(LEFT$(prj$, -1) + ".lst")
projFiles$ = REPLACE$(projFiles$, "\\", "/")
projFiles$ = REPLACE$(projFiles$, CHR$(13), "") % Remove all $CR
SPLIT all$[], projFiles$, "\\n" % split on new line
ARRAY.LENGTH nfiles, all$[]
IF log_act THEN DEGUB("    " + INT$(nfiles) + " files found")
FOR i=nfiles TO 1 STEP -1
  r$ = GW_ACTION$() % read (and ignore) user input during compilation
  file$ = TRIM$(all$[i])
  IF LEN(file$) = 0 THEN F_N.CONTINUE
  IF fast_cp & has_dex & (ENDS_WITH(".head", file$) | ENDS_WITH(".body", file$)) THEN F_N.CONTINUE
  % IF log_act THEN DEGUB("    Unpack " + REPLACE$(file$, supath$, ""))
  tgt$ = REPLACE$(file$, src$ + pkg$, src$ + newpkg$)
  tgt$ = REPLACE$(tgt$, RTRIM$(prj$, "/"), appdir$)
  FileCopy(file$, tgt$) % copy from assets/ to sdcard/rfo-compiler/data
  GW_SET_PROGRESSBAR(pgb_compil, tot + (nfiles+1-i)/nfiles*5) % -> 0 to 5 %
NEXT
tot += 5
ARRAY.DELETE all$[]

% (IMPORTANT) Now prj$/pkg$ have changed! Update all the App paths
prj$ = appdir$ + "/" % folder of project to compile in sdcard/rfo-compiler/data
oldpkgnam$ = REPLACE$(RTRIM$(pkg$, "/"), "/", ".")
pkg$ = newpkg$
GOSUB SetProjPaths

% Add some libs needed for flavors compilation
e$ = "android-support-compat-28.0.0.jar"
FILE.EXISTS fe, lib$+e$
IF !fe THEN FileCopy("Basic-"+ver$+"/libs/"+e$, lib$+e$)
e$ = "org.apache.http.legacy.jar"
FILE.EXISTS fe, lib$+e$
IF !fe THEN FileCopy("Basic-"+ver$+"/libs/"+e$, lib$+e$)

% Check result of Unpacking
FILE.EXISTS proj, prj$ + "AndroidManifest.xml"
IF !proj
  IF log_act THEN DEGUB("    Error: "+prj$+"AndroidManifest.xml not found!")
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  STOP(LBL$("unpack_ko")) % Unpacking KO!
ENDIF
%===================================================================

%===================================================================
IF fast_cp & has_dex
  IF log_act THEN DEGUB("02. [fast-recompile] Customize project...")
  tot = 19 : GW_SET_PROGRESSBAR(pgb_compil, tot)
  GOTO ChangePackageInXmls
ENDIF
%===================================================================

%============================= STEP 02 =============================
GW_MODIFY(pgb_compil, "text", LBL$("custo")) % Customizing...
path$ = src$ + pkg$
ext$ = ".head"
IF log_act
  DEGUB("02. Customize project...")
  DEGUB("    List all files...")
ENDIF
GOSUB ListFiles
IF log_act THEN DEGUB("    Change package in "+INT$(nfiles)+" java files")
% Change package in all Java files
FOR i=1 TO nfiles
  r$ = GW_ACTION$() % read (and ignore) user input during compilation
  LIST.GET files, i, file$
  java$ = REPLACE$(FileName$(file$), ".head", "")
  % IF log_act THEN DEGUB("    Change package in "+java$)
  GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("modify"), "XXX", java$)) % Modifying XXX
  ReplaceInFile(file$, oldpkgnam$, apppkg$)
  head$ = file$
  body$ = REPLACE$(file$, ".head", ".body")
  java$ = REPLACE$(file$, ".head", "")
  SHELL("cat " + DQ$(data$ + head$) + " " + DQ$(data$ + body$) + " > " + DQ$(data$ + java$))
  FILE.DELETE fid, head$
  FILE.DELETE fid, body$
  GW_SET_PROGRESSBAR(pgb_compil, tot + i/nfiles*14) % -> 5 to 19 %
NEXT
tot += 14

% Change package in all Xml files
ChangePackageInXmls:
GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("modify"), "XXX", "res/xmls")) % Modifying res/xmls
LIST.CLEAR files
RecursiveDir(res$, files)
LIST.SIZE files, nfiles
IF log_act THEN DEGUB("    Change package in "+INT$(nfiles)+" xml files")
FOR i=1 TO nfiles
  r$ = GW_ACTION$() % read (and ignore) user input during compilation
  LIST.GET files, i, file$
  IF RIGHT$(file$, 4) <> ".xml" THEN F_N.CONTINUE % skip non-xml files
  % IF log_act THEN DEGUB("    Change package in "+file$)
  ReplaceInFile(file$, oldpkgnam$, apppkg$)
NEXT
GW_SET_PROGRESSBAR(pgb_compil, ++tot) % -> 20 %

% Modify AndroidManifest.xml
GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("modify"), "XXX", "AndroidManifest.xml")) % Modifying AndroidManifest.xml
IF log_act THEN DEGUB("    Modify AndroidManifest.xml")
e$ = GetFile$(prj$ + "AndroidManifest.xml")
e$ = REPLACE$(e$, oldpkgnam$, apppkg$) % package
% Change permissions
FOR i=1 TO nperm
  IF chk_perm[i] THEN e$ = InsertBefore$(e$, "<uses-feature", PermStr$(permissions$[i]))
NEXT
% Change version name and code
ReplaceInlineContentWith(&e$, "android:versionName", appver$)
ReplaceInlineContentWith(&e$, "android:versionCode", appcod$)
% Advanced options in AndroidManifest.xml: start at boot
IF go_adv
  IF adv_sta THEN e$ = InsertBefore$(e$, "<uses-feature", PermStr$("<!>RECEIVE_BOOT_COMPLETED")) % permission
  ReplaceInlineContentAfterTagWith(&e$, "receiver", "android:enabled", TrueFalse$(adv_sta)) % .BootUpReceiver
ENDIF
% Super advanced options in AndroidManifest.xml: large heap memory, register extension(s)
IF sup_adv
  ReplaceInlineContentAfterTagWith(&e$, "application", "android:largeHeap", TrueFalse$(adv_mem))
  IF LEN(adv_reg$)
    ext$ = REPLACE$(LOWER$(adv_reg$), " ", "")
    e$ = InsertBefore$(e$, "</activity>", MakeIntentFilter$(ext$))
  ENDIF
ENDIF
% Save new manifest
PutFile(e$, prj$ + "AndroidManifest.xml")
tot+=0.5 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 20.5 %
% Nota: unregistering .bas file extension & launcher shortcut has
% already been done by PREP-RFOCOMP.EXE /or/ SuperUser...

% Modify Setup.xml
GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("modify"), "XXX", "Setup.xml")) % Modifying Setup.xml
IF log_act THEN DEGUB("    Modify Setup.xml")
e$ = GetFile$(res$ + "values/setup.xml")
ReplaceXmlContentWith(&e$, "bool name=" + CHR$(34) + "is_apk", "true")
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "version", appver$)
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "app_name", UtfProtect$(appnam$))
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "run_name", UtfProtect$(appnam$)) % console title
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "select_name", UtfProtect$(appnam$)) % select prompt
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "textinput_name", UtfProtect$(appnam$)) % input prompt
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "app_path", appdir$) % already ResolveDiacritics'ed
ReplaceXmlContentWith(&e$, "string name=" + CHR$(34) + "my_program", appbas2$) % idem, xml-safe
ReplaceXmlContentWith(&e$, "string-array name=" + CHR$(34) + "loading_msg", "")
% Advanced options from Setup.xml
IF go_adv
  ReplaceXmlContentWith(&e$, "bool name=" + CHR$(34) + "apk_create_data_dir", TrueFalse$(adv_dat))
  ReplaceXmlContentWith(&e$, "bool name=" + CHR$(34) + "apk_create_database_dir", TrueFalse$(adv_db))
ENDIF
% Super advanced options from Setup.xml
IF sup_adv
  % Splash screen
  ReplaceXmlContentWith(&e$, "bool name=" + CHR$(34) + "apk_programs_encrypted", TrueFalse$(adv_enc))
  ReplaceXmlContentWith(&e$, "bool name=" + CHR$(34) + "splash_display", TrueFalse$(splash_time * splash_img))
  ReplaceXmlContentWith(&e$, "integer name=" + CHR$(34) + "splash_time", INT$(1000 * splash_time))
  ReplaceXmlContentWith(&e$, "color name=" + CHR$(34) + "splash_color", UPPER$(splash_bgd$))
  % Console custo
  ReplaceXmlContentWith(&e$, "integer name=" + CHR$(34) + "color1", REPLACE$(con_lincol$, "#", "0xff"))
  ReplaceXmlContentWith(&e$, "integer name=" + CHR$(34) + "color2", REPLACE$(con_fntcol$, "#", "0xff"))
  ReplaceXmlContentWith(&e$, "integer name=" + CHR$(34) + "color3", REPLACE$(con_bgdcol$, "#", "0xff"))
  % Copy resources to sdcard
  IF adv_cpy
    GOSUB MakeResItems % list resources into 'Items$'
    ReplaceXmlContentWith(&e$, "string-array name=\"load_file_names\"", Items$)
  ENDIF
ENDIF
% Save new xml
PutFile(e$, res$ + "values/setup.xml")
tot+=0.5 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 21 %

IF sup_adv % modify Settings.xml
  IF log_act THEN DEGUB("    Modify Settings.xml")
  e$ = GetFile$(res$ + "xml/settings.xml")
  t$ = "android:key=" + CHR$(34)
  v$ = "android:defaultValue"
  ReplaceInlineContentAfterTagWith(&e$, t$ + "gr_accel", v$, TrueFalse$(adv_acc))
  ReplaceInlineContentAfterTagWith(&e$, t$ + "lined_console", v$, TrueFalse$(con_uselin))
  ReplaceInlineContentAfterTagWith(&e$, t$ + "console_menu", v$, TrueFalse$(con_usemenu))
  ReplaceInlineContentAfterTagWith(&e$, t$ + "empty_color_pref", v$, con_emptycol$[con_empty])
  ReplaceInlineContentAfterTagWith(&e$, t$ + "font_pref", v$, con_fntsiz$[con_fntsiz])
  ReplaceInlineContentAfterTagWith(&e$, t$ + "csf_pref", v$, xml_fnttyp$[con_fnttyp])
  ReplaceInlineContentAfterTagWith(&e$, t$ + "es_pref", v$, "WBL")
  ReplaceInlineContentAfterTagWith(&e$, t$ + "so_pref", v$, INT$(con_scrdir - 1))
  PutFile(e$, res$ + "xml/settings.xml")
ENDIF

% Create icons / splash screen
GW_MODIFY(pgb_compil, "text", LBL$("set_icons")) % Setting icons...
IF log_act THEN DEGUB("    Create icons")
IF drk_thm
  GR.OPEN 255, 0, 0, 0, HIDE_STATUS_BAR, GR_ORIENTATION-1
ELSE
  GR.OPEN 255, 255, 255, 255, HIDE_STATUS_BAR, GR_ORIENTATION-1
ENDIF
GrSaveAppIcons(ico_siz$[], appico$, res$) % save app icons in res/drawable-??dpi/icon.png
GrSaveNotifyIcon(appico$, res$) % save icon used for notification
IF sup_adv % modify splash screen only if user went in super advanced options
  IF splash_img & splash_img$ <> "splash.png"
    IF log_act THEN DEGUB("    Create splash screen")
    FILE.DELETE fid, res$ + "drawable/splash.png"
    GR.BITMAP.LOAD newsplash, splash_img$ % save new splash.png
    GR.BITMAP.SAVE newsplash, res$ + "drawable/splash.png"
    GR.BITMAP.DELETE newsplash
  ENDIF
ENDIF
GR.CLOSE
tot+=0.5 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 21.5 %

% Copy main .bas + include files to assets/<my-app>/source
GW_MODIFY(pgb_compil, "text", LBL$("copy_bas_res")) % Copying bas and resources
IF log_act THEN DEGUB("    Copy main .bas + include files to assets/<my-app>/source")
GOSUB CopyAssetsSrc

% Copy resources to assets/<my-app>/data
IF log_act THEN DEGUB("    Copy resources to assets/<my-app>/data")
GOSUB CopyAssetsData
tot+=0.5 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 22 %
%===================================================================

%===================================================================
IF fast_cp & has_dex
  IF log_act
    DEGUB("03. [fast-recompile] Skip R.java creation")
    DEGUB("04. [fast-recompile] Skip all java files compilation")
    DEGUB("05. [fast-recompile] Restore previous classes.dex")
  ENDIF
  FileCopy(apppkg$ + ".dex", "classes.dex")
  tot = 99 : GW_SET_PROGRESSBAR(pgb_compil, tot)
  GOTO PackageUnsigned
ENDIF
%===================================================================

%============================= STEP 03 =============================
GW_MODIFY(pgb_compil, "text", LBL$("create_r")) % Creating R.java
IF log_act THEN DEGUB("03. Create R.java with aapt package -m")

cmd$  = sys$ + "aapt package -m"
cmd$ += " -J " + DQ$(data$ + src$)
cmd$ += " -M " + DQ$(data$ + prj$ + "AndroidManifest.xml")
cmd$ += " -S " + DQ$(data$ + res$)
cmd$ += " -I " + DQ$(sys$ + "android.jar")
SHELL(cmd$)

GW_SET_PROGRESSBAR(pgb_compil, ++tot) % -> 23 %

FILE.EXISTS R, src$ + pkg$ + "R.java"
IF !R
  IF log_act THEN DEGUB("    Error: "+src$+pkg$+"R.java not found!\n"+SYSLOG$())
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  STOP(LBL$("err_r") + "\n" + SYSLOG$()) % Error creating R.java
ENDIF
%===================================================================

%============================= STEP 04 =============================
% List all java files from src/ and compile them
path$ = src$ + pkg$
ext$ = ".java"
IF log_act THEN DEGUB("04. List all java files from src/ and compile them")
GOSUB ListFiles

t1 = CLOCK()

FOR i=1 TO nfiles
  r$ = GW_ACTION$() % read (and ignore) user input during compilation
  file$ = ELT$(files, i)
  f$ = FileName$(file$)
  GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("compiling"), "XXX", f$)) % Compiling XXX
  IF log_act THEN DEGUB("    Compile "+file$)
  JAVAC (data$ + file$)
  err$ = GETERROR$()
  IF err$ <> "No error"
    GW_MODIFY(android, "src", "ko.png")
    GW_ENABLE(title_btns)
    e$ = REPLACE$(LBL$("err_compiling"), "XXX", f$) + "\n" + err$ % Compilation of XXX failed! Details:
    IF log_act THEN DEGUB("    Error: compilation failed\n"+err$)
    STOP(e$)
  ENDIF
  GW_SET_PROGRESSBAR(pgb_compil, tot + i/nfiles*30) % -> 23 to 53 %
NEXT
tot += 30 % -> 53 %

% Make a folder full of .class only -> remove all .java
FILE.DIR src$ + pkg$, all$[], "/"
ARRAY.LENGTH nall, all$[]
GW_MODIFY(pgb_compil, "text", REPLACE$(LBL$("classes"), "XXX", INT$(nall-nfiles))) % Produced XXX classes. Moving them to /bin
IF log_act THEN DEGUB("    "+INT$(nall-nfiles)+" classes produced")
FILE.RENAME src$, bin$
FOR i=1 TO nfiles
  r$ = GW_ACTION$() % read (and ignore) user input during compilation
	FILE.DELETE fd, REPLACE$(ELT$(files, i), src$, bin$)
NEXT

% Add classes for runtime: NEW PERMISSION SYSTEM
CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.ActivityCompat", bin$)
CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.ActivityCompat$RequestPermissionsRequestCodeValidator", bin$)
CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.ActivityCompat$OnRequestPermissionsResultCallback", bin$)
CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.content.ContextCompat", bin$)

% Add conditional classes depending on use of keywords
bas$ = rfopath$ + "source/" + appbas$
GOSUB GetAndFormatMainBas % content put in 'bas$' (in UPPER case)

IF IS_IN("\nNOTIFY", bas$) % Add classes for runtime: NOTIFICATIONS
  CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.NotificationCompatBuilder", bin$)
  CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.NotificationCompat$Builder", bin$)
  CopyClassFromLibTo(lib$+"android-support-compat-28.0.0.jar", "android.support.v4.app.NotificationBuilderWithBuilderAccessor", bin$)
ENDIF

IF IS_IN("\nFTP", bas$) % Add classes for runtime: FTP
  CopyClassFromLibTo(lib$+"commons-net-3.0.1.jar", "org.apache.commons.net.*", bin$)
ENDIF
%===================================================================

%============================= STEP 05 =============================
IF log_act THEN DEGUB("05. Dexify all compiled classes into classes.dex")
GW_MODIFY(pgb_compil, "text", LBL$("dex")) % Dexifying...

t1 = CLOCK() - t1 % t1 = time to compile full project (in ms)
FILE.EXISTS dxTiming, bsys$ + "timing.txt"
IF dxTiming % get dexify time from a previous compilation
  GRABFILE t1$, bsys$ + "timing.txt"
  t1$ = TRIM$(t1$)
ELSE        % else approximate dexify time to 1.5x compilation time
  t1$ = INT$(1.5 * t1)
ENDIF
t1 = CLOCK()
JS("var pgini=" + ENT$(tot))
JS("autoIncreasePgBar(+46, " + t1$ + ")") % -> 53 to 99 %

DEX (data$ + bin$)
DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation

JS("clearInterval(interval)") % force-stop autoIncreasePgBar()
tot += 46 % -> 99 %
GW_SET_PROGRESSBAR(pgb_compil, tot)

err$ = GETERROR$
IF LEN(TRIM$(err$)) & err$ <> "No error"
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  e$ = LBL$("err_dex") + "\n" + err$ % Following error was returned:
  IF log_act THEN DEGUB("    Error: dexifying failed\n"+err$)
  STOP(e$)
ENDIF

FILE.EXISTS dex, "classes.dex"
IF !dex
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  IF log_act THEN DEGUB("    Error: could not create classes.dex")
  STOP(LBL$("dex_ko")) % Dexifying KO!
ENDIF
FileCopy("classes.dex", apppkg$ + ".dex")

t1 = CLOCK() - t1
IF !dxTiming | t1 > VAL(t1$) % store actual dexify time
  TEXT.OPEN w, fid, bsys$ + "timing.txt"
  TEXT.WRITELN fid, INT$(t1)
  TEXT.CLOSE fid
ENDIF
%===================================================================

%============================= STEP 06 =============================
PackageUnsigned:
GW_MODIFY(pgb_compil, "text", LBL$("pack")) % Packaging
IF log_act THEN DEGUB("06. Package all components into temp-unsigned.apk with aapt package -f")

cmd$  = aapt$ + " package -f"
cmd$ += " -M " + DQ$(data$ + prj$ + "AndroidManifest.xml")
cmd$ += " -S " + DQ$(data$ + res$)
cmd$ += " -A " + DQ$(data$ + ast$)
cmd$ += " -F " + DQ$(data$ + "temp-unsigned.apk")
cmd$ += " -I " + DQ$(sys$ + "android.jar")
SHELL(cmd$)
IF log_act & LEN(SYSLOG$()) THEN DEGUB("    " + TRIM$(SYSLOG$()))

DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation

tot+=0.2 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 99.2 %

GOSUB DblCheckUnsignedApk

IF !unsigned % Backup Strat: package part of the apk with appt, part with the zip command
  IF log_act THEN DEGUB("    Backup strat! Package everything EXCEPT assets data with aapt package -f")
  DelRecursivePath(ast$+appdir$+"/data/", files, 1) % 1 = del assets data folder
  cmd$  = aapt$ + " package -f"
  cmd$ += " -M " + DQ$(data$ + prj$ + "AndroidManifest.xml")
  cmd$ += " -S " + DQ$(data$ + res$)
  cmd$ += " -A " + DQ$(data$ + ast$)
  cmd$ += " -F " + DQ$(data$ + "temp.apk")
  cmd$ += " -I " + DQ$(sys$ + "android.jar")
  SHELL(cmd$)
  IF log_act
    DEGUB("    " + SYSLOG$())
    DEGUB("    Now add assets with the ZIP command...")
  ENDIF
  GOSUB CopyAssetsData % put assets data back
  DelRecursivePath(src$, files, 1) % 1 = del src$ folder from 'prj$'
  DelRecursivePath(lib$, files, 1) % 1 = del lib$ folder from 'prj$'
  DelRecursivePath(bin$, files, 1) % 1 = del bin$ folder from 'prj$'
  DelRecursivePath(res$, files, 1) % 1 = del res$ folder from 'prj$'
  unzipped = UnzipTo("temp.apk", prj$) % extract simplified apk content (w/o assets data) to 'prj$'
  DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation
  IF !unzipped THEN GOTO BadPackage
  FILE.DELETE fid, "temp.apk"
  unsigned = ZipFrom(prj$, files, "temp-unsigned.apk", 0) % 0 = do not zip root folder
  DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation
ENDIF

BadPackage:
IF !unsigned
  IF log_act THEN DEGUB("    Error: could not create unsigned apk")
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  STOP(LBL$("pack_ko") + "\n" + SYSLOG$()) % Packaging KO!
ENDIF
PAUSE 250 % (1937)
%===================================================================

%============================= STEP 07 =============================
GW_MODIFY(pgb_compil, "text", LBL$("add_bin")) % Adding binaries
IF log_act THEN DEGUB("07. Add classes.dex to temp-unsigned.apk with aapt add -f")

FileCopy("classes.dex", "../classes.dex")

cmd$  = aapt$ + " add -f "
cmd$ += DQ$(data$ + "temp-unsigned.apk")
cmd$ += " classes.dex"
SHELL(cmd$)
IF log_act & LEN(SYSLOG$()) THEN DEGUB("    " + TRIM$(SYSLOG$()))

% Check if 'classes.dex' is in temp-unsigned.apk
ZIP.DIR "temp-unsigned.apk", zip$[], "/"
ARRAY.SEARCH zip$[], "classes.dex", found
IF !found
  IF log_act THEN DEGUB("    Backup strat: add classes.dex with jar command")
  cmd$  = "jar -uf "
  cmd$ += DQ$(data$ + "temp-unsigned.apk") + " -C "
  cmd$ += DQ$(data$)
  cmd$ += " classes.dex"
  SHELL(cmd$)
  IF log_act & LEN(SYSLOG$()) THEN DEGUB("    " + TRIM$(SYSLOG$()))
  ZIP.DIR "temp-unsigned.apk", zip$[], "/"
  ARRAY.SEARCH zip$[], "classes.dex", found
  IF !found
    IF log_act THEN DEGUB("    Error: could not add  classes.dex to unsigned apk")
    GW_MODIFY(android, "src", "ko.png")
    GW_ENABLE(title_btns)
    STOP(LBL$("pack_ko") + "\n" + SYSLOG$()) % Packaging KO!
  ENDIF
ENDIF

FILE.DELETE fid, "../classes.dex"
FILE.DELETE fid, "classes.dex"

DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation

tot+=0.2 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 99.4 %
%===================================================================

%============================= STEP 08 =============================
r$ = "" : IF (custom_pem_provided & custom_pk8_provided) THEN r$ = " (custom cert.)"
GW_MODIFY(pgb_compil, "text", LBL$("sign")+r$) % Signing
IF log_act THEN DEGUB("08. Sign temp-unsigned.apk into temp.apk"+r$)

SIGNAPK (data$ + "temp-unsigned.apk")

DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation

tot+=0.2 : GW_SET_PROGRESSBAR(pgb_compil, tot) % -> 99.6 %

FILE.EXISTS final, "temp.apk"
IF !final
  GW_MODIFY(android, "src", "ko.png")
  GW_ENABLE(title_btns)
  err$=GETERROR$()
  IF log_act THEN DEGUB("    Error: could not sign apk\n"+err$)
  STOP(LBL$("sign_ko") + "\n" + err$) % Signing KO!
ENDIF
%===================================================================

%============================= STEP 09 =============================
IF log_act THEN DEGUB("09. Clean project and rename temp.apk to "+finalApk$)
GW_MODIFY(pgb_compil, "text", LBL$("clean")) % Cleaning...
FILE.RENAME "temp.apk", "../" + finalApk$
GOSUB CleanProject

GW_SET_PROGRESSBAR(pgb_compil, 100) % 100%

DO : r$ = GW_ACTION$() : UNTIL r$ = "" % read (and ignore) user input during compilation

GW_MODIFY(android, "src", "ok.png")
e$ = REPLACE$(LBL$("compile_ok"), "XXX", "&quot;" + finalApk$ + "&quot;")
e$ = REPLACE$(e$, "YYY", HumanTime$(CLOCK() - t0))
GW_MODIFY(pgb_compil, "text", e$)
GW_ENABLE(title_btns)
%===================================================================

e$  = "<style>span{color:black;font-weight:normal;padding-left:20px;filter:invert("
IF drk_thm THEN e$ += "100%" ELSE e$ += "0%"
e$ += ")}</style>"
e$ += "<div style='height:10px'></div>"
e$ += "<a onclick=javascript:RFO('FOLDER')>"
e$ += "<img src='opendir.png' width='32' style='vertical-align:middle'>"
e$ += "<span>" + LBL$("open_dir") + "</span>"
e$ += "</a><br>"
e$ += "<div style='height:10px'></div>"
e$ += "<a onclick=javascript:RFO('INSTALL')>"
e$ += "<img src='install.png' width='32' style='vertical-align:middle'>"
e$ += "<span>" + LBL$("install") + "</span>"
e$ += "</a>"
GW_MODIFY(err_tx, "text", e$)

DO
  IF gofast
    r$ = "INSTALL"
    gofast = 0
  ELSE
    r$ = GW_WAIT_ACTION$()
  ENDIF
  IF r$ = "FOLDER"
    FILE.ROOT e$
    e$ = LEFT$(e$, IS_IN("/", e$, -1))
    APP.START "android.intent.action.VIEW", e$,,, "resource/folder",,, HEX("10000000") % FLAG_ACTIVITY_NEW_TASK
    err$=GETERROR$()
    IF err$ <> "No error" % no app registered to open folder via this intent
      POPUP "No Explorer found to open folder 'rfo-compiler', please open it manually"
    ENDIF
    r$ = ""
  ELSEIF r$ = "INSTALL"
    FILE.EXISTS fid, "../" + finalApk$
    IF !fid
      POPUP "file missing"
    ELSE
      FILE.ROOT e$ % try old method (older devices)
      e$ = "file://" + LEFT$(e$, IS_IN("/", e$, -1)) + finalApk$
      APP.START "android.intent.action.INSTALL_PACKAGE", e$ ,,, "*/*",,, HEX("10000000") % FLAG_ACTIVITY_NEW_TASK
      err$=GETERROR$()
      IF err$ <> "No error" % old method didnt'work --> try new method (unknown source apks permission request)
        InstallApk("../" + finalApk$)
        err$=GETERROR$() : IF err$ <> "No error" THEN POPUP err$
      ENDIF
    ENDIF
    r$ = ""
  ENDIF
UNTIL LEN(r$)
IF r$ = "EXIT" THEN EXIT
GOTO Proj_Menu

INCLUDE "rfo-comp-subs.bas"
