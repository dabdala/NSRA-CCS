 
 /*------------------------------------------------------------------------
    File        : DataResponse
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala
    Created     : Fri Feb 16 16:09:15 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.BusinessLogic.IGetDataResponse.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.DataResponse IMPLEMENTS IGetDataResponse: 

	DEFINE PUBLIC PROPERTY CustomResponse AS Progress.Lang.Object NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY TableResponses AS Ccs.BusinessLogic.IGetDataTableResponse EXTENT NO-UNDO 
	GET.
	SET. 
	
END CLASS.