% This is the INCLUDE file "utils_file.bas" for RFO-BASIC! available under the terms of a GNU GPL V3 license.
% It contains useful functions to handle files. Download at http://laughton.com/basic/programs/utilities/mougino
%
% PutFile(buf$, path$)
%     - put the binary string buf$ inside the file at path$. if the file already exists, it is overwritten
% buf$ = GetFile$(path$)
%     - return the content (binary string) of the file at path$
% lof = GetSize(path$)
%     - return the size in bytes of the file at path$ or -1 if it doesn't exist
% FileCopy(src$, tgt$)
%     - copy the source file at src$ to the destination file 'tgt$'. both paths are relative to rfo-basic/data
% test = SysExist(fileName$)
%     - return 1 if the file named fileName$ exists in /data/data/com.rfo.compiler/ or 0 otherwise
% RecursiveDir(path$, list)
%     - list recursively the files and folders inside path$. put the result into the string list 'list'
% MakeRecursivePath(path$)
%     - recursively create the folder tree starting in rfo-basic/data and up to path$
%     - e.g. MakeRecursivePath("a/b/c") will create rfo-basic/data/a/b/c/
% DelRecursivePath(path$, list, del_root_too)
%     - recursively delete the files and folders inside path$
%     - user must provide a string list as second parameter to hold the list of files and folders to delete
%     - if del_root_too is true (non zero) the root folder at path$ is also deleted
% CopyFromDataToSys(prog$)
%     - copy the file named prog$ from FILE.ROOT to /data/data/com.rfo.compiler/
% GrantExecPerm(prog$)
%     - give the execution permission (555) to the file named prog$ inside /data/data/com.rfo.compiler/
% name$ = FileName$(file$)
%     - return the file name from a full file path + name, e.g. "file.ext" from "abc/def/ghi/file.ext"
% path$ = FilePath$(file$)
%     - return the file path from a full file path + name, e.g. "abc/def/ghi/ from "abc/def/ghi/file.ext"
% ReplaceInFile(file$, old$, new$)
%     - replace the string old$ with new$ in file$ (path is relative to rfo-basic/data)
% protected_path$ = DQ$(original_path$)
%     - protect a path with a double quote if it contains spaces
% result = IsPresentInApk(file_path$)
%     - returns 1 if file is present in APK, 0 otherwise

INCLUDE "utils_str.bas" % some of the functions below need functions defined in "utils_str.bas"

FN.DEF PutFile(buf$, path$)
  i = IS_IN("/", path$, -1) % create target folder if it doesn't exist
  IF i THEN MakeRecursivePath(LEFT$(path$, i))
  BYTE.OPEN w, bid, path$
  BYTE.WRITE.BUFFER bid, buf$
  BYTE.CLOSE bid
FN.END

FN.DEF GetFile$(path$)
  BYTE.OPEN r, bid, path$
  IF bid < 0 THEN FN.RTN "" % cannot open file
  FILE.SIZE lof, path$
  BYTE.READ.BUFFER bid, lof, buf$
  BYTE.CLOSE bid
  FN.RTN buf$
FN.END

FN.DEF GetSize(path$)
  BYTE.OPEN r, bid, path$
  IF bid < 0 THEN FN.RTN -1 % cannot open file
  FILE.SIZE lof, path$
  BYTE.CLOSE bid
  FN.RTN lof
FN.END

FN.DEF FileCopy(src$, tgt$)
  i = IS_IN("/", tgt$, -1) % create target folder if it doesn't exist
  IF i THEN MakeRecursivePath(LEFT$(tgt$, i))
  BYTE.OPEN r, fid, src$
  IF fid < 0 THEN FN.RTN 0
  BYTE.COPY fid, tgt$
  FN.RTN 1
FN.END

FN.DEF SysExist(fileName$)
  sys$ = SYSPATH$() % "/data/data/com.rfo.compiler/"
  bsys$ = "../../../../../../.." + sys$
  IF LEFT$(fileName$,1) = "+" THEN fileName$ = MID$(fileName$,2)
  FILE.EXISTS ex, bsys$ + fileName$
  FN.RTN ex
FN.END

FN.DEF RecursiveDir(path$, list)
  IF RIGHT$(path$, 1) <> "/" THEN path$ += "/"
  FILE.DIR path$, all$[], "/"
  ARRAY.LENGTH al, all$[]
  IF al <= 0 THEN FN.RTN 0
  % New: sort files alphabetically, regardless of case
  FOR i=1 TO al
    FOR j=i+1 TO al
      IF LOWER$(all$[j]) < LOWER$(all$[i])
        SWAP all$[j], all$[i]
      ENDIF
    NEXT
  NEXT
  % Recurse if there are folders
  FOR i=1 TO al
    IF RIGHT$(all$[i], 1) = "/" THEN
      LIST.ADD list, path$ + all$[i]
      RecursiveDir(path$ + all$[i], list) %' it's a folder
    ELSE
      LIST.ADD list, path$ + all$[i] %' it's a file
    ENDIF
  NEXT
  FN.RTN 1
FN.END

FN.DEF MakeRecursivePath(path$)
  path$ = TRIM$(path$, "/") + "/"
  FOR i=1 TO TALLY(path$, "/")
    cpath$ += PARSE$(path$, "/", i) + "/"
    FILE.MKDIR cpath$
  NEXT
FN.END

FN.DEF DelRecursivePath(path$, list, del_root_too)
  path$ = RTRIM$(path$, "/")
  FILE.EXISTS ok, path$
  IF 0=ok THEN FN.RTN 0
  LIST.CLEAR list
  RecursiveDir(path$, list)
  LIST.SIZE list, nfiles
  FOR i=nfiles TO 1 STEP -1
    LIST.GET list, i, file$
    FILE.DELETE fid, RTRIM$(file$, "/")
  NEXT
  IF del_root_too THEN FILE.DELETE fid, path$
  FN.RTN 1
FN.END

FN.DEF CopyFromDataToSys(prog$)
  FILE.ROOT data$ : data$ += "/"
  sys$ = SYSPATH$() % "/data/data/com.rfo.compiler/"
  SHELL("cat " + DQ$(data$ + prog$) + " > " + DQ$(sys$ + prog$))
FN.END

FN.DEF GrantExecPerm(prog$)
  sys$ = SYSPATH$() % "/data/data/com.rfo.compiler/"
  SHELL("chmod 555 " + sys$ + prog$)
FN.END

FN.DEF FileName$(file$)
  i = IS_IN("/", file$, -1)
  IF i THEN FN.RTN MID$(file$, i+1) ELSE FN.RTN file$
FN.END

FN.DEF FilePath$(file$)
  i = IS_IN("/", file$, -1)
  IF i THEN FN.RTN LEFT$(file$, i)
FN.END

FN.DEF ReplaceInFile(file$, old$, new$)
  GRABFILE buf$, file$
  buf$ = REPLACE$(buf$, old$, new$)
  PutFile(buf$, file$)
FN.END

FN.DEF DQ$(path$)
  IF IS_IN(" ", path$)
    FN.RTN CHR$(34) + path$ + CHR$(34)
  ELSE
    FN.RTN path$
  ENDIF
FN.END

FN.DEF IsPresentInApk(file_path$)
  BYTE.OPEN r, isThere, file_path$
  IF (++isThere) THEN BYTE.CLOSE (isThere-1)
  FN.RTN isThere
FN.END
