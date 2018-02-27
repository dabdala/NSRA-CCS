 
 /*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.ServiceParamsError
    Purpose     : ServiceParams error raising.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 21 09:45:28 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Lang.AppError.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.ServiceParamsError INHERITS AppError: 
	CONSTRUCTOR PUBLIC ServiceParamsError ( INPUT errorMessage AS CHARACTER, INPUT messageNum AS INTEGER ):
		SUPER (INPUT errorMessage, INPUT messageNum).
	END CONSTRUCTOR.
END CLASS.