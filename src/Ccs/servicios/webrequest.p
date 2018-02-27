{nsra/utiles/runlevel.i}
/*------------------------------------------------------------------------
    File        : Ccs.servicios.webrequest.p
    Purpose     : Entry point for web transports

    Syntax      :

    Description : Process a web request

    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Fri Feb 16 18:40:49 ART 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */
{src/web/method/wrap-cgi.i}


/* ***************************  Main Block  *************************** */
{nsra/servicios/agent_check_dbconns.i}

DEFINE SHARED VARIABLE REQUEST_METHOD AS CHARACTER.

/* recepcion paquete xml */
IF WEB-CONTEXT:X-DOCUMENT<>? OR REQUEST_METHOD EQ 'GET'
  &IF DEFINED(GNMCGI_INCLUDED)=1 &THEN OR gnm-is-xml-doc &ENDIF THEN DO:
 
  Ccs.utiles.Application:Protocol:PrepareParse(?).
  IF REQUEST_METHOD EQ 'GET' THEN DO:
    DEFINE STREAM lstInput.
    OUTPUT STREAM lstInput TO VALUE(Ccs.utiles.Application:Protocol:cchInputFile) NO-ECHO CONVERT TARGET 'utf-8'.
    PUT STREAM lstInput UNFORMATTED get-value('xml').
    OUTPUT STREAM lstInput CLOSE.    
    Ccs.utiles.Application:Protocol:Parse(?).
  END.
  ELSE DO:
    &IF DEFINED(GNMCGI_INCLUDED)=1 &THEN
    /* via ganimede */
    IF gnm-is-xml-doc THEN DO:
      DEFINE STREAM lstInput.
      OUTPUT STREAM lstInput TO VALUE(Ccs.utiles.Application:Protocol:cchInputFile) NO-ECHO.
      gnm-xml-doc-hdl:SAVE("STREAM", "lstInput").
      OUTPUT STREAM lstInput CLOSE.    
      Ccs.utiles.Application:Protocol:Parse(?).
    END. 
    &ELSE
    /* via webspeed */
    &IF DEFINED( DEBUGGING ) <> 0 &THEN
      IF WEB-CONTEXT:IS-XML THEN DO:
        DEFINE STREAM lstInput.
        OUTPUT STREAM lstInput TO VALUE(Ccs.utiles.Application:Protocol:cchInputFile) NO-ECHO.
        WEB-CONTEXT:X-DOCUMENT:SAVE("STREAM", "lstInput").
        OUTPUT STREAM lstInput CLOSE.    
        Ccs.utiles.Application:Protocol:Parse(?).
      END.
      ELSE
        Ccs.utiles.Application:Protocol:Parse(WEB-CONTEXT).
    &ELSE
        Ccs.utiles.Application:bProtocol:Parse(WEB-CONTEXT).
    &ENDIF
    &ENDIF
  END.
END.
ELSE DO:
  Ccs.utiles.Application:Protocol:PrepareParse(?).
  IF REQUEST_METHOD EQ 'POST' AND get-value('pedido') NE ? THEN DO:
    DEFINE STREAM lstInput.
    OUTPUT STREAM lstInput TO VALUE(Ccs.utiles.Application:Protocol:cchInputFile) NO-ECHO CONVERT TARGET 'utf-8'.
    PUT STREAM lstInput UNFORMATTED get-value('pedido').
    OUTPUT STREAM lstInput CLOSE.    
    Ccs.utiles.Application:Protocol:Parse(?).
  END.
END.

Ccs.utiles.Application:Protocol:DoRequests().
/*si la sesión actual es una sesión de segundo plano, redirigir la salida al archivo apropiado*/
DEFINE STREAM lstOutput.

IF Ccs.utiles.Application:Protocol:cobSessionManager:cobServiceManager:cobBackgroundManager:clgBackgroundSession THEN DO:
  DEFINE VARIABLE lchSeparator AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE lchOutFile AS CHARACTER   NO-UNDO.
  
  lchSeparator = Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:GetContextValue('SeparadorDir',Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:getSerialNumber()).
  lchOutFile = REPLACE(Ccs.utiles.Application:Protocol:cchOutputFile,lchSeparator + 'inout' + lchSeparator,lchSeparator + 'background' + lchSeparator).
  DO ON ERROR UNDO, THROW:
    OUTPUT STREAM lstOutput TO VALUE(lchOutFile).
    Ccs.utiles.Application:Protocol:Response(STREAM lstOutput:HANDLE).
    FINALLY:
      OUTPUT STREAM lstOutput CLOSE.
    END FINALLY.
  END.
