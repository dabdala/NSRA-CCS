 
 /*------------------------------------------------------------------------
    File        : Ccs.BusinessLogic.Etapa
    Purpose     : Provide access to DAO Etapa as a CCS business entity.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Fri Feb 16 17:11:06 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.utiles.NSRABusinessEntityWrapper.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.dao.Etapa INHERITS NSRABusinessEntityWrapper: 

	METHOD OVERRIDE PROTECTED nsra.dao.BasicDAO getMyDAOInstance(  ):
	  DEFINE VARIABLE mobDAO AS nsra.dao.BasicDAO NO-UNDO.
	  mobDAO = CAST(CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager):cobBroker:NewObject(compras.utiles.ClasesDAO:Etapa),nsra.dao.BasicDAO).
	  RETURN mobDAO.
	END METHOD.
	
	CONSTRUCTOR Etapa():
	  SUPER().
	  CAST(cobDAO,compras.dao.Etapa):cobACL.
	END CONSTRUCTOR.

END CLASS.