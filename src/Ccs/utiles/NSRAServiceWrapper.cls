{nsra/utiles/runlevel.i}
 /*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.NSRAServiceWrapper
    Purpose     : Wrap NSRA services in an Invokable object, in order to use is as a CCS service.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 11:12:18 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.ServiceManager.*.
USING Ccs.Common.IService.
USING Ccs.utiles.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
CCS espera que los servicios sean objetos, en los cuales invocar métodos específicos, que el 
usuario del servicio debe conocer.
NSRA implementa los servicios como procedimientos internos y no se espera que el usuario
sepa cómo ni dónde está implementado el servicio.
Esta clase permite utilizar servicios NSRA como servicios CCS, llendo un paso más allá e
implementando un mecanismo genérico de invocación del servicio.
[en]
CCS uses objects as services, users of CCS services must know object class and invoke the
appropriate methods, after casting the instance.
NSRA implements services as interna procedures, and user must know nothing about the implementation.
This class allows for the CCS style of usage of NSRA services. It takes things a step further
by allowing the generic invocation of services.
$*/
CLASS Ccs.utiles.NSRAServiceWrapper IMPLEMENTS IInvokable:
  /*$
  [es]
  Nomenclatura NSRA para la obtención de los parámetros del servicio.
  [en]
  NSRA naming to get service paramaters.
  $*/
  DEFINE PUBLIC PROPERTY cobServiceParams AS IServiceParams NO-UNDO
    GET.
    PRIVATE SET.
  /*$
  [es]
  Nomenclatura CCS para la obtención de los parámetros.
  [en]
  CCS naming convention to get parameters. 
  $*/
  DEFINE PUBLIC PROPERTY serviceParams AS IServiceParams NO-UNDO
    GET:
      RETURN cobServiceParams.
    END GET.
  /*$
  [es]
  Objeto CALL para la invocación del servicio NSRA.
  Se elimina al asignar ?.
  [en]
  CALL object for NSRA service invocation.
  Gets deleted by assigning ?.
  $*/
  DEFINE PROTECTED STATIC PROPERTY chnDynCall AS HANDLE NO-UNDO
    GET:
      IF NOT VALID-HANDLE(chnDynCall) THEN
        CREATE CALL chnDynCall.
      RETURN chnDynCall.
    END.
    SET(INPUT iphnCall AS HANDLE):
      IF iphnCall EQ ? THEN
        DELETE OBJECT chnDynCall NO-ERROR.
      chnDynCall = iphnCall.
    END.
  /*$
  [es]
  Elimina las instancias internas.
  [en]
  Deletes internal instances.
  $*/
	METHOD PUBLIC VOID dispose(  ):
		DELETE OBJECT cobServiceParams NO-ERROR.
		chnDynCall = ?.
	END METHOD.
  /*$
  [es]
  Usa el ExceptionManager para registrar las posibles excepciones de esta clase, y la clase a utilizar.
  [en]
  Uses ExceptionManager to register class possible errors, and error class to use.
  $*/
	METHOD PUBLIC VOID initialize(  ):
    Ccs.utiles.Application:ExceptionManager:registerErrorClass(THIS-OBJECT:GetClass(),GET-CLASS(Ccs.utiles.NSRAServiceWrapperError)).
    Ccs.utiles.Application:ExceptionManager:registerError(THIS-OBJECT:GetClass(),1,'Se requere que serviceObject, o serviceHandle, sea válido para invocar un servicio').
    Ccs.utiles.Application:ExceptionManager:registerError(THIS-OBJECT:GetClass(),2,'Se ha producido un error al invocar el método de la instancia: &1').
    Ccs.utiles.Application:ExceptionManager:registerError(THIS-OBJECT:GetClass(),3,'Se ha producido un error al invocar el procedimiento: &1').
	END METHOD.
	/*$
	[es]
	Realiza la invocación del servicio NSRA, con los parámetros provistos.
	Si los parámetros corresponden a una instancia de clase, realiza la invocación en forma directa,
	sino utiliza invocación dinámica.
	[en]
	Invokes NSRA service with the provided parameters.
	If parameters holds an object invocation is done directly (throgh reflection),
	in any other case a dynamic invocation is used.
	$*/
	METHOD PUBLIC VOID invoke(INPUT-OUTPUT obParams AS IServiceParams):
	  DEFINE VARIABLE mchError AS CHARACTER EXTENT 1 NO-UNDO.

    IF VALID-OBJECT(obParams:serviceObject) THEN DO ON ERROR UNDO, THROW:
      IF obParams:inputCount + obParams:outputCount EQ 0 THEN
        obParams:serviceObject:GetClass():Invoke(obParams:serviceObject,obParams:serviceName).
      ELSE
        obParams:serviceObject:GetClass():Invoke(obParams:serviceObject,obParams:serviceName,obParams:paramList).
      RETURN.
      CATCH sError AS Progress.Lang.SysError :
        mchError[1] = sError:getMessage(1).
        DELETE OBJECT sError.
        UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),2,mchError).
      END CATCH.
    END.
    IF NOT VALID-HANDLE(obParams:serviceHandle) THEN
      UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),1).

    DEFINE VARIABLE minPCount AS INTEGER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE minLongIndex AS INTEGER NO-UNDO.    
    DEFINE VARIABLE minLongCount AS INTEGER NO-UNDO.
    DEFINE VARIABLE mlcLongParam AS LONGCHAR EXTENT NO-UNDO.
    DEFINE VARIABLE mchParam AS CHARACTER EXTENT NO-UNDO.
      
    chnDynCall:CLEAR().
    chnDynCall:CALL-NAME = obParams:serviceName.
    chnDynCall:IN-HANDLE = obParams:serviceHandle.
    minPCount = obParams:inputCount + obParams:outputCount - obParams:bothCount.
    chnDynCall:NUM-PARAMETERS = minPCount.
    IF minPCount GT 0 THEN
      EXTENT(mchParam) = minPCount.
    
    DO minIndex = 1 TO minPCount:
      IF obParams:parameterType(minIndex) EQ 'LONGCHAR' THEN
        minLongCount = minLongCount + 1.
    END.
    IF minLongCount GT 0 THEN
      EXTENT(mlcLongParam) = minLongCount.
    minLongIndex = 1.
    DO minIndex = 1 TO minPCount:
      /* para INPUT y para INPUT-OUTPUT, tengo que establecer el valor del parámetro */
      IF obParams:parameterMode(minIndex) NE 'OUTPUT' THEN DO:
        IF obParams:ParameterType(minIndex) EQ 'LONGCHAR' THEN DO:
          mlcLongParam[minPCount] = obParams:getLongInput(minIndex).
          minLongIndex = minLongIndex + 1.
        END.
        ELSE
          mchParam[minIndex] = obParams:getInput(minIndex).
      END.
      IF obParams:ParameterType(minIndex) EQ 'LONGCHAR' THEN
        chnDynCall:SET-PARAMETER(minIndex, 'LONGCHAR', obParams:parameterMode(minIndex), mlcLongParam[minLongIndex - 1]).
      ELSE
        chnDynCall:SET-PARAMETER(minIndex, 'CHARACTER', obParams:parameterMode(minIndex), mchParam[minIndex]).
    END.
    /* invoca servicio abl */
    chnDynCall:INVOKE.
    /* asigna valores de parametros resultantes tipo output */
    minLongIndex = 0.
    DO minIndex = 1 TO minPCount:
      IF obParams:parameterType(minIndex) EQ 'LONGCHAR' THEN
          minLongIndex = minLongIndex + 1.
      IF obParams:parameterMode(minIndex) NE 'INPUT' THEN DO:
        IF obParams:ParameterType(minIndex) EQ 'LONGCHAR' THEN
          obParams:setLongOutput(minIndex,mlcLongParam[minLongIndex]).
        ELSE
          obParams:setOutput(minIndex,mchParam[minIndex]).
      END.
    END.
    CATCH sError AS Progress.Lang.SysError :
      mchError[1] = sError:getMessage(1).
      DELETE OBJECT sError.
      UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),3,mchError).
    END CATCH.
	END METHOD.
  /*$
  [es]
  Prepara la instancia para realizar la invocación dinámica de un servicio NSRA que es un procedimiento interno.
  [en]
  Setups the instance for the invocation of an internal procedure NSRA service.
  $*/
  CONSTRUCTOR NSRAServiceWrapper(INPUT iphnService AS HANDLE, INPUT ipchService AS CHARACTER):
    cobServiceParams = NEW Ccs.utiles.ServiceParams().
    cobServiceParams:initialize(iphnService,ipchService).
  END CONSTRUCTOR.
  /*$
  [es]
  Prepara la instancia para invocar un método de un objeto, como servicio.
  [en]
  Setups the instance for the invocation of an object method.
  $*/
  CONSTRUCTOR NSRAServiceWrapper(INPUT ipobService AS Progress.Lang.Object, INPUT ipchService AS CHARACTER):
    cobServiceParams = NEW Ccs.utiles.ServiceParams().
    cobServiceParams:initialize(ipobService,ipchService).
  END CONSTRUCTOR.
END CLASS.