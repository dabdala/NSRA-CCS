 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.StartupManagerError
    Purpose     : Used for StartupManager Error throwing
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 21 09:01:46 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Lang.AppError.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.StartupManagerError INHERITS AppError: 

  CONSTRUCTOR StartupManagerError(INPUT ipchMessage AS CHARACTER, INPUT ipinCode AS INTEGER):
    SUPER(ipchMessage,ipinCode).
  END CONSTRUCTOR.
END CLASS.