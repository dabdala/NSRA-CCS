 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.ClientContext
    Purpose     : Provide a way of storing information associated to the user session.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 09:50:07 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.utiles.IContext.
USING Ccs.Common.IClientContext.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Implementación de las interfaces IContext e IClientContext que permite almacenar
valores arbitrarios asociados a la sesión del usuario.
Internamente utiliza icomun.dao.SessionManager (la instancia global).
[en]
Implementation to store arbitrary information associated to the user session.
Internally uses icomun.dao.SessionManager (global instance).
$*/
CLASS Ccs.utiles.ClientContext IMPLEMENTS IClientContext, IContext:
  /*$
  [es]
  Preserva la instancia global para facilitar la implementación.
  [en]
  Preserves a reference to the global instance to easy implementation.
  $*/
  DEFINE PROTECTED PROPERTY cobSessionManager AS icomun.dao.SessionManager NO-UNDO
    GET.
    SET. 

	DEFINE PUBLIC PROPERTY clientPrincipal AS HANDLE NO-UNDO 
	GET.
	SET. 
	DEFINE PUBLIC PROPERTY contextID AS CHARACTER NO-UNDO 
	GET.
	SET. 

  /*$
  [es]
  Establece las propiedades del objeto.
  [en]
  Sets objects properties.
  $*/
	METHOD PUBLIC VOID initializeContext( INPUT phClientPrincipal AS HANDLE ):
    cobSessionManager = CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager).
		clientPrincipal = phClientPrincipal.
    contextId = cobSessionManager:cchSession.
	END METHOD.

  /*$
  [es]
  Establece las propiedades del objeto.
  [en]
  Sets objects properties.
  $*/
	METHOD PUBLIC VOID initializeContext( INPUT pcSessionID AS CHARACTER ):
    cobSessionManager = CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager).
		clientPrincipal = ?.
    contextId = cobSessionManager:cchSession.
	END METHOD.

  /*$
  [es]
  Preserva en la base de datos toda la información asociada a la sesión de usuario.
  [en]
  Preserves in database all the user related info.
  $*/
	METHOD PUBLIC VOID saveContext(  ):
    cobSessionManager:SaveChanges().
	END METHOD.
	
  METHOD PUBLIC CHARACTER getValue(INPUT chName AS CHARACTER):
    RETURN cobSessionManager:GetContextValue(chName).
  END METHOD.
  METHOD PUBLIC CHARACTER setValue(INPUT chName AS CHARACTER, INPUT chValue AS CHARACTER):
    DEFINE VARIABLE mchPrevio AS CHARACTER NO-UNDO.
    mchPrevio = cobSessionManager:getContextValue(chName).
    cobSessionManager:SaveContextValue(chName,chValue).
    RETURN mchPrevio.
  END METHOD.  
	
END CLASS.