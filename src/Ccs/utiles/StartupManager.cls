 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.StartupManager
    Purpose     : Implements CCS IStartupManager spec.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 09:34:34 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/
{nsra/utiles/runlevel.i}
ROUTINE-LEVEL ON ERROR UNDO, THROW.

USING Progress.Lang.*.
USING Ccs.Common.*.
USING icomun.dao.SessionManager.

/*$
[es]
Además de realizar las tareas propias de Ccs, instancia el SessionManager NSRA, lo que levanta todo el entorno NSRA.
[en]
Besides implementing CCS spec is responsible for instantiating NSRA SessionManager, which sets up the whole NSRA
environment.
$*/
CLASS Ccs.utiles.StartupManager IMPLEMENTS IStartupManager: 
  /*$
  [es]
  Punto de entrada a la infraestructura común NSRA.
  [en]
  NSRA common infrastructure entry point.
  $*/
  DEFINE PROTECTED VARIABLE cobSessionManager AS icomun.dao.SessionManager NO-UNDO.
  /*$
  [es]
  Conserva toda la configuración leida del archivo config/StartupManager.cfg
  [en]
  Preserves the configuration taken from config/StartupManager.cfg
  $*/
  DEFINE PROTECTED TEMP-TABLE cttConfig NO-UNDO
    FIELD chNombre AS CHARACTER
    FIELD chValor AS CHARACTER
    INDEX pkNombre IS PRIMARY IS UNIQUE chNombre
  {&END}
  /*$
  [es]
  Conserva las referencias a todos los IManager instanciados.
  [en]
  Preserves the references to every instantiated IManager.
  $*/
  DEFINE PROTECTED TEMP-TABLE cttManager NO-UNDO
    FIELD inOrder AS INTEGER
    FIELD chClass AS CHARACTER
    FIELD obInstance AS Progress.Lang.Object
    INDEX ixManagers IS PRIMARY IS UNIQUE inOrder
  {&END}
  /*$
  [es]
  Lee la configuración y carta la TT.
  [en]
  Reads the config file and preserves it in the TT.
  $*/
  METHOD PROTECTED VOID LoadConfig():
    FILE-INFO:FILE-NAME = 'Ccs/config/StartupManager.cfg'.
    INPUT FROM VALUE(FILE-INFO:FULL-PATHNAME).
    REPEAT ON ENDKEY UNDO, LEAVE:
      CREATE cttConfig.
      IMPORT cttConfig.
    END.
    /* eliminar las configuraciones comentadas */
    FOR EACH cttConfig WHERE cttConfig.chNombre BEGINS '#':
      DELETE cttConfig.
    END.
    FINALLY:
      INPUT CLOSE.
    END FINALLY.
  END METHOD.
  /*$
  [es]
  Si el ServiceManager CCS está disponible, intenta que sea éste quien instancie el Manager,
  si no está disponible, o no devuelve uno, se instancia la clase.
  [en]
  If CCS ServiceManager is available is used to get the instance, if no instance if obtained
  the class gets instantiated.
  $*/
  METHOD PROTECTED Progress.Lang.Object createManager(INPUT ipchClass AS CHARACTER):
    DEFINE VARIABLE mobManager AS Progress.Lang.Object NO-UNDO.
    DEFINE VARIABLE mifManager AS CLASS IManager NO-UNDO.
    DEFINE VARIABLE minSiguiente AS INTEGER INITIAL 1 NO-UNDO.
    
    IF VALID-OBJECT(Ccs.Common.Application:ServiceManager) THEN DO ON ERROR UNDO, THROW:        
      mobManager = Ccs.Common.Application:ServiceManager:getService(Progress.Lang.Class:GetClass(ipchClass)).
      CATCH pError AS Progress.Lang.Error :
        DELETE OBJECT pError.           
      END CATCH.
    END.
    IF NOT VALID-OBJECT(mobManager) THEN
      mobManager = DYNAMIC-NEW ipchClass().
    mifManager = CAST(mobManager,IManager).
    mifManager:initialize().
    FOR EACH cttManager BY cttManager.inOrder DESCENDING:
      minSiguiente = cttManager.inOrder + 1.
      LEAVE.
    END.
    CREATE cttManager.
    ASSIGN
      cttManager.inOrder = minSiguiente
      cttManager.chClass = ipchClass
      cttManager.obInstance = mifManager
    {&END} 
    RETURN mobManager.
  END METHOD.
  
  /*$
  [es]
  Intenta crear todos los objetos IManager definidos en la configuración, en el orden definidos.
  Si está disponible IServiceManager, lo utiliza para obtener las instancias, si no está disponible, o
  falla la instanciación a través de éste, realiza un DYNAMIC-NEW.
  Se registra en Ccs.Common.Application cada instancia que implemente las interfaces correctas, lo que
  hace que quede registrada la última que satisfaga cada interfaz.
  [en]
  Tryes to create every IManager listed in the configuration, in the specified order.
  If CCS ServiceManager is available, uses it, otherwise every class id dynamically instantiated.
  Ever instance implementing the correct interfaces is registered in Ccs.Common.Application, which implies
  that the last instance of every interface results in the registered interface for the Application.
  $*/
  METHOD PROTECTED VOID CreateManagers():
    DEFINE VARIABLE mchLista AS CHARACTER NO-UNDO.
    
    FIND cttConfig WHERE chNombre EQ 'Managers' NO-ERROR.
    IF AVAILABLE cttConfig THEN
      mchLista = cttConfig.chValor.     
      
    DEFINE VARIABLE mchEntry AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minEntry AS INTEGER NO-UNDO.
    DEFINE VARIABLE minNE AS INTEGER NO-UNDO.
    DEFINE VARIABLE mifManager AS CLASS IManager NO-UNDO.
    DEFINE VARIABLE mobManager AS Progress.Lang.Object NO-UNDO.
    
    minNE = NUM-ENTRIES(mchLista).
    DO minEntry = 1 TO minNE ON ERROR UNDO, THROW:
      mchEntry = ENTRY(minEntry,mchLista).
      mobManager = createManager(mchEntry).
      
      IF mobManager:GetClass():IsA('Ccs.Common.IServiceManager') THEN
        Ccs.Common.Application:ServiceManager = CAST(mobManager,IServiceManager).
        
      IF mobManager:GetClass():IsA('Ccs.Common.ISessionManager') THEN
        Ccs.Common.Application:SessionManager = CAST(mobManager,ISessionManager).
        
      IF mobManager:GetClass():IsA('nsra.utiles.BaseProtocol') THEN
        Ccs.utiles.Application:Protocol = CAST(mobManager,nsra.utiles.BaseProtocol).
      
      CATCH pError AS Progress.Lang.Error :
        DEFINE VARIABLE aError AS Progress.Lang.AppError NO-UNDO.
        DEFINE VARIABLE mchClassList AS CHARACTER EXTENT 1 NO-UNDO.
      	DestroyManagers().
      	mchClassList = mchEntry.
      	aError = Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),1,mchClassList).
      	DO minEntry = 1 TO pError:NumMessages:
      	 aError:AddMessage(pError:GetMessage(minEntry),pError:GetMessageNum(minEntry)).
        END.
        DELETE OBJECT pError.
      	UNDO, THROW aError.
      END CATCH.
    END.
    /* proveer managers por omisión, para los que no han sido especificados */
    IF NOT VALID-OBJECT(Ccs.utiles.Application:Protocol) THEN DO:
      mobManager = createManager('Ccs.utiles.NsxmlProtocol').
      Ccs.utiles.Application:Protocol = CAST(mobManager,nsra.utiles.BaseProtocol).
    END.
    IF Ccs.Common.Application:SessionManager EQ ? OR NOT VALID-OBJECT(Ccs.Common.Application:SessionManager) THEN DO:
      mobManager = createManager('Ccs.utiles.SessionManager').
      Ccs.Common.Application:SessionManager = CAST(mobManager,Ccs.Common.ISessionManager).
    END.
    IF NOT VALID-OBJECT(Ccs.Common.Application:ServiceManager) THEN DO:
      mobManager = createManager('Ccs.utiles.ServiceManager').
      Ccs.Common.Application:ServiceManager = CAST(mobManager,Ccs.Common.IServiceManager).      
    END.
    IF NOT VALID-OBJECT(Ccs.utiles.Application:ExceptionManager) THEN DO:
      mobManager = createManager('Ccs.utiles.NSRAExceptionManager').
      Ccs.utiles.Application:ExceptionManager = CAST(mobManager,Ccs.utiles.NSRAExceptionManager).
    END.
  END METHOD.
  /*$
  [es]
  Registra la clase a utilizar para los errores, y los posibles mensajes de error.
  [en]
  Registers the class to use for error raising, and possible messages.
  $*/
  METHOD PROTECTED VOID RegisterExceptions():    
    DEFINE VARIABLE mobClase AS Progress.Lang.Class NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    mobClase = THIS-OBJECT:GetClass().
    Ccs.utiles.Application:ExceptionManager:registerErrorClass(mobClase,GET-CLASS(Ccs.utiles.StartupManagerError)).
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,1,'No se puede instanciar el Manager: &1.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,2,'No se pudo instanciar el Manager: &1.').
    Ccs.utiles.Application:ExceptionManager:registerError(mobClase,3,'Se requiere especificar "RootDir" en la configuración.').
  END METHOD.
  /*$
  [es]
  Elimina cada uno de los managers que se hayan instanciado.
  [en]
  Destroys every instantiated manager.
  $*/
  METHOD PROTECTED VOID DestroyManagers():
    DEFINE VARIABLE mifManager AS IManager NO-UNDO.
    FOR EACH cttManager:
      IF VALID-OBJECT(cttManager.obInstance) THEN DO:
        mifManager = CAST(cttManager.obInstance,IManager).
        mifManager:dispose().
        DELETE OBJECT mifManager NO-ERROR.
        cttManager.obInstance = ?.
      END.
    END.
    EMPTY TEMP-TABLE cttManager.
  END METHOD.
  /*$
  [es]
  Elimina todo, lo que deja el entorno inutilizable.
  [en]
  Frees everything, which leaves the environment unavailable.
  $*/
	METHOD PUBLIC VOID dispose(  ):
	  DestroyManagers().
		DELETE OBJECT cobSessionManager.
		EMPTY TEMP-TABLE cttConfig.
	END METHOD.
  /*$
  [es]
  Devuelve el primer IManager que satisfaga la clase especificada.
  Si no hay uno y la clase es un IManager, entonces se instancia.
  [en]
  Returns the first instantiated IManager that satisfies the pServiceType class.
  If none exists and the class is an IManager then it gets instantiated.
  $*/
	METHOD PUBLIC Ccs.Common.IManager getManager( INPUT pServiceType AS Progress.Lang.Class ):	  
    DEFINE VARIABLE mchClase AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mobManager AS Progress.Lang.Object NO-UNDO.
    DEFINE VARIABLE mchService AS CHARACTER EXTENT 1 NO-UNDO.
    
	  IF THIS-OBJECT:GetClass():IsA(pServiceType) THEN
	   RETURN THIS-OBJECT.	  
	  mchClase = pServiceType:TypeName.
	  FOR EACH cttManager WHERE cttManager.chClass EQ mchClase BY cttManager.inOrder:
	    RETURN CAST(cttManager.obInstance,IManager).
	  END.
	  /* si no hay uno coincidente, verificar si hay alguno que implemente la clase  deseada */
	  FOR EACH cttManager BY cttMAnager.inOrder:
	    IF cttManager.obInstance:getClass():IsA(pServiceType) THEN
	     RETURN CAST(cttManager.obInstance,IManager).
	  END.
	  /* si no existe una instancia, pero se trata de un IManager, intentar instanciarlo */
	  IF pServiceType:IsA('Ccs.Common.IManager') THEN DO ON ERROR UNDO, THROW:
	    mobManager = createManager(pServiceType:TypeName).
      CATCH pError AS Progress.Lang.Error :
        DELETE OBJECT pError.
      END.
	  END.
	  mchService[1] = pServiceType:TypeName.
		UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),2,mchService).
	END METHOD.
  /*$
  [es]
  Lee la configuración e inicializa todo el entorno, lo que implica tanto CCS como NSRA.
  [en]
  Reads config and sets up the CCS environment and the NSRA environment.
  $*/
	METHOD PUBLIC VOID initialize():
    Ccs.Common.Application:ServiceManager = ?.
    Ccs.Common.Application:SessionManager = ?.
    Ccs.utiles.Application:ExceptionManager = ?.
    Ccs.utiles.Application:Protocol = ?.
    Ccs.utiles.Application:SessionManager = ?.
    Ccs.utiles.Application:TranslationManager = ?.
	  LoadConfig().
	  FIND cttConfig WHERE chNombre EQ 'RootDir' NO-ERROR.
	  IF NOT AVAILABLE cttConfig THEN
	   UNDO, THROW NEW Ccs.utiles.StartupManagerError('Se requiere especificar "RootDir" en la configuración.',3).
	  IF cttConfig.chValor EQ '' THEN DO:
	    DEFINE VARIABLE mchFileName AS CHARACTER NO-UNDO.
	    mchFileName = REPLACE(THIS-OBJECT:GetClass():TypeName,'.','/').
      FILE-INFO:FILE-NAME = mchFileName + '.cls'.
	    IF FILE-INFO:FULL-PATHNAME EQ ? THEN
        FILE-INFO:FILE-NAME = mchFileName + '.r'.
	    IF FILE-INFO:FULL-PATHNAME NE ? THEN DO:
	     cttConfig.chValor = FILE-INFO:FULL-PATHNAME.
	     ENTRY(NUM-ENTRIES(cttConfig.chValor,'.'),cttConfig.chValor,'.') = ''.
	     SUBSTRING(cttConfig.chValor,LENGTH(cttConfig.chValor) - LENGTH(mchFileName) - 1, LENGTH(cttConfig.chValor)) = ''.
	    END.
	  END.
		cobSessionManager = NEW SessionManager(cttConfig.chValor).
    /* propio de NSRA */
    Ccs.utiles.Application:SessionManager = cobSessionManager.
		/* inicializar los managers definidos */
		CreateManagers().
		RegisterExceptions().
	END METHOD.
	/*$
	[es]
	Se registra en Ccs.Common.Application como StartupManager.
	[en]
	Registers itself as Ccs.Common.Application:StartupManager.
	$*/
	CONSTRUCTOR StartupManager():
	  Ccs.Common.Application:StartupManager = THIS-OBJECT.
	END CONSTRUCTOR.
END CLASS.
