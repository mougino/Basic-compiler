% This is the INCLUDE file "utils_xml.bas" for RFO-BASIC! available under the terms of a GNU GPL V3 license.
% It contains useful functions to handle XML. Download at http://laughton.com/basic/programs/utilities/mougino
%
% a$ = XmlNextTag$ (&buffer$)
%     - extract the first <tag attribute="inline_value"> from a buffer
%     - buffer$ needs to be called by reference: tag$ = XmlNextTag$(&buffer$)
% a$ = XmlContent$ (buffer$, tag$)
%     - retrieve 'content' from   <tag attribute="inline_value"> content </tag>
%     - hint: you can specify a 'tag' to be searched for, or a 'tag attribute'
% ReplaceXmlContentWith (&buffer$, tag$, newcontent$)
%     - replace 'content' with 'newcontent' in   <tag attribute="inline_value"> content </tag>
%     /or/ transform a   <tag attribute='inline_value' />   into a   <tag attribute='inline_value' > newcontent </tag>
%     - hint: you can specify a 'tag' to be searched for, or a 'tag attribute'
%     - buffer$ needs to be called by reference: ReplaceXmlContentWith (&buffer$, ...)
% a$ = InlineContent$ (buffer$, param$)
%     - retrieve 'inline_value' from    <tag attribute="inline_value"> content </tag>
%       or from   <tag attribute='inline_value' />
% ReplaceInlineContentWith (&buffer$, param$, newvalue$)
%     - replace 'inline_value' with 'newvalue' in first occurence of   <tag attribute="inline_value"> content </tag>
%       or first occurence of   <tag attribute="inline_value" />
%     - buffer$ needs to be called by reference: ReplaceInlineContentWith (&buffer$, ...)
% ReplaceInlineContentAfterTagWith (&buffer$, tag$, param$, newvalue$)
%     - replace 'inline_value' with 'newvalue' in   <tag attribute="inline_value"> content </tag>
%       or in   <tag attribute="inline_value" />
%     - buffer$ needs to be called by reference: ReplaceInlineContentAfterTagWith (&buffer$, ...)
% ReplaceXmlTagWith (&buffer$, tag$, newtag$)
%     - replace <tag attribute='inline_value' />   with   <newtag$ attribute='inline_value' />
%       or  <tag attribute="inline_value"> content </tag>   with   <newtag$ attribute="inline_value"> content </newtag>
%     - hint: you can specify a 'tag' to be searched for, or a 'tag attribute'
%     - buffer$ needs to be called by reference: ReplaceXmlTagWith (&buffer$, ...)
% DeleteFirstXmlTag (&buffer$, tag$, contains$)
%     - remove first occurence of <tag attribute="inline_value" /> 
%       or of  <tag attribute="inline_value"> content </tag>
%       that contains the string 'contains' (insensitive case research)
%     - return 1 if successful, 0 if not
%     - hint: you can specify a 'tag' to be searched for, or a 'tag attribute'
%     - buffer$ needs to be called by reference: DeleteFirstXmlTag (&buffer$, ...)

FN.DEF XmlNextTag$ (buffer$)
    i = IS_IN("<", buffer$)
    IF i = 0 THEN
        buffer$ = ""
    ELSE
        j = IS_IN(">", buffer$, i)
        IF j = 0 THEN
            buffer$ = ""
        ELSE
            tag$ = MID$(buffer$, i, j-i+1)
            buffer$ = MID$(buffer$, j+1)
            FN.RTN tag$
        ENDIF
    ENDIF
FN.END

FN.DEF XmlContent$ (buffer$, tag$)
    i = IS_IN("<" + LOWER$(tag$), LOWER$(buffer$))
    IF i = 0 THEN FN.RTN "" % opening tag not found

    IF IS_IN(" ", tag$) = 0 THEN % find closing tag (ct$)
      ct$ = "</" + tag$  + ">"
    ELSE
      ct$ = "</" + LEFT$(tag$, IS_IN(" ", tag$) - 1) + ">"
    END IF

    i += LEN(tag$) + 1
    j = IS_IN("/>", buffer$, i)
    i = IS_IN(">", buffer$, i)

    IF i = j+1 THEN FN.RTN "" % <tag attribute='inline_value' />   --> tag has no content

    i += 1
    j = IS_IN(LOWER$(ct$), LOWER$(buffer$), i)
    IF j = 0 THEN FN.RTN "" % closing tag not found

    FN.RTN MID$(buffer$, i, j-i)
