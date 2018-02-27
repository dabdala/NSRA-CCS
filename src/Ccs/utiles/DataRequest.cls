 
 /*------------------------------------------------------------------------
    File        : DataRequest
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala
    Created     : Mon Feb 19 17:01:14 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.BusinessLogic.IGetDataRequest.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.DataRequest IMPLEMENTS IGetDataRequest: 

	DEFINE PUBLIC PROPERTY CustomParameter AS Progress.Lang.Object NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY NamedQuery AS Ccs.BusinessLogic.INamedQuery NO-UNDO 
	GET.
	SET. 

	DEFINE PUBLIC PROPERTY TableRequests AS Ccs.BusinessLogic.IGetDataTableRequest EXTENT NO-UNDO 
	GET.
	SET. 
	
	CONSTRUCTOR DataRequest(INPUT iphdDataSet AS HANDLE):
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  EXTENT(TableRequests) = iphdDataset:NUM-BUFFERS.
	  DO minIndex = 1 TO EXTENT(TableRequests):
	    TableRequests[minIndex] = NEW Ccs.utiles.TableRequest(iphdDataSet:GET-BUFFER-HANDLE(minIndex):TABLE).
	  END.
	END CONSTRUCTOR.

END CLASS.