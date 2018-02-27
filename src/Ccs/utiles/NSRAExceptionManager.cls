 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.NSRAExceptionManager
    Purpose     : Concrete implementation of the error message handling manager.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Feb 20 11:34:27 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.utiles.IExceptionManager.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
No es parte de NSRA y simplemente conserva la información de mensajes y configuración
de cada clase que utiliza esta instancia global. Usa un traductor, si está disponible.
[en]
This is not an NSRA class, it just preserves messages and configuration.
Uses a translation manager if available.
$*/
CLASS Ccs.utiles.NSRAExceptionManager IMPLEMENTS IExceptionManager:
  /*$
  [es]
  Preserva la información que cada clase registra, para poder generar los errores solictados.
  [en]
  Preserves the information required to provide errors to users.
  $*/
  DEFINE PROTECTED TEMP-TABLE cttMensajes NO-UNDO
    FIELD Clase AS CHARACTER
    FIELD Codigo AS INTEGER
    FIELD Mensaje AS CHARACTER
    INDEX ixMensaje IS UNIQUE Clase Codigo
  .
  /*$
  [es]
  Registra qué tipo de clase utilizar para los errores de las clases que utilizan esta instancia.
  [en]
  Preserves the information of what class to use for errors to generate, for each user class.
  $*/
  DEFINE PROTECTED TEMP-TABLE cttClases NO-UNDO
    FIELD Clase AS CHARACTER
    FIELD ClaseError AS CHARACTER
    INDEX ixClase IS UNIQUE Clase
  . 
  /*$
  [es]
  Si está disponible el traductor NSRA, lo utiliza.
  [en]
  If NSRA translator is avialable, uses it.
  $*/
	DEFINE PUBLIC PROPERTY translationManager AS Ccs.utiles.ITranslationManager NO-UNDO 
	GET:
	  IF NOT VALID-OBJECT(translationManager) THEN
	   translationManager = Ccs.utiles.Application:TranslationManager.
	  RETURN translationManager.
	END GET.
	SET. 
	/*$
	[es]
	Mensaje a utilizar cuando no existe el mensaje para el código solicitado.
	[en]
	Message to use when there is no message registered for the required error code.
	$*/
	DEFINE PUBLIC PROPERTY missingErrorMessage AS CHARACTER INITIAL 'Error no especificado' NO-UNDO
	GET.
	SET.
	METHOD PUBLIC VOID dispose(  ):
	 EMPTY TEMP-TABLE cttMensajes.
	 EMPTY TEMP-TABLE cttClases.
	END METHOD.
  /*$
  [es]
  Se registra como manager de excepciones y obtiene el traductor, si es que está disponible.
  [en]
  Register itself as global exception manager and obtains the global translator, if available.
  $*/
	METHOD PUBLIC VOID initialize(  ):
	  IF NOT VALID-OBJECT(Ccs.utiles.Application:ExceptionManager) THEN
	   Ccs.utiles.Application:ExceptionManager = THIS-OBJECT.
	  IF NOT VALID-OBJECT(translationManager) THEN
	   translationManager = Ccs.utiles.Application:TranslationManager.
	END METHOD.
	
  METHOD PUBLIC LOGICAL registerErrorClass( INPUT ThrowingClass AS Progress.Lang.Class, INPUT ErrorClass AS Progress.Lang.Class):
    FIND cttClases WHERE cttClases.Clase EQ ThrowingClass:TypeName NO-ERROR.
    IF AVAILABLE cttClases THEN DO:
      cttClases.ClaseError = ErrorClass:TypeName.
      RETURN TRUE.
    END.
    CREATE cttClases.
    ASSIGN
      cttClases.Clase = ThrowingClass:TypeName
      cttClases.ClaseError = ErrorClass:TypeName
    .
    RETURN FALSE.
  END METHOD.
	METHOD PUBLIC LOGICAL registerError( INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER, INPUT messageDesc AS CHARACTER ):
		FIND cttMensajes WHERE cttMensajes.Clase EQ ThrowingClass:TypeName AND cttMensajes.Codigo EQ messageCode NO-ERROR.
		IF AVAILABLE cttMensajes THEN DO:
		  cttMensajes.Mensaje = messageDesc.
		  RETURN TRUE.
		END.
		CREATE cttMensajes.
		ASSIGN
		  cttMEnsajes.Clase = ThrowingClass:TypeName
		  cttMensajes.Codigo = messageCode
		  cttMEnsajes.Mensaje = messageDesc
		.
		RETURN FALSE.
	END METHOD.

  METHOD PUBLIC Progress.Lang.AppError throwError( INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER ):
    DEFINE VARIABLE mchSubst AS CHARACTER EXTENT NO-UNDO.
    RETURN throwError(ThrowingClass,messageCode,mchSubst).
  END METHOD.
	METHOD PUBLIC Progress.Lang.AppError throwError( INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER , INPUT substitutions AS CHARACTER EXTENT):
	  DEFINE VARIABLE mchMensaje AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  DEFINE VARIABLE mobError AS CLASS Progress.Lang.AppError NO-UNDO.
	  
		FIND cttMensajes WHERE cttMensajes.Clase EQ ThrowingClass:TypeName AND cttMensajes.Codigo EQ messageCode NO-ERROR.
		IF NOT AVAILABLE cttMEnsajes THEN
		  mchMensaje = missingErrorMessage.
		ELSE
		  mchMensaje = cttMensajes.Mensaje.
		IF VALID-OBJECT(translationManager) THEN
		  mchMEnsaje = translationManager:translate(mchMensaje).
		IF EXTENT(substitutions) GT 0 THEN DO:
		  DO minIndex = 1 TO EXTENT(substitutions):
		    mchMensaje = REPLACE(mchMensaje,'&' + STRING(minIndex), substitutions[minIndex]).
		  END.
		END.
		FIND cttClases WHERE cttClases.Clase EQ ThrowingClass:TypeName NO-ERROR.
		IF AVAILABLE cttClases THEN
		  mobError = DYNAMIC-NEW(cttClases.ClaseError)(mchMensaje,messageCode).
		ELSE
		  mobError = NEW Progress.Lang.AppError(mchMEnsaje,messageCode).
		RETURN mobError.
	END METHOD.


END CLASS.