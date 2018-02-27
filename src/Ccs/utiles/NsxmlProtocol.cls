
 /*------------------------------------------------------------------------
    File        : Ccs.Protocol.NsxmlProtocol
    Purpose     : Wraps NSXMLProtocol to be used as an IManager.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Feb 20 12:13:13 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

{nsra/utiles/runlevel.i}
ROUTINE-LEVEL ON ERROR UNDO, THROW.

/*$
[es]
Encapsula el objeto de protocolo NSXML para ser utilizado a través del módulo CCS
[en]
Encapsulates the NSXML protocol instance to be used as an IManager.
$*/

USING Progress.Lang.*.
USING Ccs.Common.IManager.
USING nsxml.utiles.NSXMLProtocol.

CLASS Ccs.utiles.NsxmlProtocol INHERITS NSXMLProtocol IMPLEMENTS IManager: 

	METHOD PUBLIC VOID dispose(  ):
	END METHOD.

	METHOD PUBLIC VOID initialize(  ):
	END METHOD.
	
	CONSTRUCTOR NsxmlProtocol():
	  SUPER(CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager)).
	END CONSTRUCTOR.

END CLASS.