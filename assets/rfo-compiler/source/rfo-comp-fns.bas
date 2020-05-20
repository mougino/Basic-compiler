%-------------------------------------------------------------------
% RFO-Compiler shared Functions
%-------------------------------------------------------------------
FN.DEF SHELL(cmd$) % execute shell command
  SYSTEM.OPEN      % result (error..) is accessible through SYSLOG$()
  SYSTEM.WRITE cmd$ + " 2>&1"
  c0 = CLOCK()
  DO
    c1 = CLOCK()
    DO
      SYSTEM.READ.READY ready
      PAUSE 1
    UNTIL ready | CLOCK() - c1 > 500
    IF ready
      SYSTEM.READ.LINE answer$
      slog$ += answer$ + "\n"
    ENDIF
  UNTIL !ready | CLOCK() - c0 > 3000
  SYSTEM.CLOSE
  BUNDLE.PUT 1, "sys-log", slog$
FN.END

FN.DEF SYSLOG$()
  BUNDLE.GET 1, "sys-log", slog$
  FN.RTN slog$
FN.END

FN.DEF ListSwap(list, idx1, idx2)
  LIST.TYPE list, typ$
  IF typ$ = "S"
    LIST.GET list, idx1, s1$
    LIST.GET list, idx2, s2$
    LIST.REPLACE list, idx1, s2$
    LIST.REPLACE list, idx2, s1$
  ELSE
    LIST.GET list, idx1, n1
    LIST.GET list, idx2, n2
    LIST.REPLACE list, idx1, n2
    LIST.REPLACE list, idx2, n1
  ENDIF
FN.END

FN.DEF ELT$(list, index)
  LIST.TYPE list, typ$
  IF typ$ = "S"
    LIST.GET list, index, s$
  ELSE
    LIST.GET list, index, s
    s$ = INT$(s)
  ENDIF
  FN.RTN s$
FN.END

FN.DEF LBL$(key$)
  BUNDLE.CONTAIN 1, "lbl_" + LOWER$(key$), exist
  IF !exist THEN FN.RTN ""
  BUNDLE.GET 1, "lbl_" + LOWER$(key$), lbl$
  lbl$ = REPLACE$(lbl$, "\\n", "\n")
  FN.RTN lbl$
FN.END

FN.DEF Plural$(w$, v) % Plural$("date(s)", <=1) returns "date" ; Plural$("date(s)", >1) returns "dates"
  i = IS_IN("(", w$)
  j = IS_IN(")", w$)
  IF 0=i | 0=j | i>j THEN FN.RTN w$
  e$ = MID$(w$, i+1, j-i-1)
  IF v > 1
    FN.RTN REPLACE$(w$, "("+e$+")", e$)
  ELSE
    FN.RTN REPLACE$(w$, "("+e$+")", "")
  ENDIF
FN.END

FN.DEF TrueFalse$(v)
  IF v THEN FN.RTN "true" ELSE FN.RTN "false"
FN.END

FN.DEF Sz$(a)
 IF a >= 1000^2
  FN.RTN STR$(INT(10*a/1000^2)/10) + " MB"
 ELSEIF a >= 1000
  FN.RTN STR$(INT(a/100)/10) + " KB"
 ELSE
  FN.RTN INT$(a) + " Bytes"
 ENDIF
FN.END

FN.DEF HumanTime$(ms)
  IF ms < 1000 THEN FN.RTN INT$(ms) + " ms"
  s = INT(ms / 100) / 10
  IF s < 60 THEN FN.RTN TRIM$(STR$(s)) + " s"
  mn = INT(s / 6) / 10
  FN.RTN TRIM$(STR$(mn)) + " mn"
FN.END

FN.DEF TimeStamp$()
  TIME y$, mo$, d$, h$, mi$, sec$
  FN.RTN y$ + mo$ + d$ + h$ + mi$ + sec$
FN.END

