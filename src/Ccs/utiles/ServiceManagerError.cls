 
 /*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.ServiceManagerError
    Purpose     : Used for ServiceManager Error throwing
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 21 09:02:11 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Progress.Lang.AppError.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.ServiceManagerError INHERITS AppError: 
  CONSTRUCTOR ServiceManagerError(INPUT ipchMessage AS CHARACTER, INPUT ipinCode AS INTEGER):
    SUPER(ipchMessage,ipinCode).
  END CONSTRUCTOR.
END CLASS.