FN.END

FN.DEF ReplaceXmlContentWith (buffer$, tag$, newcontent$)
    i = IS_IN("<" + LOWER$(tag$), LOWER$(buffer$))
    IF i = 0 THEN FN.RTN 0 % opening tag not found

    IF IS_IN(" ", tag$) = 0 THEN % find closing tag (ct$)
      ct$ = "</" + tag$  + ">"
    ELSE
      ct$ = "</" + LEFT$(tag$, IS_IN(" ", tag$) - 1) + ">"
    END IF

    i += LEN(tag$) + 1
    j = IS_IN("/>", buffer$, i)
    i = IS_IN(">", buffer$, i)

    IF i = j + 1 THEN % <tag attribute='inline_value' />   --> tag found but has no content initialy  --> create it
        buffer$ = LEFT$(buffer$, j-1) + ">" + newcontent$ + ct$ + MID$(buffer$, j+2)
    ELSE
        i += 1
        j = IS_IN(LOWER$(ct$), LOWER$(buffer$), i)
        IF j <> 0 THEN buffer$ = LEFT$(buffer$, i-1) + newcontent$ + MID$(buffer$, j) % closing tag found --> replace content
    END IF
FN.END

FN.DEF InlineContent$ (buffer$, param$)
    t$ = "=" + CHR$(34)
    i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))              % double quote, no space around equal sign
    IF i = 0 THEN
        t$ = "='"
        i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))          % simple quote, no space around equal sign
        IF i = 0 THEN
            t$ = " = " + CHR$(34)
            i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))      % double quote, spaces around equal sign
            IF i = 0 THEN
                t$ = " = '"
                i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))  % simple quote, spaces around equal sign
            END IF
        END IF
    END IF
    IF i = 0 THEN FN.RTN "" % attribute not found

    i += LEN(param$ + t$)
    j = IS_IN(RIGHT$(t$, 1), LOWER$(buffer$), i)
    IF j = 0 THEN FN.RTN "" % closing quote not found

    FN.RTN MID$(buffer$, i, j-i)
FN.END

FN.DEF ReplaceInlineContentWith (buffer$, param$, newvalue$)
    t$ = "=" + CHR$(34)
    i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))              % double quote, no space around equal sign
    IF i = 0 THEN
        t$ = "='"
        i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))          % simple quote, no space around equal sign
        IF i = 0 THEN
            t$ = " = " + CHR$(34)
            i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))      % double quote, spaces around equal sign
            IF i = 0 THEN
                t$ = " = '"
                i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$))  % simple quote, spaces around equal sign
            END IF
        END IF
    END IF
    IF i = 0 THEN FN.RTN 0 % attribute not found

    i += LEN(param$ + t$)
    j = IS_IN(RIGHT$(t$, 1), LOWER$(buffer$), i)
    IF j = 0 THEN FN.RTN 0 % closing quote not found

    buffer$ = LEFT$(buffer$, i-1) + newvalue$ + MID$(buffer$, j)
FN.END

