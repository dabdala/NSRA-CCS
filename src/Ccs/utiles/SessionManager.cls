 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.SessionManager
    Purpose     : Implements CCS ISessionManager spec.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 09:34:34 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.Common.ISessionManager.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Implementación de la especificación CCS integrando el funcionamiento con el
SessionManager NSRA, de forma de unificar inicio/cierre de sesiones.
Dado que el funcionamiento está basado en el concepto de CLIENT-PRINCIPAL que
NSRA no utiliza, se han incorporado algunas consideraciones para permitir
el funcionamiento aunque no se utilice realmente la seguridad integrada
de Progress.
[en]
CCS spec implementation that collaborates with NSRA SessionManager in order
to have an unified session start/end.
Due to the fact that CCS uses the concept of CLIENT-PRINCIPAL and NSRA does
not, provisions have been taken to allow the usage without really using
Progress integrated security.
$*/
CLASS Ccs.utiles.SessionManager IMPLEMENTS ISessionManager:
  /*$
  [es]
  SessionManager NSRA
  [en]
  NSRA SessionManager
  $*/
  DEFINE PUBLIC PROPERTY cobRealManager AS CLASS icomun.dao.SessionManager NO-UNDO
    GET.
    PROTECTED SET.
  /*$
  [es]
  Clase a utilizar para conservar la información de contexto del cliente.
  Se obtiene de la configuración.
  [en]
  Class to use for client context preservation. Is taken from the config file.
  $*/
  DEFINE PROTECTED PROPERTY cchClientContextClass AS CHARACTER NO-UNDO
    GET.
    SET. 
  /*$
  [es]
  Instancia encargada de preservar la información de contexto del cliente.
  [en]
  Client context preservation instance.
  $*/
	DEFINE PUBLIC PROPERTY CurrentClientContext AS Ccs.Common.IClientContext NO-UNDO 
	 GET.
	 SET. 
	/*$
	[es]
	Define si se aceptan inicio de sesión aunque falle el establecimiento del CLIENT-PRINCIPAL
	recibido.
	Se obtiene de la configuración.
	[en]
	Determines if session start is allowed when setting CLIENT-PRINCIPAL fails.
	Taken from the config file.
	$*/
  DEFINE PUBLIC PROPERTY clgAllowInsecureLogin AS LOGICAL INITIAL FALSE NO-UNDO
    GET.
    PROTECTED SET.
  /*
  [es]
  Los cuatro datos necesarios para formar un CLIENT-PRINCIPAL a utilizar para
  cuando no hay una sesión activa de algún cliente.
  Se obtiene de la configuración.
  [en]
  The four parameters required to set up a CLIENT-PRINCIPAL to use when no
  session is active.
  Taken from config file.
  */
  DEFINE PRIVATE VARIABLE cchCPInfo AS CHARACTER INITIAL 'none,none,none,none' NO-UNDO.
  /*$
  [es]
  CLIENT-PRINCIPAL utilizado para los momentos en que no hay una sesión activa.
  [en]
  Used CLIENT-PRINCIPAL when no session is active.
  $*/
  DEFINE PROTECTED PROPERTY chnBaseCP AS HANDLE NO-UNDO
    GET.
    PRIVATE SET.
		
  METHOD PUBLIC VOID dispose(  ):
	  DELETE OBJECT CurrentClientContext NO-ERROR.
		cobRealManager = ?.
	END METHOD.
  /*$
  [es]
  Elimina la instancia encargada de preserva el contexto del cliente y establece todo el
  entorno en un estado "seguro" (sin sesión).
  [en]
  Deletes client context instance and sets the environment to a secure state (no session).
  $*/
	METHOD PUBLIC VOID endRequestEnvironment(  ):
	  IF VALID-OBJECT(CurrentClientContext) THEN
	   CurrentClientContext:saveContext().
	  cobRealManager:RestoreSession(?).
	  DELETE OBJECT CurrentClientContext NO-ERROR.
    SECURITY-POLICY:SET-CLIENT(chnBaseCP).
    CATCH pError AS Progress.Lang.Error :
      DEFINE VARIABLE mobExp AS Progress.Lang.AppError NO-UNDO.
      mobExp = Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),4).      
      mobExp:AddMessage(pError:getMessage(1),pError:GetMessageNum(1)).
      DELETE OBJECT pError.
      UNDO, THROW mobExp.
    END CATCH.	  
	END METHOD.
  /*$
  [es]
  Inicia una sesión (o recupera una existente) para el usuario identificado por
  el CLIENT-PRINCPAL recibido.
  Si no puede establecerse la seguridad integrada de Progress con el CLIENT-PRINCIPAL
  recibido, el método fallará, salvo que se permitan los ingresos inseguros.
  Si el CLIENT-PRINCIPAL tiene una propiedad 'NSRASession' se utilizará esta sesión
  para validar el ingreso.
  [en]
  Starts a client session (or sets up an existing one) for the user identified by
  the received CLIENT-PRINCIPAL.
  If setting the integrated security with the received CLIENT-PRINCIPAL fails, the
  method will fail unless insecure logins are enabled.
  If the CLIENT-PRINCIPAL has an 'NSRASession' property, this will be used to
  validate the session.
  $*/
	METHOD PUBLIC VOID establishRequestEnvironment( INPUT phClientPrincipal AS HANDLE ):
	  DEFINE VARIABLE mchSesion AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE mhnAuxCP AS HANDLE NO-UNDO.
	  
	  DO ON ERROR UNDO, THROW:
	   SECURITY-POLICY:SET-CLIENT(phClientPrincipal).
	   mhnAuxCP = SECURITY-POLICY:GET-CLIENT().
	   IF mhnAuxCP EQ ? THEN DO:
       IF NOT clgAllowInsecureLogin THEN
         UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),1).
	   END.
	   ELSE
	     DELETE OBJECT mhnAuxCP.
	   CATCH pError AS Progress.Lang.Error :
       IF NOT clgAllowInsecureLogin THEN
         UNDO, THROW pError.
       DELETE OBJECT pError.     		
     END CATCH.
	  END.
	  mchSesion = phClientPrincipal:GET-PROPERTY('NSRASession').
	  IF mchSesion EQ ? AND LOOKUP(phClientPrincipal:LOGIN-STATE,'LOGIN,SSO') GT 0 THEN DO:
      mchSesion = cobRealManager:cobGlobalContext:GetContextValue(phClientPrincipal:SESSION-ID).
      IF mchSesion NE ? THEN
       cobRealManager:RestoreSession(mchSesion).            
	    IF mchSesion EQ ? OR NOT cobRealManager:IsSessionValid() THEN DO:
	     IF cobRealManager:InitSession(phClientPrincipal:USER-ID) THEN
	       mchSesion = cobRealManager:cchSession.
	     ELSE IF cobRealManager:cinSaveErrors GT 0 THEN
	       UNDO, THROW cobRealManager:SaveException().
	     ELSE
	       UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),2).
	    END.
	  END.
	  ELSE
		  cobRealManager:RestoreSession(mchSesion).
		IF cobRealManager:IsSessionCurrent() THEN DO:
		  IF NOT VALID-OBJECT(CurrentClientContext) THEN
		    CurrentClientContext = DYNAMIC-NEW cchClientContextClass().
		  CurrentClientContext:initializeContext(phClientPrincipal).
		  cobRealManager:cobGlobalContext:SaveContextValue(phClientPrincipal:SESSION-ID,mchSesion).
		END.
		ELSE IF VALID-OBJECT(CurrentClientContext) THEN DO:
		  DELETE OBJECT CurrentClientContext.
		  CurrentClientContext = ?.
		END.
	END METHOD.
  /*$
  [es]
  Restablece una sesión para el usuario. La sesión debe haberse creado previamente en
  algún lugar.
  [en]
  Restablish the user session identified by the provided id. The session must have
  been previously created somewhere.
  $*/
	METHOD PUBLIC VOID establishRequestEnvironment( INPUT pcSessionID AS CHARACTER ):
	  DEFINE VARIABLE mchSesion AS CHARACTER NO-UNDO.
		mchSesion = cobRealManager:cobGlobalContext:GetContextValue(pcSessionID).
    cobRealManager:RestoreSession(mchSesion).
    IF cobRealManager:IsSessionCurrent() THEN DO:
      IF NOT VALID-OBJECT(CurrentClientContext) THEN
        CurrentClientContext = DYNAMIC-NEW cchClientContextClass().
      CurrentClientContext:initializeContext(pcSessionID).
    END.
    ELSE IF VALID-OBJECT(CurrentClientContext) THEN DO:
      DELETE OBJECT CurrentClientContext.
      CurrentClientContext = ?.
    END.
	END METHOD.
	/*$
	[es]
	Lee el archivo config/SessionManager.cfg y en base a su contenido configura la instancia.
	[en]
	Reads the file config/SessionManager.cfg and set ups the instance accordingly.
	$*/
	METHOD PROTECTED VOID LoadConfig():
	  DEFINE VARIABLE mchNombre AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE mchValor AS CHARACTER NO-UNDO.
	  
	  FILE-INFO:FILE-NAME = 'Ccs/config/SessionManager.cfg'.
	  INPUT FROM VALUE(FILE-INFO:FULL-PATHNAME).
	  REPEAT ON ENDKEY UNDO, LEAVE:
	    IMPORT mchNombre mchValor.
	    IF SUBSTRING(mchNombre,1,1) EQ '#' THEN
	     NEXT.
	    IF mchNombre EQ 'Ccs.Common.IClientContext' THEN DO:
	      cchClientContextClass = mchValor.
	      LEAVE.
	    END.
	    ELSE IF mchNombre EQ 'allowInsecureLogin' THEN
	     clgAllowInsecureLogin = LOGICAL(mchValor).
	    ELSE IF mchNombre EQ 'CPdata' THEN
	     cchCPInfo = mchValor. 
	  END.
	  IF cchClientContextClass EQ '' THEN
	   cchClientContextClass = 'Ccs.utiles.ClientContext'.
	  FINALLY:
	    INPUT CLOSE.
	  END FINALLY.
	END METHOD.
	/*$
	[es]
	Crea un CLIENT-PRINCIPAL a utilizar cuando no hay una sesión activa.
	[en]
	Creates a CLIENT-PRINCIPAL to use when there is no active session.
	$*/
	METHOD PROTECTED VOID SetUpBaseCP():
	  chnBaseCP = SECURITY-POLICY:GET-CLIENT ().
	  IF VALID-HANDLE(chnBaseCP) THEN
	   RETURN.
	  CREATE CLIENT-PRINCIPAL chnBaseCP.
    chnBaseCP:INITIALIZE (ENTRY(1,cchCPInfo)).
    chnBaseCP:DOMAIN-NAME = ENTRY(2,cchCPInfo).
    chnBaseCP:SESSION-ID = ENTRY(3,cchCPInfo).
    IF NOT chnBaseCP:SEAL(ENTRY(4,cchCPInfo)) THEN
      UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),3).
    CATCH sError AS Progress.Lang.SysError :
      DEFINE VARIABLE mobExp AS Progress.Lang.AppError NO-UNDO.
      mobExp = Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),3).      
      mobExp:AddMessage(sError:getMessage(1),sError:GetMessageNum(1)).
    	DELETE OBJECT sError.
    	UNDO, THROW mobExp.
    END CATCH.	  
	END METHOD.
	/*$
	[es]
	Registra la clase a utilizar para las excepciones y los mensajes posibles.
	[en]
	Registers the class to use for raising errors, and the possible error messages.
	$*/
	METHOD PROTECTED VOID RegisterExceptions():
    DEFINE VARIABLE mobClase AS Progress.Lang.Class NO-UNDO.
    mobClase = THIS-OBJECT:GetClass().
    Ccs.utiles.Application:ExceptionManager:registerErrorClass(mobClase,GET-CLASS(Ccs.utiles.SessionManagerError)).
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,1,'CLIENT-PRINCIPAL inválido.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,2,'No se puede iniciar sesión NSRA para el usuario.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,3,'No puede sellarse el CLIENT-PRINCIPAL a utilizar para sesiones no iniciadas.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,4,'No puede restablecerse la sesión a un estado de identidad seguro.').
	END METHOD.
  /*$
  [es]
  Obtiene una referencia al SessionManager NSRA, carga la configuración, registra excepciones
  e inicializa el CLIENT-PRINCIPAL a usar internamente.
  [en]
  Gets a reference to NSRA SessionManager, loads config, sets up exceptions and creates the
  internal CLIENT-PRINCIPAL.
  $*/
	METHOD PUBLIC VOID initialize(  ):
		cobRealManager = CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager).
		/* determinar el tipo real de IClientContext a utilizar */
		loadConfig().
		RegisterExceptions().
		SetUpBaseCP().
	END METHOD.

END CLASS.