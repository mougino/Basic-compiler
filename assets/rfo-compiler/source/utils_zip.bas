% This is the INCLUDE file "utils_zip.bas" for RFO-BASIC! available under the terms of a GNU GPL V3 license.
% It contains useful functions to handle zip files. Download at http://laughton.com/basic/programs/utilities/mougino
%
% UnzipTo(zip$, tgt_path$)
%     - unzip the zip file located at zip$ into the target folder tgt_path$. if tgt_path$ doesn't exist it is created
% ZipFrom(src_path$, list, zip$, keep_root_folder)
%     - zip all recursive files and folders inside src_path$ into the file zip$. if zip$ existed it is overwritten
%     - user must provide a string list as second parameter to hold the list of files and folders to zip
%     - if keep_root_folder is true (non zero) the root folder src_path$ is kept in the zip file

INCLUDE "utils_file.bas" % some of the functions below need functions defined in "utils_file.bas"

FN.DEF UnzipTo(zip$, tgt_path$)
  IF RIGHT$(tgt_path$, 1) <> "/" THEN tgt_path$ += "/"
  MakeRecursivePath(tgt_path$) % create target folder if it doesn't exist
  ZIP.OPEN r, fid, zip$
  IF fid < 0 THEN FN.RTN 0 % failed opening the zip
  ZIP.DIR zip$, all$[], "/" % list content of the zip
  ARRAY.LENGTH nfiles, all$[]
  FOR i=1 TO nfiles
    IF RIGHT$(all$[i], 1) = "/" THEN F_N.CONTINUE % skip folders
    ZIP.READ fid, buf$, all$[i]
    IF buf$ <> "EOF" THEN PutFile(buf$, tgt_path$ + all$[i])
  NEXT
  ZIP.CLOSE fid
  FN.RTN 1
FN.END

FN.DEF ZipFrom(src_path$, list, zip$, keep_root_folder)
  i = IS_IN("/", zip$, -1) % create target folder if it doesn't exist
  IF i THEN MakeRecursivePath(LEFT$(zip$, i))
  IF RIGHT$(src_path$, 1) <> "/" THEN src_path$ += "/"
  LIST.CLEAR list
  RecursiveDir(src_path$, list)
  LIST.SIZE list, nfiles
  ZIP.OPEN w, fid, zip$
  IF fid < 0 THEN FN.RTN 0 % failed creating the zip
  FOR i=1 TO nfiles
    LIST.GET list, i, file$
    IF RIGHT$(file$, 1) = "/" THEN F_N.CONTINUE % skip folders
    buf$ = GetFile$(file$)
    IF !keep_root_folder THEN file$ = MID$(file$, LEN(src_path$)+1)
    uncompressed = IS_IN("assets/",file$) + IS_IN(".arsc",file$)
    ZIP.WRITE fid, buf$, file$, uncompressed
  NEXT
  ZIP.CLOSE fid
  FN.RTN 1
FN.END