FN.DEF HowLongAgo$(tstamp$)
  now$ = TimeStamp$()
  n = VAL(LEFT$(now$, 4)) : o = VAL(LEFT$(tstamp$, 4)) % Year
  IF n <> o THEN FN.RTN INT$(n-o) + " " + Plural$(LBL$("year"), n-o)
  n = VAL(MID$(now$, 5, 2)) : o = VAL(MID$(tstamp$, 5, 2)) % Month
  IF n <> o THEN FN.RTN INT$(n-o) + " " + Plural$(LBL$("month"), n-o)
  n = VAL(MID$(now$, 7, 2)) : o = VAL(MID$(tstamp$, 7, 2)) % Day
  IF n <> o THEN FN.RTN INT$(n-o) + " " + Plural$(LBL$("day"), n-o)
  n = VAL(MID$(now$, 9, 2)) : o = VAL(MID$(tstamp$, 9, 2)) % Hour
  IF n <> o THEN FN.RTN INT$(n-o) + " " + Plural$(LBL$("hour"), n-o)
  n = VAL(MID$(now$, 11, 2)) : o = VAL(MID$(tstamp$, 11, 2)) % Minute
  IF n <> o THEN FN.RTN INT$(n-o) + " " + Plural$(LBL$("minute"), n-o)
  n = VAL(RIGHT$(now$, 2)) : o = VAL(RIGHT$(tstamp$, 2)) % Second
  FN.RTN INT$(n-o) + " " + Plural$(LBL$("second"), n-o)
FN.END

FN.DEF ext_ico$(file$)
  IF RIGHT$(file$, 1) = "/" THEN FN.RTN "folder.gif"
  i = IS_IN(".", file$, -1)
  IF !i THEN FN.RTN "any.gif" % no extension
  ext$ = LOWER$(MID$(file$, i+1))
  SW.BEGIN ext$
    SW.CASE "bas"
      ico$ = "basic.gif" : SW.BREAK
    SW.CASE "bmp", "gif", "png", "jpg", "jpeg"
      ico$ = "image.gif" : SW.BREAK
    SW.CASE "mp3", "wav", "ogg", "mid", "wma"
      ico$ = "music.gif" : SW.BREAK
    SW.CASE "htm", "html", "js", "css"
      ico$ = "www.gif" : SW.BREAK
    SW.CASE "zip", "rar", "jar", "apk"
      ico$ = "archive.gif" : SW.BREAK
    SW.CASE "avi", "mp4", "mpg", "mpeg", "3gp", "wmv"
      ico$ = "video.gif" : SW.BREAK
    SW.DEFAULT
      ico$ = "any.gif"
  SW.END
  FN.RTN ico$
FN.END

FN.DEF ImgQualiInfo$(ico_siz$[], img$)
  wxh$ = GW_GET_IMAGE_DIM$(img$)
  w = VAL(PARSE$(wxh$, "x", 1))
  h = VAL(PARSE$(wxh$, "x", 1))
  l = MAX(w, h)
  ARRAY.LENGTH al, ico_siz$[]
  quali = 1
  FOR i=al TO 2 STEP -1
    k = IS_IN("x", ico_siz$[i], -1)
    ll = VAL(LEFT$(MID$(ico_siz$[i], k+1), -1))
    IF l >= ll THEN quali = i : F_N.BREAK
  NEXT
  e$ = LBL$("ico_quali") + "<br>" % Icon quality:
  e$ += GW_ADD_IMAGE$("quali" + INT$(quali) + ".png")
  e$ += "<br>" + ico_siz$[quali]
  FN.RTN e$
FN.END

