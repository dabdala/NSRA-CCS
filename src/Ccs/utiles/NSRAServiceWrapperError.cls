 
 /*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.NSRAServiceWrapperError
    Purpose     : Exception class for NSRAServiceWrappers
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 21 09:16:26 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Lang.AppError.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.NSRAServiceWrapperError INHERITS AppError: 
	CONSTRUCTOR PUBLIC NSRAServiceWrapperError ( INPUT errorMessage AS CHARACTER, INPUT messageNum AS INTEGER ):
		SUPER (INPUT errorMessage, INPUT messageNum).
	END CONSTRUCTOR.
END CLASS.