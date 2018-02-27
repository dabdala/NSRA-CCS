 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.NSRATranslator
    Purpose     : Uses the NSRA translator to provide messages translations.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Feb 20 12:13:13 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING icomun.dao.Traductor.
USING Ccs.utiles.ITranslationManager.
USING icomun.dao.SessionManager.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Encapsula el traductor NSRA, que ya implementa todo lo necesario para ser utilizado desde CCS.
[en]
Encapsulates NSRA translator.
$*/
CLASS Ccs.utiles.NSRATranslator IMPLEMENTS ITranslationManager:
  
  DEFINE PROTECTED VARIABLE cobTranslator AS Traductor NO-UNDO.  

	DEFINE PUBLIC PROPERTY destinationLang AS CHARACTER NO-UNDO 
  GET:
    RETURN cobTranslator:cchDestino.
  END GET.
  SET(INPUT ipchDest AS CHARACTER):
    cobTranslator:cchDestino = ipchDest.
  END SET. 

	DEFINE PUBLIC PROPERTY sourceLang AS CHARACTER NO-UNDO 
  GET:
    RETURN cobTranslator:cchOrigen.
  END GET.
  SET(INPUT ipchOrigen AS CHARACTER):
    cobTranslator:cchOrigen = ipchOrigen.
  END SET. 

	METHOD PUBLIC VOID dispose(  ):
    IF NOT TYPE-OF(Ccs.utiles.Application:SessionManager,SessionManager) THEN
      DELETE OBJECT cobTranslator.
	END METHOD.

	METHOD PUBLIC VOID initialize(  ):
	  IF TYPE-OF(Ccs.utiles.Application:SessionManager,SessionManager) THEN
      cobTranslator = CAST(Ccs.utiles.Application:SessionManager,SessionManager):cobTraductor.
    ELSE DO:
      cobTranslator = NEW Traductor().
      cobTranslator:SetSessionManager(Ccs.utiles.Application:SessionManager).
    END.
    Ccs.utiles.Application:TranslationManager = THIS-OBJECT.
	END METHOD.

	METHOD PUBLIC CHARACTER translate( INPUT sourceMEssage AS CHARACTER ):
	  RETURN cobTranslator:Traducir(sourceMessage).
	END METHOD.

	METHOD PUBLIC CHARACTER translate( INPUT messageId AS INTEGER ):
		RETURN cobTranslator:Traducir(messageId).
	END METHOD.

	METHOD PUBLIC CHARACTER translate( INPUT messageId AS INTEGER, INPUT defaultMessage AS CHARACTER ):
		RETURN cobTranslator:Traducir(messageId,defaultMessage).
	END METHOD.

END CLASS.