FN.DEF GrSaveAppIcons(ico_siz$[], src_img$, tgt_path$)
  GR.BITMAP.LOAD original, src_img$
  IF original<0 THEN GR.BITMAP.LOAD original, "hold.png"
  GR.BITMAP.SIZE original, w, h
  IF w*h = 0 THEN GR.BITMAP.LOAD original, "hold.png" : GR.BITMAP.SIZE original, w, h
  l = MAX(w, h)
  ARRAY.LENGTH al, ico_siz$[]
  FOR i=1 TO al
    k = IS_IN(">", ico_siz$[i])
    r$ = MID$(ico_siz$[i], k+1) % r$ = resolution (xxxhdpi, xxhdpi... ldpi)
    k = IS_IN("<", r$)
    r$ = LEFT$(r$, k-1)
    k = IS_IN("x", ico_siz$[i], -1)
    ll = VAL(LEFT$(MID$(ico_siz$[i], k+1), -1))
    IF 1 = i | l >= ll % icon is big enough for this resolution (or at least fill lowest resolution slot)
      ratio = MIN(ll/w, ll/h)
      nw = w * ratio
      nh = h * ratio
      GR.BITMAP.SCALE scaled, original, nw, nh, (l>=ll) % antialias is on (smoothing) only if we downscale
      IF nw <> nh % non-square icon -> make it square
        tmp = scaled
        GR.BITMAP.CREATE scaled, ll, ll
        GR.BITMAP.DRAWINTO.START scaled
        GR.BITMAP.DRAW nul, tmp, (ll-nw)/2, (ll-nh)/2
        GR.BITMAP.DRAWINTO.END
        GR.BITMAP.DELETE tmp
      ENDIF
      FILE.MKDIR tgt_path$ + "drawable-" + r$ % create folder for this resolution
      FILE.DELETE fid, tgt_path$ + "drawable-" + r$ + "/icon.png"
      GR.BITMAP.SAVE scaled, tgt_path$ + "drawable-" + r$ + "/icon.png"
      GR.BITMAP.DELETE scaled
    ELSE % icon too small for this resolution -> at least delete old icon
      FILE.DELETE fid, tgt_path$ + "drawable-" + r$ + "/icon.png"
    ENDIF
  NEXT
  GR.BITMAP.DELETE original
FN.END

FN.DEF ColDelta(r1, g1, b1, r2, g2, b2)
  % Delta between 2 colors: returns 0 (same color) to 442 (black Vs. white)
  FN.RTN SQR((r2-r1)^2 + (g2-g1)^2 + (b2-b1)^2)
FN.END

FN.DEF GrSaveNotifyIcon(src_img$, tgt_path$) % res/drawable/classic_notify_icon.png
  GR.BITMAP.LOAD original, src_img$
  IF original<0 THEN GR.BITMAP.LOAD original, "hold.png"
  GR.BITMAP.SIZE original, w, h
  IF w*h = 0 THEN GR.BITMAP.LOAD original, "hold.png" : GR.BITMAP.SIZE original, w, h
  l = MAX(w, h)
  ll = 24 % notification icon is 24x24
  ratio = MIN(ll/w, ll/h)
  nw = w * ratio
  nh = h * ratio
  GR.BITMAP.SCALE scaled, original, nw, nh, (l>=ll) % antialias is on (smoothing) only if we downscale
  IF nw <> nh % non-square icon -> make it square
    tmp = scaled
    GR.BITMAP.CREATE scaled, ll, ll
    GR.BITMAP.DRAWINTO.START scaled
    GR.BITMAP.DRAW nul, tmp, (ll-nw)/2, (ll-nh)/2
    GR.BITMAP.DRAWINTO.END
    GR.BITMAP.DELETE tmp
  ENDIF
  % save classic (colored) icon
  FILE.DELETE fid, tgt_path$ + "drawable/classic_notify_icon.png"
  GR.BITMAP.SAVE scaled, tgt_path$ + "drawable/classic_notify_icon.png"
  % make new material design (detoured white on transparent) icon
  GR.GET.BMPIXEL scaled, 0, 0, a, r1, g1, b1 % assume top left pixel is background color
  GR.COLOR 255, 255, 255, 255 % only use white (material)
  GR.BITMAP.CREATE material, ll, ll
  GR.BITMAP.DRAWINTO.START material
  FOR y=0 TO ll-1
    FOR x=0 TO ll-2
      GR.GET.BMPIXEL scaled, x, y, a, r2, g2, b2
      IF ColDelta(r1,g1,b1, r2,g2,b2) > 0.5*442 THEN GR.POINT nul, x, y
    NEXT
  NEXT
  GR.BITMAP.DRAWINTO.END
  % save material design icon
  FILE.DELETE fid, tgt_path$ + "drawable/notify_icon.png"
  GR.BITMAP.SAVE material, tgt_path$ + "drawable/notify_icon.png"
  % clean-up
  GR.BITMAP.DELETE material
  GR.BITMAP.DELETE scaled
  GR.BITMAP.DELETE original
