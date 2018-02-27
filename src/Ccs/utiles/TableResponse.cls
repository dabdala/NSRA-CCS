 
 /*------------------------------------------------------------------------
    File        : Ccs.BusinessLogic.TableResponse
    Purpose     : Required for implementation of CCS business entities.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Fri Feb 16 16:11:35 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.BusinessLogic.IGetDataTableResponse.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Implementación lo más básica posible para permitir el uso de entidades de negocio CCS.
[en]
The most basic implementation possible to be able to use CCS business entities.
$*/
CLASS Ccs.utiles.TableResponse IMPLEMENTS IGetDataTableResponse: 

    DEFINE PUBLIC PROPERTY NextPagingContext AS CHARACTER NO-UNDO
    GET.
    SET.

    DEFINE PUBLIC PROPERTY PreviousPagingContext AS CHARACTER NO-UNDO
    GET.
    SET.

    DEFINE PUBLIC PROPERTY TableName AS CHARACTER NO-UNDO
    GET.
    SET.

END CLASS.