END.
ELSE DO:
  DEFINE VARIABLE ichFileName AS CHARACTER   NO-UNDO.

  ichFileName = Ccs.utiles.Application:Protocol:cchResponseFileName.
  IF ichFileName NE ? THEN
    output-http-header('Content-Disposition:','attachment; filename="' + ichFileName + '"').
  /* cabecera del paquete... (sin esto no camina) */
  RUN OutputContentType IN web-utilities-hdl (Ccs.utiles.Application:Protocol:cchResponseContentType).

  &IF DEFINED(CHUNKED_RESPONSE) EQ 0 &THEN
    Ccs.utiles.Application:Protocol:Response({&WEBSTREAM}:HANDLE).
  &ELSE
    DO ON ERROR UNDO,THROW:
      OUTPUT STREAM lstOutput TO VALUE(Ccs.utiles.Application:Protocol:cchOutputFile).
      Ccs.utiles.Application:Protocol:Response(STREAM lstOutput:HANDLE).
      FINALLY:
        OUTPUT STREAM lstOutput CLOSE.
      END FINALLY.
    END.
    &IF DEFINED(DEBUGGING) > 0 &THEN
    /* hacer un poco de limpieza de los pedidos y respuestas de este agente */
    DEFINE VARIABLE iinIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE ichFullName AS CHARACTER NO-UNDO.
    DEFINE VARIABLE iinIndice AS INTEGER NO-UNDO.
    DEFINE VARIABLE ichId AS CHARACTER NO-UNDO.
    ASSIGN
      ichId = Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:cchContextId
      lchSeparator = Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:GetContextValue('SeparadorDir',Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:getSerialNumber())
      iinIndex = INTEGER(Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:GetContextValue('ReqNumber',ichId)) - 30
      ichFileName = Ccs.utiles.Application:Protocol:cchInputFile
    {&END}
    ENTRY(NUM-ENTRIES(ichFileName,lchSeparator),ichFileName,lchSeparator) = ''.
    INPUT STREAM lstInput FROM OS-DIR(ichFileName) NO-ATTR-LIST.
    REPEAT ON ENDKEY UNDO, LEAVE:
      IMPORT STREAM lstInput ichFileName ichFullName.
      IF INDEX(ichFileName,ichId) EQ 0 THEN
        NEXT.
      iinIndice =INTEGER(ENTRY(1,ichFileName,'-')). 
      IF iinIndice LT iinIndex THEN
        OS-DELETE VALUE(ichFullName).
    END.
    INPUT STREAM lstInput CLOSE.
    &ENDIF

    /* inyecta xml respuesta al canal salida de webspeed/ganimede (de a 1Kb) */
    DEF STREAM stbBinary.
    DEF VAR rwvUnKbyte AS RAW NO-UNDO.
    DO ON ERROR UNDO, THROW:
      INPUT STREAM stbBinary FROM VALUE(Ccs.utiles.Application:Protocol:cchOutputFile) BINARY NO-ECHO.
      REPEAT:
        LENGTH(rwvUnKbyte)=1024. 
        IMPORT STREAM stbBinary UNFORMATTED rwvUnKbyte.
        PUT {&WEBSTREAM} CONTROL rwvUnKbyte.
      END.
      LENGTH(rwvUnKbyte)=0.
      FINALLY:
        INPUT STREAM stbBinary CLOSE.
      END FINALLY.
    END.
  &ENDIF
END.

&IF DEFINED(TIME_REQUESTS) > 0 &THEN
FUNCTION GetTime RETURNS CHARACTER (INPUT ipinMsecs AS INTEGER):

  DEFINE VARIABLE tiempo AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE segs AS INTEGER     NO-UNDO.

  segs = TRUNCATE(ipinMsecs / 1000,0).
  ipinMsecs = ipinMsecs - segs * 1000.
  IF TRUNCATE(segs / 60,0) > 0 THEN
    tiempo = STRING(INTEGER(TRUNCATE(segs / 60,0))) + ':'.
  ELSE
    tiempo = '0:'.
  segs = segs - TRUNCATE(segs / 60,0) * 60.
  IF segs < 10 THEN
    tiempo = tiempo + '0'.
  tiempo = tiempo + STRING(segs) + ':'.
  IF ipinMsecs < 10 THEN
    tiempo = tiempo + '00'.
  ELSE IF ipinMsecs < 100 THEN
    tiempo = tiempo + '0'.
  RETURN tiempo + STRING(ipinMsecs).
END FUNCTION.
&ENDIF

FINALLY:
  &IF DEFINED( SINGLE_AGENT ) EQ 0 &THEN
   Ccs.utiles.Application:Protocol:cobSessionManager:EmptyData().
   /* garantiza que en la próxima ejecución se actualice el contexto, es importante cuando se está ejecutando más de un agente */
   Ccs.utiles.Application:Protocol:cobSessionManager:cobGlobalContext:EmptyData().
  &ENDIF
  &IF DEFINED (DEBUGGING) <> 0 &THEN
  Ccs.utiles.Application:Protocol:cobSessionManager:MostrarImpactos(TRUE).
  &ENDIF
  &IF DEFINED(TIME_REQUESTS) <> 0 &THEN
  DEFINE VARIABLE linLevel AS INTEGER     NO-UNDO.
  DEFINE VARIABLE linEnd AS INTEGER     NO-UNDO.
  DEFINE VARIABLE linServ AS INTEGER     NO-UNDO.
  DEFINE VARIABLE lchServs AS CHARACTER   NO-UNDO.
  DEFINE VARIABLE linSCount AS INTEGER     NO-UNDO.
  linEnd = ETIME.
  linLevel = Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:GetLevel('NOTICE').
  Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog(' <SERVICE TIMING>',linLevel).
  Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog('<tiempototal>' + GetTime(linEnd) + '</tiempo>',linLevel).
  linSCount = Ccs.utiles.Application:Protocol:Invocations(OUTPUT lchServs,OUTPUT linServ).
  Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog('<tiemposervicio>' + GetTime(linServ) + '</tiemposervicio>',linLevel).
  Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog('<tiempoprotocolo>' + GetTime(linEnd - linServ) + '</tiempoprotocolo>',linLevel).
  DO linEnd = 1 TO linSCount:
    Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog('<servicio>' + ENTRY(linEnd,lchServs) + '</servicio>',linLevel).
  END.
  Ccs.utiles.Application:Protocol:cobSessionManager:cobLogger:OutLog(' </SERVICE TIMING>',linLevel).
  &ENDIF
END FINALLY.
