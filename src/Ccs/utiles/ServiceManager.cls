 
 /*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.ServiceManager
    Purpose     : Implementation of the CCS specification, taking into account NSRA services.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 11:07:21 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.Common.IServiceManager.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Implementa el acceso a servicios a través de las interfaces definidas por CCS.
Utiliza envolturas CCS para acceder a los servicios NSRA.
Dado que los servicios NSRA se identifican por nombre, la única forma de acceder
directamente a un servicio NSRA es utilizar el método que recibe un "alias", que
corresponde al nombre del servicion NSRA.
Para los demás métodos se busca si el nombre de clase está definido como nombre
de recurso REST para algún servicio, de ser así se usa ese servicio NSRA. Dado
que no hay forma de identificar la operación HTTP asociada al servicio REST, este
método no es seguro, salvo que el servicio sea capaz de manejar todos los verbos
REST (lo cual no es habitual, ni recomendable).
[en]
Implements CCS service access to NSRA services.
NSRA services requires wrappers, as they are internal procedures.
Due to the fact that NSRA services are identified by name, the only method call
that directly returns an NSRA service wrapped is the one that takes an "alias" as
parameter.
The others methods verifies if the classname matches an NSRA REST service resource
definition and, if yes, then this NSRA service is returned. One thing to consider
is the inhability to verify the REST verb requested, so no check is made about it.
$*/
CLASS Ccs.utiles.ServiceManager IMPLEMENTS IServiceManager:
  /*$
  [es]
  Dado que se requiere un entorno NSRA funcional, se conserva una referencia
  al SessionManager (que es el punto de entrada en NSRA).
  [en]
  Due to the need of a functional NSRA environment, a reference to NSRA
  SessionManager is preserved.
  $*/
  DEFINE PROTECTED PROPERTY cobSessionManager AS CLASS icomun.dao.SessionManager NO-UNDO
    GET.
    SET. 
    
  /*$
  [es]
  Conserva la referencia a cada servicio instanciado, para devolverlos si vuelven a
  solicitarse, y para eliminarlos cuando se solicita.
  [en]
  Keeps a reference to every requested service, to return them when required again,
  and to release them on request.
  $*/
  DEFINE PROTECTED TEMP-TABLE cttServicios NO-UNDO
    FIELD Clase AS CHARACTER
    FIELD Instancia AS Progress.Lang.Object
    FIELD Alcance AS Progress.Lang.Object
    FIELD AliasInstancia AS CHARACTER
  .

  /*$
  [es]
  Libera la referencia al SessionManager y elimina todos los servicios instanciados.
  [en]
  Frees the SessionManager reference and frees all the instantiated services.
  $*/
	METHOD PUBLIC VOID dispose(  ):
    cobSessionManager = ?.
    FOR EACH cttServicios:
      DELETE OBJECT Instancia NO-ERROR.
    END.
    EMPTY TEMP-TABLE cttServicios.
	END METHOD.
  /*$
  [es]
  Se busca un servicio NSRA que tenga definido el nombre de la clase como entidad REST,
  primero para 'GET' y luego para 'POST', si se encuentra, se devuelve este servicio, sino
  se instancia la clase.
  [en]
  Searches for an NSRA REST resource matching the class name, first for GET, then for POST,
  if one matches, this NSRA service is returned, otherwise the class gets instantiated.
  $*/
	METHOD PUBLIC Progress.Lang.Object getService( INPUT poService AS Progress.Lang.Class ):
		DEFINE VARIABLE mobServiceManager AS icomun.dao.ServiceManager NO-UNDO.
		DEFINE VARIABLE mchService AS CHARACTER NO-UNDO.
		DEFINE VARIABLE mobService AS Progress.Lang.Object NO-UNDO.
		
    IF NOT VALID-OBJECT(poService) THEN
      RETURN ?.
		FIND cttServicios WHERE cttServicios.Clase EQ poService:TypeName NO-ERROR.
		IF AVAILABLE cttServicios THEN
		  RETURN cttServicios.Instancia.
		mobServiceManager = cobSessionManager:cobServiceManager.
    mchService = mobServiceManager:EntityService(poService:TypeName,'GET').
    IF mchService EQ ? THEN
      mchService = mobServiceManager:EntityService(poService:TypeName,'POST').
    IF mchService EQ ? THEN
      mobService = poService:New() NO-ERROR.
    ELSE
      mobService = NEW Ccs.utiles.NSRAServiceWrapper(mobServiceManager:ServiceToCall(mchService,TRUE),mobServiceManager:cchCurrentService).
    IF VALID-OBJECT(mobService) THEN DO:
      IF NOT TYPE-OF(mobService,Ccs.Common.IService) THEN
        UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),1).
      CAST(mobService,Ccs.Common.IService):initialize().
      CREATE cttServicios.
      ASSIGN
        cttServicios.Clase = poService:TypeName
        cttServicios.Instancia = mobService
        cttServicios.Alcance = ?
        cttServicios.AliasInstancia = ?
      .
    END.
    ELSE
      UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),2).
    RETURN mobService.
	END METHOD.
  /*$
  [es]
  Simplemente invoca el método que recibe solo la clase, y luego establece el alcance para ese servicio.
  [en]
  Invokes the method that only receives the class, after which sets that service scope.
  $*/
	METHOD PUBLIC Progress.Lang.Object getService( INPUT poService AS Progress.Lang.Class, INPUT poScope AS Ccs.ServiceManager.ILifecycleScope ):
	  DEFINE VARIABLE mobService AS Progress.Lang.Object NO-UNDO.
		mobService = getService(poService).
		IF AVAILABLE cttServicios AND cttServicios.Instancia EQ mobService THEN
      cttServicios.Alcance = poScope:getScope().
		RETURN mobService.
	END METHOD.
  /*$
  [es]
  Busca el servicio NSRA pcAlias, si no lo encuentra, invoca el método que recibe solamente la clase.
  [en]
  Searches for the pcAlias NSRA service, if not found the method which only receives the class gets invoked. 
  $*/
	METHOD PUBLIC Progress.Lang.Object getService( INPUT poService AS Progress.Lang.Class, INPUT pcAlias AS CHARACTER ):
    DEFINE VARIABLE mobServiceManager AS icomun.dao.ServiceManager NO-UNDO.
    DEFINE VARIABLE mobService AS Progress.Lang.Object NO-UNDO.
    DEFINE VARIABLE mhnService AS HANDLE NO-UNDO.
    DEFINE VARIABLE mobExcept AS icomun.utiles.IServiceException NO-UNDO.
    
		IF poService EQ ? AND pcAlias NE ? THEN DO:
      mobServiceManager = cobSessionManager:cobServiceManager.
      mhnService = mobServiceManager:ServiceToCall(pcAlias,FALSE). 
      IF VALID-HANDLE(mhnService) THEN DO:
        mobService = NEW Ccs.utiles.NSRAServiceWrapper(mhnService,mobServiceManager:cchCurrentService).
        CAST(mobService,Ccs.Common.IService):initialize().
        CREATE cttServicios.
        ASSIGN
          cttServicios.Clase = 'Ccs.utiles.NSRAServiceWrapper'          
          cttServicios.Instancia = mobService
          cttServicios.Alcance = ?
          cttServicios.AliasInstancia = ?
        .
        RETURN mobService.
      END.
      IF mobServiceManager:ExceptionCount() GT 0 THEN DO:
        mobExcept = mobServiceManager:GetException(1).
        UNDO, THROW NEW AppError(mobExcept:GetDescription(),4).
      END.
      ELSE
        UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),3).
		END.
		ELSE DO ON ERROR UNDO, THROW:
      FIND cttServicios WHERE cttServicios.Clase EQ poService:TypeName AND cttServicios.AliasInstancia EQ pcAlias NO-ERROR.
      IF AVAILABLE cttServicios THEN
        RETURN cttServicios.Instancia.
      RETURN getService(poService).
      FINALLY:
        IF AVAILABLE cttServicios THEN
          cttServicios.AliasInstancia = pcAlias.
      END FINALLY.
		END.
	END METHOD.
  /*$
  [es]
  Registra la clase a utilizar para los errores, y cada uno de los mensajes de error posibles.
  [en]
  Registers this class error class to use, and each of the posible error messages.
  $*/
  METHOD PROTECTED VOID RegisterExceptions():
    DEFINE VARIABLE mobClase AS Progress.Lang.Class NO-UNDO.
    mobClase = THIS-OBJECT:GetClass().
    Ccs.utiles.Application:ExceptionManager:registerErrorClass(mobClase,GET-CLASS(Ccs.utiles.ServiceManagerError)).
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,1,'La clase no implementa la interfaz IService.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,2,'No se pudo crear el servicio.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,3,'No se puede crear la envoltura del servicio NSRA.').
  END METHOD.
  /*$
  [es]
  Obtiene una referencia al SessionManager NSRA y registra las excepciones posibles para la clase.
  [en]
  Gets the NSRA SessionManager reference and registers class exceptions.
  $*/
	METHOD PUBLIC VOID initialize(  ):
		cobSessionManager = CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager).
    RegisterExceptions().
	END METHOD.
  /*$
  [es]
  Elimina todos los servicios que respetan el alcance indicado. La mayoría se instancian sin especificar
  alcance, por lo que se eliminan únicamente si el alcance es la sesión.
  [en]
  Deletes all the services instantiated for the specified scope. As most services are instantiated without
  scope, they are deleted only for the session scope.
  $*/
	METHOD PUBLIC VOID stopServices( INPUT poScope AS Ccs.ServiceManager.ILifecycleScope ):
	  DEFINE VARIABLE mobScope AS Progress.Lang.Object NO-UNDO.
		IF TYPE-OF(poScope,Ccs.ServiceManager.ISessionScope) THEN DO:
		  cobSessionManager:cobServiceManager:Restart(TRUE,TRUE).
      FOR EACH cttServicios:
        DELETE OBJECT cttServicios.Instancia NO-ERROR.
        DELETE cttServicios.
      END. 
		END.
		mobScope = poScope:getScope().
    FOR EACH cttServicios WHERE cttServicios.Alcance NE ?:        
      IF NOT mobScope:Equals(cttServicios.Alcance) THEN
        NEXT.
      DELETE OBJECT cttServicios.Instancia NO-ERROR.
      DELETE cttServicios.
    END. 
	END METHOD.

END CLASS.