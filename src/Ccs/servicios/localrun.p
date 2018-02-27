/*------------------------------------------------------------------------
    File        : Ccs.servicios.localrun.p
    Purpose     : Set ups the environment for local run of NSRA through CCS for development/testing.

    Syntax      :

    Description : Check database connections.

    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Fri Feb 16 18:34:11 ART 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/*
conexion a bases necesarias para todos los servicios
--
database connections required by the application as a whole
*/
IF OPSYS="UNIX" THEN DO:
 IF NOT CONNECTED("nsradb") THEN CONNECT /sistemas/dbs/nsra/nsra -ld nsradb.
 IF NOT CONNECTED("compras") THEN CONNECT /sistemas/dbs/nsra/compras -ld compras.
END.
IF OPSYS="WIN32" THEN DO:
 IF NOT CONNECTED("nsradb") THEN CONNECT "C:\Users\nomade\Progress\Developer Studio 4.3.1\workspace\ccs_test\dbs\nsra" -ld nsradb.
 IF NOT CONNECTED("compras") THEN CONNECT "C:\Users\nomade\Progress\Developer Studio 4.3.1\workspace\ccs_test\dbs\compras"  -ld compras.
END.

/* ********************  Preprocessor Definitions  ******************** */
FUNCTION GetTime RETURNS CHARACTER (INPUT ipinMSegs AS INTEGER):
  DEFINE VARIABLE segs AS INTEGER     NO-UNDO.
  DEFINE VARIABLE mins AS INTEGER     NO-UNDO.

  segs = TRUNCATE(ipinMSegs / 1000,0).
  ipinMSegs = ipinMSegs - segs * 1000.
  mins = TRUNCATE(segs / 60,0).
  segs = segs - mins * 60.
  RETURN STRING(mins) + ':' + STRING(segs) + ':' + STRING(ipinMSegs).
END FUNCTION.


/* ***************************  Main Block  *************************** */
RUN Ccs/servicios/iniagntCCS.p.

DISPLAY "Entorno inicializado.. (Environment initialized)" SKIP.
DISPLAY SKIP "-- ap y cte vacios para finalizar (ap and cte empty to end session) --".

DEFINE VARIABLE xml AS CHARACTER LABEL 'ap:'NO-UNDO.
DEFINE VARIABLE runit AS CHARACTER LABEL 'cte:' NO-UNDO.
DEFINE VARIABLE tiempo AS CHARACTER   NO-UNDO.
DEFINE VARIABLE finalizar AS LOGICAL     NO-UNDO.
DEFINE STREAM lstOutput.

DO WHILE TRUE:
  CLEAR FRAME a NO-PAUSE.
  CLEAR FRAME b NO-PAUSE.
  CLEAR FRAME c NO-PAUSE.
  DISPLAY 'archivo de protocolo sin extensión (protocol file without extension)' SKIP WITH FRAME a.
  DISPLAY '-- debe ser .in y estar en nsra/servicios/inout/' SKIP '   (must be .in and located in nsra/servicios/inout/) --' SKIP WITH FRAME a. 
  UPDATE xml FORMAT "X(30)" WITH FRAME a.
  DISPLAY 'ruta a .p a ejecutar (path to .p to run)' WITH FRAME b.
  DISPLAY '-- ruta completa desde la raiz NSRA (full path from NSRA root dir) --' WITH FRAME b.
  UPDATE runit FORMAT "X(60)" WHEN LENGTH(TRIM(xml)) EQ 0 WITH FRAME b.
  IF LENGTH(TRIM(xml))EQ 0 AND LENGTH(TRIM(runit))EQ 0 THEN DO:
    MESSAGE '¿Salir? (Exit?)' VIEW-AS ALERT-BOX QUESTION BUTTONS YES-NO UPDATE finalizar.
    IF finalizar THEN
      LEAVE.
  END.
  DISPLAY "-- Ejecutando --" WITH FRAME c.
  ETIME(TRUE).
  IF LENGTH(xml) > 0 THEN DO ON ERROR UNDO, THROW:
    Ccs.utiles.Application:Protocol:PrepareParse(xml).
    Ccs.utiles.Application:Protocol:Parse(?).
    Ccs.utiles.Application:Protocol:DoRequests().
    OUTPUT STREAM lstOutput TO VALUE(Ccs.utiles.Application:Protocol:cchOutputFile).
    Ccs.utiles.Application:Protocol:Response(STREAM lstOutput:HANDLE).
    MESSAGE "Ejecutado: " xml ", Total: " GetTime(ETIME).
    FINALLY:
      OUTPUT STREAM lstOutput CLOSE.
      Ccs.utiles.Application:Protocol:cobSessionManager:MostrarImpactos(TRUE).
    END FINALLY.
  END.
  ELSE IF LENGTH(runit) > 0 THEN DO ON ERROR UNDO, THROW:
    RUN VALUE(runit).
    MESSAGE "Ejecutado: " runit ", Total: " GetTime(ETIME).
    CATCH E AS Progress.Lang.Error :
      MESSAGE 'Error:' E:getMessage(1) VIEW-AS ALERT-BOX.
      DELETE OBJECT E.
    END CATCH.
  END.
END.