FN.END

FN.DEF CharBelongsTo(a, scheme$)
  r = 0
  IF IS_IN("az", scheme$) THEN r += (a>=97 & a<=122) : scheme$ = REPLACE$(scheme$, "az", "")
  IF IS_IN("AZ", scheme$) THEN r += (a>=65 & a<=90)  : scheme$ = REPLACE$(scheme$, "AZ", "")
  IF IS_IN("09", scheme$) THEN r += (a>=48 & a<=57)  : scheme$ = REPLACE$(scheme$, "09", "")
  FOR i=1 TO LEN(scheme$)
    r += (a=ASCII(scheme$, i))
  NEXT
  FN.RTN r
FN.END

FN.DEF MakeVersionCode$(ver$)
  e$ = REPLACE$(ver$, ".", "")
  e$ = LTRIM$(e$, "0")
  FN.RTN e$
FN.END

FN.DEF MakeValidVersion$(v$)
  v$ = REPLACE$(v$, "-", "")
  v$ = REPLACE$(v$, " ", "")
  v$ = REPLACE$(v$, ",", ".")
  FN.RTN v$
FN.END

FN.DEF MakePackageName$(app$)
  app$ = ResolveDiacritics$(app$)
  FOR i=1 TO LEN(app$)
    a = ASCII(app$, i)
    IF CharBelongsTo(a, "azAZ09") THEN e$ += CHR$(a)
  NEXT
  IF e$ = "" THEN e$ = "myapp"
  a = ASCII(e$)
  IF (a>=48 & a<=57) THEN e$ = "i" + e$ % prevent starting with 0-9
  FN.RTN "com.rfo." + LOWER$(e$)
FN.END

FN.DEF MakeIntentFilter$(ext$)
  r$ = "            <intent-filter>\n"
  r$+= "                <action android:name=\"android.intent.action.VIEW\" />\n"
  r$+= "                <action android:name=\"android.intent.action.EDIT\" />\n"
  r$+= "                <category android:name=\"android.intent.category.DEFAULT\" />\n"
  r$+= "                <category android:name=\"android.intent.category.BROWSABLE\" />\n"
  r$+= "                <data android:scheme=\"\" />\n"
  r$+= "                <data android:scheme=\"file\" />\n"
  r$+= "                <data android:scheme=\"content\" />\n"
  r$+= "                <data android:scheme=\"http\" />\n"
  r$+= "                <data android:scheme=\"https\" />\n"
  r$+= "                <data android:mimeType=\"*/*\" />\n"
  r$+= "                <data android:mimeType=\"text/*\" />\n"
  r$+= "                <data android:mimeType=\"audio/*\" />\n"
  r$+= "                <data android:mimeType=\"video/*\" />\n"
  r$+= "                <data android:mimeType=\"image/*\" />\n"
  r$+= "                <data android:mimeType=\"application/*\" />\n"
  r$+= "                <data android:host=\"*\" />\n"
  FOR i=1 TO PARSECOUNT(ext$, ",") % for each extension
    x$ = PARSE$(ext$, ",", i)
    r$+= "                <data android:pathPattern=\".*"+CHR$(92,92)+x$+"\" />\n"
  NEXT
  r$+= "            </intent-filter>\n"
  r$+= "\n"
  FN.RTN r$
FN.END

