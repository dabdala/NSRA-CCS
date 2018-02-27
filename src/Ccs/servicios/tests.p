
/*------------------------------------------------------------------------
    File        : Ccs.servicios.tests.p
    Purpose     : Run some tests on CCS implementation.

    Syntax      :

    Description : This should be a set of tests that allows for conformance test of the
                  implementation. As writting so many tests is a lot of effort, only
                  some basic tests have been written.
                  You are more than welcome to write more, more, and more tests.

    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Mon Feb 19 16:45:32 ART 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */

/* ***************************  Main Block  *************************** */
PROCEDURE pruebaBEgetData:
  DEFINE VARIABLE lobEtapa AS Ccs.BusinessLogic.IBusinessEntity NO-UNDO.
  DEFINE VARIABLE lhdDataset AS HANDLE NO-UNDO.
  DEFINE VARIABLE lobResponse AS Ccs.BusinessLogic.IGetDataResponse NO-UNDO.
  DEFINE VARIABLE lobRequest AS Ccs.utiles.DataRequest NO-UNDO.
  
  lobEtapa = CAST(Ccs.Common.Application:ServiceManager:getService(GET-CLASS(Ccs.dao.Etapa)),Ccs.dao.Etapa).
  
  lobEtapa:getDataSet(OUTPUT DATASET-HANDLE lhdDataSet). 
  lobRequest = NEW Ccs.utiles.DataRequest(lhdDataSet).
  DELETE OBJECT lhdDataSet NO-ERROR.
  lhdDataSet = ?.
  CAST(lobRequest:TableRequests[1],Ccs.utiles.TableRequest):NumRecords = 2.
  CAST(lobRequest:TableRequests[1],Ccs.utiles.TableRequest):QueryString = 'EsInicio EQ TRUE'.  
  lobResponse = lobEtapa:getData(lobRequest,OUTPUT DATASET-HANDLE lhdDataSet).
  
  DEFINE VARIABLE lhnQuery AS HANDLE NO-UNDO.
  DEFINE VARIABLE lhnBuffer AS HANDLE NO-UNDO.
  
  lhnBuffer = lhdDataSet:GET-BUFFER-HANDLE (1).
  CREATE QUERY lhnQuery.
  lhnQuery:SET-BUFFERS (lhnBuffer).
  lhnQuery:QUERY-PREPARE('FOR EACH ' + lhnBuffer:TABLE).
  lhnQuery:QUERY-OPEN.
  DO WHILE lhnQuery:GET-NEXT():
    DISPLAY lhnBuffer:BUFFER-FIELD(1):BUFFER-VALUE.
  END.
  lhnQuery:QUERY-CLOSE.
  FINALLY:
    DELETE OBJECT lobEtapa NO-ERROR. 
    DELETE OBJECT lhdDataSet NO-ERROR.
    DELETE OBJECT lobRequest NO-ERROR.
    DELETE OBJECT lobResponse NO-ERROR.
    DELETE OBJECT lhnQuery NO-ERROR.
  END FINALLY.
END PROCEDURE.

PROCEDURE pruebaNSRASW:
  DEFINE VARIABLE lobService AS Ccs.Common.IService NO-UNDO.
  DEFINE VARIABLE lobInvocable AS Ccs.utiles.IInvokable NO-UNDO.
  DEFINE VARIABLE lobParS AS Ccs.utiles.IServiceParams NO-UNDO.
  
  lobService = CAST(Ccs.Common.Application:ServiceManager:getService(?,'proccompra.esVerificador'),Ccs.Common.IService).
  IF TYPE-OF(lobService,Ccs.utiles.IInvokable) THEN DO:
    lobInvocable = CAST(lobService,Ccs.utiles.IInvokable).
    lobPars = lobInvocable:serviceParams.
    lobInvocable:invoke(INPUT-OUTPUT lobPars).
    DISPLAY lobPars:getOutput(1).
  END.
  FINALLY:
    DELETE OBJECT lobService NO-ERROR.
  END FINALLY.
END PROCEDURE.

/*
[es]
Dado que CCS requiere el uso de CLIENT-PRINCPAL, creo uno "ficticio".
Solo funciona si la configuración del SessionManager permite el ingreso inseguro.
[en]
Due to the CCS requirement for CLIENT-PRINCIPAL, a "fake" one is created.
Only works if SessionManager config allows for insecure access.
*/
DEFINE VARIABLE lhnClientPrincipal AS HANDLE NO-UNDO.

CREATE CLIENT-PRINCIPAL lhnClientPrincipal.
SECURITY-POLICY:REGISTER-DOMAIN ('CCSTEST','CCSTEST','CCS test domain','voidauth') NO-ERROR.
SECURITY-POLICY:LOCK-REGISTRATION () NO-ERROR.
lhnClientPrincipal:INITIALIZE ('david.abdala').
lhnClientPrincipal:DOMAIN-NAME = 'CCSTEST'.
lhnClientPrincipal:SESSION-ID = 'NSRAsess'.
IF NOT lhnClientPrincipal:SEAL('CCSTEST') THEN
  UNDO, THROW NEW Progress.Lang.AppError('error',1).

Ccs.Common.Application:SessionManager:establishRequestEnvironment(lhnClientPrincipal).
RUN pruebaNSRASW.
RUN pruebaBEgetData.
Ccs.Common.Application:SessionManager:endRequestEnvironment().

FINALLY:
  DELETE OBJECT lhnClientPrincipal NO-ERROR.
END FINALLY.
