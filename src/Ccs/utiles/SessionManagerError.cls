 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.SessionManagerError
    Purpose     : Used for SessionManager Error throwing
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 21 09:04:50 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Lang.AppError.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.SessionManagerError INHERITS AppError: 		
	CONSTRUCTOR PUBLIC SessionManagerError ( INPUT errorMessage AS CHARACTER, INPUT messageNum AS INTEGER ):
		SUPER (INPUT errorMessage, INPUT messageNum).
	END CONSTRUCTOR.
END CLASS.