FN.DEF CheckValidAppName(p$)
  v = 1 % valid by default
  FOR i=1 TO LEN(p$)
    c$ = MID$(p$, i, 1)
    IF IS_IN(c$, "|?*<:>/'" + CHR$(34) + CHR$(92)) THEN v = 0 : F_N.BREAK
  NEXT
  IF v = 1 & TRIM$(p$) = "" THEN v = 0 % empty name or only spaces
  FN.RTN v
FN.END

FN.DEF CheckValidVerCode(v$) % must be an integer (Android doc)
  IF 0 = IS_NUMBER(v$) THEN FN.RTN 0
  IF VAL(v$) <> INT(VAL(v$)) THEN FN.RTN 0
  FN.RTN 1
FN.END

FN.DEF CheckValidPackage(p$)
  IF TALLY(p$, ".") <> 2 THEN FN.RTN 0 % must be mm.nn.oo
  v = 1 % valid by default
  FOR i=1 TO 3
    n$ = UPPER$(PARSE$(p$, ".", i))
    a = ASCII(n$)
    IF 0 = CharBelongsTo(a, "AZ") THEN v = 0 : F_N.BREAK % first letter must be alphabetical
    FOR j=2 TO LEN(n$)
      a = ASCII(n$, j)
      IF 0 = CharBelongsTo(a, "AZ09") THEN v = 0 : F_N.BREAK % any other must be alphanumeric
    NEXT
    IF v = 0 THEN F_N.BREAK
  NEXT
  FN.RTN v
FN.END

FN.DEF CheckValidExtensions(e$)
  e$ = REPLACE$(UPPER$(e$), " ", "")
  v = 1 % valid by default
  FOR i=1 TO PARSECOUNT(e$, ",") % for each extension
    x$ = PARSE$(e$, ",", i)
    IF LEFT$(x$, 1) <> "." THEN FN.RTN 0
    FOR j=2 TO LEN(x$)
      IF 0 = CharBelongsTo(ASCII(x$, j), "AZ09") THEN v = 0 : F_N.BREAK % extension must be alphanumeric
    NEXT
    IF v=0 THEN F_N.BREAK
  NEXT
  FN.RTN v
FN.END

FN.DEF STOP(msg$)
  CLIPBOARD.PUT msg$
  BUNDLE.GET 1, "err_tx", err_tx
  GW_MODIFY(err_tx, "text", "<b>" + msg$ + "</b>")
  GW_WAIT_ACTION$()
  EXIT
FN.END

FN.DEF PermStr$(p$)
  e$  = "<uses-permission android:name="
  e$ += CHR$(34) + "android.permission."
  e$ += MID$(p$, 4) + CHR$(34) + " />\n"
  FN.RTN e$
FN.END

FN.DEF ReadTextFileTillComment(fid, cmt$)
  IF fid<0 THEN FN.RTN 0
  DO
    TEXT.READLN fid, e$
  UNTIL IS_IN(cmt$, e$) | e$="EOF"
FN.END

FN.DEF ReadNumberFrom(fid)
  TEXT.READLN fid, e$
  i = IS_IN("%", e$)
  IF i THEN e$ = TRIM$(LEFT$(e$, i-1))
  IF !IS_NUMBER(e$) THEN e$="0"
  FN.RTN VAL(e$)
FN.END

FN.DEF GetStrFromComment$(buf$, cmt$)
  j = IS_IN(cmt$, buf$)
  IF --j<0 THEN FN.RTN ""
  i = IS_IN(CHR$(10), buf$, j-LEN(buf$))
  IF i=0 THEN i=1 % cmt$ is on first line
  ii = IS_IN(CHR$(13), buf$, j-LEN(buf$))
  IF ii>i THEN i=ii
  FN.RTN TRIM$(MID$(buf$, i+1, j-i-1))
FN.END

FN.DEF GetNbFromComment(buf$, cmt$)
  e$ = GetStrFromComment$(buf$, cmt$)
  IF !IS_NUMBER(e$) THEN e$="0"
  FN.RTN VAL(e$)
FN.END

