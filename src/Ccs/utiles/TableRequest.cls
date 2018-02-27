 
 /*------------------------------------------------------------------------
    File        : Ccs.BusinessLogic.TableRequest
    Purpose     : Required to be able to perform request to business entities.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Mon Feb 19 17:03:32 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.BusinessLogic.IGetDataTableRequest.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Implementación lo más básica posible para poder realizar pedidos a las entidades de negocio.
[en]
The most basic implementation that allows request to business entities.
$*/
CLASS Ccs.utiles.TableRequest IMPLEMENTS IGetDataTableRequest: 

	DEFINE PUBLIC PROPERTY NumRecords AS INT64 NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY PagingContext AS CHARACTER NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY QueryDefinition AS Ccs.BusinessLogic.IQueryDefinition NO-UNDO 
	GET.
	PRIVATE SET. 

	DEFINE PUBLIC PROPERTY QueryString AS CHARACTER NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY Skip AS INT64 NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY TableName AS CHARACTER NO-UNDO 
	GET.
	PRIVATE SET. 

  CONSTRUCTOR TableRequest(INPUT ipchTable AS CHARACTER):
    TableName = ipchTable.
  END CONSTRUCTOR.
END CLASS.