% This is the INCLUDE file "utils_str.bas" for RFO-BASIC! available under the terms of a GNU GPL V3 license.
% It contains useful functions to handle strings. Download at http://laughton.com/basic/programs/utilities/mougino
%
% nb = TALLY(main$, sub$)
%     - return the number of occurence of sub$ inside main$
% a$ = BUILD$(e$, n)
%     - return a string composed of n occurences of e$
% nb = PARSECOUNT(main$, sep$)
%     - return the number of delimited fields of the string main$ split on the delimiter sep$
%     - e.g. PARSECOUNT("a/b/c", "/") returns 3
% a$ = PARSE$(main$, sep$, n)
%     - return the delimited field #n of the string main$ split on the delimiter sep$
%     - e.g. PARSE$("a/b/c", "/", 2) returns "b"
% a$ = InsertBefore$(buf$, where$, ins$)
%     - return a string with ins$ inserted in buf$ before the first occurence of where$ (search is case insensitive)
% a$ = InsertAfter$(buf$, where$, ins$)
%     - return a string with ins$ inserted in buf$ after the first occurence of where$ (search is case insensitive)
% a$ = Isolate$(buf$, chunk$)
%     - return the first substring inside buf$ containing chunk$ delimited by 2 end-of-line characters
%     - e.g. Isolate$("abc \n def \n hij", "e") will return " def "
% a$ = UtfProtect$(e$)
%     - return a text with its Unicode characters protected. e.g. UtfProtect$("Menü") will return "Men&#252;"
% a$ = InBetween$(buf$, a$, b$)
%     - return the substring comprised between occurences of a$ and b$
%     - e.g. InBetween$("abc<def>ghi", "<", ">") will return "def"
% a$ = IIF$(condition, true$, false$)
%     - return true$ if condition is true, false$ otherwise

FN.DEF TALLY(main$, sub$)
  i=IS_IN(sub$, main$)
  WHILE i
    n++
    i=IS_IN(sub$, main$, i+1)
  REPEAT
  FN.RTN n
FN.END

FN.DEF BUILD$(e$, n)
  DIM tmp$[n+1]
  JOIN.ALL tmp$[], r$, e$
  FN.RTN r$
FN.END

FN.DEF PARSECOUNT(main$, sep$)
  FN.RTN TALLY(TRIM$(main$, sep$), sep$) + 1
FN.END

FN.DEF PARSE$(main$, sep$, n)
  main$ = sep$ + TRIM$(main$, sep$) + sep$
  FOR k=1 TO n
    i=IS_IN(sep$, main$, i+1)
  NEXT
  IF !i THEN FN.RTN ""
  j=IS_IN(sep$, main$, i+1)
  IF !j THEN FN.RTN ""
  FN.RTN MID$(main$, i+1, j-i-1)
FN.END

FN.DEF InsertBefore$(buf$, where$, ins$)
    nbuf$ = buf$
    p = IS_IN(LOWER$(where$), LOWER$(buf$))
    IF p THEN nbuf$ = LEFT$(nbuf$, p-1) + ins$ + MID$(nbuf$, p)
    FN.RTN nbuf$
FN.END

FN.DEF InsertAfter$(buf$, where$, ins$)
    nbuf$ = buf$
    p = IS_IN(LOWER$(where$), LOWER$(buf$))
    IF p THEN p += LEN(where$) : nbuf$ = LEFT$(nbuf$, p) + ins$ + MID$(nbuf$, p+1)
    FN.RTN nbuf$
FN.END

FN.DEF Isolate$(buf$, chunk$)
  p = IS_IN(LOWER$(chunk$), LOWER$(buf$))
  IF p
    i = IS_IN("\n", buf$, p - LEN(buf$))
    IF i > 0
      j = IS_IN("\n", buf$, p)
      IF j > 0 THEN FN.RTN MID$(buf$, i+1, j-i-1)
    END IF
  END IF
FN.END

FN.DEF UtfProtect$(e$)
  e$ = REPLACE$(e$, "&", "&amp;")
  FOR i=1 TO LEN(e$)
    a = ASCII(e$, i)
    IF a <= 128
      a$ += CHR$(a)
    ELSE
      a$ += "&#" + INT$(a) + ";"
    END IF
  NEXT
  FN.RTN a$
FN.END

FN.DEF InBetween$(buf$, a$, b$)
  i = IS_IN(a$, buf$)
  IF 0=i THEN FN.RTN ""
  j = IS_IN(b$, buf$, -1)
  IF j<i THEN FN.RTN ""
  FN.RTN MID$(buf$, i+1, j-i-1)
FN.END

FN.DEF IIF$(condition, true$, false$)
  IF condition THEN FN.RTN true$ ELSE FN.RTN false$
FN.END