FN.DEF ReplaceInlineContentAfterTagWith (buffer$, tag$, param$, newvalue$)
    k = IS_IN(LOWER$(tag$), LOWER$(buffer$))
    IF k = 0 & IS_IN("'", tag$) > 0 & IS_IN(CHR$(34), tag$) = 0 THEN
        k = IS_IN(LOWER$(REPLACE$(tag$, "'", CHR$(34))), LOWER$(buffer$))
    ELSEIF k = 0 & IS_IN("'", tag$) = 0 & IS_IN(CHR$(34), tag$) > 0 THEN
        k = IS_IN(LOWER$(REPLACE$(tag$, CHR$(34), "'")), LOWER$(buffer$))
    ENDIF
    IF k = 0 THEN FN.RTN 0 % tag not found

    t$ = "=" + CHR$(34)
    i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$), k)              % double quote, no space around equal sign
    IF i = 0 THEN
        t$ = "='"
        i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$), k)          % simple quote, no space around equal sign
        IF i = 0 THEN
            t$ = " = " + CHR$(34)
            i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$), k)      % double quote, spaces around equal sign
            IF i = 0 THEN
                t$ = " = '"
                i = IS_IN(LOWER$(param$) + t$, LOWER$(buffer$), k)  % simple quote, spaces around equal sign
            END IF
        END IF
    END IF
    IF i = 0 THEN FN.RTN 0 % attribute not found

    j = IS_IN(">", buffer$, k)
    IF j < i THEN FN.RTN 0 % attribute outside of scope of tag$ (e.g. <tag ... /> <other_incorrect_tag  attribute_we_are_looking_for...>

    i += LEN(param$ + t$)
    j = IS_IN(RIGHT$(t$, 1), LOWER$(buffer$), i)
    IF j = 0 THEN FN.RTN 0 % closing quote not found

    buffer$ = LEFT$(buffer$, i-1) + newvalue$ + MID$(buffer$, j)
FN.END

FN.DEF ReplaceXmlTagWith (buffer$, tag$, newtag$)
    i = IS_IN("<" + LOWER$(tag$), LOWER$(buffer$))
    IF i = 0 THEN FN.RTN 0 % opening tag not found

    IF IS_IN(" ",    tag$) = 0 THEN  ct$ = "</" +    tag$ + ">" ELSE  ct$ = "</" + LEFT$(   tag$, IS_IN(" ",    tag$) - 1) + ">" % closing tag
    IF IS_IN(" ", newtag$) = 0 THEN cnt$ = "</" + newtag$ + ">" ELSE cnt$ = "</" + LEFT$(newtag$, IS_IN(" ", newtag$) - 1) + ">" % closing newtag$

    m = i + LEN(tag$) + 1
    j = IS_IN("/>", buffer$, m)
    k = IS_IN(">", buffer$, m)

    IF k = j + 1 THEN  % <tag attribute='inline_value' />   --> tag without content --> do a single replace 
        buffer$ = LEFT$(buffer$, i) + newtag$ + MID$(buffer$, m)
    ELSE
        buffer$ = LEFT$(buffer$, i) + newtag$ + MID$(buffer$, m)
        j = IS_IN(LOWER$(ct$), LOWER$(buffer$), m)
        IF j <> 0 THEN buffer$ = LEFT$(buffer$, j-1) + cnt$ + MID$(buffer$, j + LEN(ct$)) % tag$ with content --> do a double replace (opening & closing tags)
    END IF
FN.END

FN.DEF DeleteFirstXmlTag (buffer$, tag$, contains$)
    Loop:
    i = IS_IN("<" + LOWER$(tag$), LOWER$(buffer$), i + 1)
    IF i = 0 THEN FN.RTN 0 % opening tag not found

    IF IS_IN(" ", tag$) = 0 THEN % find closing tag (ct$)
      ct$ = "</" + tag$  + ">"
    ELSE
      ct$ = "</" + LEFT$(tag$, IS_IN(" ", tag$) - 1) + ">"
    END IF

    m = i + LEN(tag$) + 1
    j = IS_IN("/>", buffer$, m)
    k = IS_IN(">", buffer$, m)

    IF k = j + 1 THEN  % <tag attribute='inline_value' />   --> tag without content
        IF LEN(contains$) > 0 THEN
            IF IS_IN(LOWER$(contains$), LOWER$(MID$(buffer$, i, k-i+1))) = 0 THEN GOTO Loop % tag doesn't contain string 'contains'
        ENDIF
        IF MID$(buffer$, k + 1, 1) = "\n" THEN k += 1
        IF MID$(buffer$, k + 2, 1) = "\n" THEN k += 2
        buffer$ = LEFT$(buffer$, i - 1) + MID$(buffer$, k + 1)
        FN.RTN 1
    ELSE
        j = IS_IN(LOWER$(ct$), LOWER$(buffer$), m)
        IF j <> 0 THEN
            IF LEN(contains$) > 0 THEN
                IF IS_IN(LOWER$(contains$), LOWER$(MID$(buffer$, i, j-i+1))) = 0 THEN GOTO Loop % tag doesn't contain string 'contains'
            ENDIF
            IF MID$(buffer$, k + 1, 1) = "\n" THEN k += 1
            IF MID$(buffer$, k + 2, 1) = "\n" THEN k += 2
            buffer$ = LEFT$(buffer$, i - 1) + MID$(buffer$, j + LEN(ct$)) % tag with content
            FN.RTN 1
        ENDIF
    END IF
    FN.RTN 0
FN.END