FN.DEF GetProjectTimestamp(proj$)
  TEXT.OPEN r, fid, proj$
  TEXT.READLN fid, e$
  TEXT.CLOSE fid
  FN.RTN VAL(e$)
FN.END

FN.DEF GetProjectIcon$(proj$)
  GRABFILE buf$, proj$
  appbas$ = GetStrFromComment$(buf$, "% main .bas")
  FILE.EXISTS fid, "../../rfo-basic/source/" + appbas$
  IF 0 = fid THEN FN.RTN "nobas.png"
  appico$ = GetStrFromComment$(buf$, "% app icon")
  FILE.EXISTS fid, appico$
  IF 0 = fid THEN FN.RTN "noico.png"
  FN.RTN appico$
FN.END

FN.DEF GetProjectHeader$(proj$)
  apptim$ = INT$(GetProjectTimestamp(proj$))
  GRABFILE buf$, proj$
  appbas$ = GetStrFromComment$(buf$, "% main .bas")
  appnam$ = GetStrFromComment$(buf$, "% app name")
  appver$ = GetStrFromComment$(buf$, "% app version name")
  apppkg$ = GetStrFromComment$(buf$, "% app package name")
  pk$ = apppkg$ : IF LEN(pk$) > 22 THEN pk$ = LEFT$(pk$, 21) + "..."
  e$  = "<small>" + REPLACE$(LBL$("last_edit"), "XXX", HowLongAgo$(apptim$)) + "</small><hr>" % Last edited N hours ago.
  e$ += "<b><i>" + appnam$ + "</i></b> v<i>" + appver$ + "</i><br>"
  e$ += "<i>(" + pk$ + ")</i><br>"
  e$ += LBL$("using") + " " + CHR$(34) + appbas$ + CHR$(34)
  FN.RTN e$
FN.END

FN.DEF ResolveDiacritics$(e$)
  e$ = REPLACE$(e$, "&", "") % remove ampersands (creates havoc in XMLs & Linux shells)
  JS("removeDiacritics(" + CHR$(34) + e$ + CHR$(34) + ")")
  FN.RTN GW_WAIT_ACTION$()
FN.END

FN.DEF DEGUB(e$)
  TIME y$, m$, d$, h$, mn$, s$
  t$="["+y$+m$+d$+"-"+h$+mn$+s$+"] "+e$
  TEXT.OPEN a, fid, "../Compiler.log"
  TEXT.WRITELN fid, t$
  TEXT.CLOSE fid
FN.END

FN.DEF CopyClassFromLibTo(jar$, class$, dest$)
  ZIP.OPEN r, zid, jar$
  IF zid<0 THEN FN.RTN -1
  IF IS_IN("*", class$) % copy multiple classes
    mask$ = REPLACE$(class$, ".", "/")
    mask$ = REPLACE$(mask$, "*", "")
    ZIP.DIR jar$, zip$[], "/"
    ARRAY.LENGTH nzip, zip$[]
    DIM class$[nzip]
    FOR i=1 TO nzip
      IF RIGHT$(zip$[i],1) = "/" THEN F_N.CONTINUE % skip folders
      IF IS_IN(mask$, zip$[i]) THEN class$[++nclass] = zip$[i]
    NEXT
  ELSE                  % copy a single class
    ARRAY.LOAD class$[], REPLACE$(class$,".","/") + ".class"
    nclass = 1
  ENDIF
  FOR i=1 TO nclass
    ZIP.READ zid, buf$, class$[i]
    IF buf$="EOF" | buf$="" THEN F_N.CONTINUE
    tgt_folder$ = class$[i]
    tgt_folder$ = LEFT$(tgt_folder$, IS_IN("/",tgt_folder$,-1))
    tgt_folder$ = dest$ + tgt_folder$
    MakeRecursivePath(tgt_folder$)
    tgt_file$ = tgt_folder$ + MID$(class$[i], IS_IN("/",class$[i],-1)+1)
    PutFile(buf$, tgt_file$)
  NEXT
  ZIP.CLOSE zid
FN.END
