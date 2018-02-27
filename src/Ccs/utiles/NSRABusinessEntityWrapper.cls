 {nsra/utiles/runlevel.i}
 /*------------------------------------------------------------------------
    File        : Ccs.BusinessLogic.NSRABusinessEntityWrapper
    Purpose     : Provide access to NSRA business entities through CCS interfaces
    Syntax      : 
    Description : Implements CCS interfaces by using an underlying nsra.dao.BasicDAO.
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Wed Feb 14 10:57:43 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.BusinessLogic.ISupportNamedOperations.
USING Ccs.BusinessLogic.IUpdatableBusinessEntity.

ROUTINE-LEVEL ON ERROR UNDO, THROW.
/*$
[es]
Dado que CCS asume que los servicios son objetos, en los cuales se invocan métodos, pero
NSRA implementa los servicios como procedimientos internos, que utilizan las entidades de
negocio para realizar el trabajo real, es necesario proveer un mecanismo que permita
utilizar las clases de negocio NSRA como clases de negocio CCS.
Esta clase implementa toda la lógica genérica necesaria para acceder la funcionalidad
de una clase DAO NSRA a través de CCS, como una entidad de negocio CCS.
Lo que en CCS son considerados "NamedOperations" se determinan en base a los parámetros
de los métodos de la clase, de forma automática, lo que implica que si se quiere
exponer un método de una clase DAO como una operación con nombre CCS, solo es necesario
declararla con los parámetros y tipo de retorno correctos, para que automáticamente
sea considerada una "NamedOperation".
Para publicar una clase DAO NSRA como una entidad de negocio CCS, se debe crear una
instancia derivada de esta clase y sobrescribir el método getMyDAOInstance que debe
devolver una instancia de la clase DAO que se quiere exponer.
Se debe tener en cuenta que si la clase DAO tiene una estructura interna con delegados, se
deben crear instancias de los delegados en los constructores de la clase DAO, para
garantizar que al momento de usar la clase a través de CCS, funcione correctamente
la recuperación y persistencia de datos en estructuras complejas de datos. 
[en]
Due to the fact that CCS assumes services are objects in which you invoke methods, but NSRA
implements services as internal procedures that intensively uses DAO classes (busines classes)
to do the actual job, some way of using NSRA business classes as CCS business classes.
This class implements all the required glue code to be able to use NSRA business classes as
CCS business classes, unchanged.
The concept of "NamedOperations" is taken into account, publishing as such any method of the
business entity that complies with the calling convention for named operations: return type
and parameters type. 
To publish an NSRA DAO class as CCS class you need to write a derived class from this class
and implement getMyDAOInstance method, which has to return an instance of the DAO class you
are willing to publish as CCS business entity.
Take into account that if DAO class has an internal structure with "delegate" classes, you
must instantiate all the delegate classes in all the class constructors, to guarantee that
the CCS wrapper is able to retrieve and persist data in complex data structures. 
$*/
CLASS Ccs.utiles.NSRABusinessEntityWrapper IMPLEMENTS ISupportNamedOperations, IUpdatableBusinessEntity ABSTRACT:
  /*$
  [es]
  Preserva las referencias a las instancias delegadas de la clase DAO principal, que operan
  sobre las tablas "inferiores" del DataSet.
  [en]
  Preserves the references to the delegated instances of the DAO instance, that operates
  on the "child" DataSet tables.
  $*/
  DEFINE PROTECTED TEMP-TABLE cttDelegados NO-UNDO
    /*$
    [es]
    Nombre de la tabla en el DataSet
    [en]
    Table name in DataSet
    $*/
    FIELD chTabla AS CHARACTER
    /*$
    [es]
    Instancia nsra.dao.BaseDAODelegate responsable de la tabla.
    [en]
    nsra.dao.BaseDAODelegate instance responsible for the table.
    $*/
    FIELD obDelegado AS Progress.Lang.Object
  {&END}
  
  /*$
  [es]
  Lista de nombres de métodos que satisfacen los criterios para ser "NamedOperations"
  [en]
  List of methods satisfying NamedOperations calling convention.
  $*/
  DEFINE PROTECTED PROPERTY cchNamedOperations AS CHARACTER EXTENT NO-UNDO
    GET.
    SET.
  /*
  Necesario para poder realizar la instanciación tardía de la clase y
  poder verificar correctamente cuando ya no es necesaria.
  ---
  Required for the cobDAO property implementation.
  */
  DEFINE PRIVATE VARIABLE cobInternalDAO AS nsra.dao.BasicDAO NO-UNDO.
  /*$
  [es]
  Instancia de la clase de negocio NSRA que se está publicando como clase de negocio
  CCS.
  Se utiliza instanciación tardía de la clase.
  Se libera al asignar ?.
  [en]
  NSRA business entity instance to publish as CCS business entity.
  Uses late instantiation.
  Instance is release when ? is assigned.
  $*/
  DEFINE PROTECTED PROPERTY cobDAO AS CLASS nsra.dao.BasicDAO NO-UNDO
    GET:
      IF NOT VALID-OBJECT(cobInternalDAO) THEN
        cobInternalDAO = getMyDAOInstance().
      RETURN cobInternalDAO.
    END GET.
    PRIVATE SET(INPUT ipobDAO AS CLASS nsra.dao.BasicDAO):
      IF ipobDAO EQ ? THEN
        CAST(Ccs.utiles.Application:SessionManager,icomun.dao.SessionManager):cobBroker:freeObject(cobInternalDAO).
      IF VALID-OBJECT(cobInternalDAO) THEN DO:
        cchNamedOperations = ?.
        EMPTY TEMP-TABLE cttDelegados.
      END.
      cobInternalDAO = ipobDAO.
    END SET. 
  /*$
  [es]
  Copia del DataSet de la instancia DAO, necesario para obtener las clases
  derivadas y procesar correctamente los pedidos de datos y de cambios.
  Se elimina cuando se asigna ?.
  [en]
  Copy of the DAO instance DataSet, requiered to obtain delegates and 
  to properly process data, and change, requests.
  Feed when ? is assigned.
  $*/
  DEFINE PROTECTED PROPERTY chnDataSet AS HANDLE NO-UNDO
    GET:
      IF NOT VALID-HANDLE(chnDataSet) THEN
        chnDataSet = cobDAO:getDataSetCopy().
      RETURN chnDataSet.
    END GET.
    SET(INPUT iphnDataSet AS HANDLE):
      IF iphnDataSet EQ ? AND VALID-HANDLE(chnDataSet) THEN
        DELETE OBJECT chnDataSet.
      chnDataSet = iphnDataSet.
    END SET.
  /*$
  [es]
  Las clases derivadas deben devolver la instancia DAO correspondiente.
  [en]
  Derived classes must return the right DAO instance.
  $*/
  METHOD PROTECTED ABSTRACT nsra.dao.BasicDAO getMyDAOInstance().
  
  /*$
  [es]
  Devuelve una instancia de clase delegada correspondiente a la
  tabla especificada, si existe una disponible.
  [en]
  Returns the delegate class responsible for the provided table, if
  one exists.
  $*/
  METHOD PROTECTED nsra.dao.BaseDAODelegate encontrarDelegado(INPUT ipchTabla AS CHARACTER):
    DEFINE VARIABLE mobDelegado AS nsra.dao.BaseDAODelegate NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mhnPBuff AS HANDLE NO-UNDO.
    
    FIND cttDelegados WHERE chTabla EQ ipchTabla NO-ERROR.
    IF NOT AVAILABLE cttDelegados THEN DO:
      /* encontrar la clase padre del delegado */
      mhnPBuff = chnDataSet:GET-BUFFER-HANDLE (ipchTabla):PARENT-RELATION:PARENT-BUFFER.
      IF mhnPBuff EQ chnDataSet:GET-BUFFER-HANDLE(1) THEN
        mobDelegado = cobDAO:GetDelegate(0,TRUE,chnDataSet:GET-BUFFER-HANDLE (ipchTabla):TABLE-HANDLE:PRIVATE-DATA).
      ELSE
        mobDelegado = encontrarDelegado(mhnPBuff:TABLE-HANDLE:NAME).
    END.
    CREATE cttDelegados.
    ASSIGN
      cttDelegados.chTabla = ipchTabla
      cttDelegados.obDelegado = mobDelegado
    {&END}
  END METHOD.
  /*$
  [es]
  Libera la instancia DAO y la copia del DAtaset.
  [en]
  Frees DAO instance and DataSet copy.
  $*/
	METHOD PUBLIC VOID dispose(  ):
	  chnDataSet = ?.
		cobDAO = ?.
	END METHOD.
	/*$
	[es]
	Forma horrorosa de obtener un valor encapsulado como caracter.
	[en]
	Horrible way of getting a wrapped value as a character.
	$*/
	METHOD PUBLIC CHARACTER getHolderValue(INPUT ipobHolder AS CLASS Ccs.Common.Support.IPrimitiveHolder, INPUT iplgRequireChar AS LOGICAL):
	 DEFINE VARIABLE mchValor AS CHARACTER NO-UNDO.
	 IF TYPE-OF(ipobHolder,Ccs.Common.Support.ICharacterHolder) THEN
     mchValor = CAST(ipobHolder,Ccs.Common.Support.ICharacterHolder):Value.
	 ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IDateHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IDateHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IDateTimeHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IDateTimeHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IDateTimeTzHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IDateTimetZHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IDecimalHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IDecimalHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IInt64Holder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IInt64Holder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IIntegerHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IIntegerHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.ILogicalHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.ILogicalHolder):Value).
   ELSE IF TYPE-OF(ipobHolder,Ccs.Common.Support.IRowidHolder) THEN
     mchValor = STRING(CAST(ipobHolder,Ccs.Common.Support.IRowidHolder):Value).
   ELSE
     mchValor = '?'.
   IF iplgRequireChar EQ TRUE AND (LENGTH(mchValor) LE 2 OR LOOKUP(SUBSTRING(mchValor,1,1),'",~'') EQ 0) THEN
    mchValor = QUOTER(mchValor).
   ELSE IF iplgRequireChar EQ FALSE AND LENGTH(mchValor) GT 2
      AND LOOKUP(SUBSTRING(mchValor,1,1),'",~'') GT 0 
      AND SUBSTRING(mchValor,1,1) EQ SUBSTRING(mchValor,LENGTH(mchValor),1) THEN ASSIGN
    SUBSTRING(mchValor,LENGTH(mchValor),1) = ''
    SUBSTRING(mchValor,1,1) = ''
   {&END}  
	 RETURN mchValor.
	END METHOD.
  /*$
  [es]
  Implementación "completa" del método que devuelve registros de la instancia DAO.
  [en]
  "complete" implementation of the returning of DAO data records.
  $*/
	METHOD PUBLIC Ccs.BusinessLogic.IGetDataResponse getData( INPUT poRequest AS Ccs.BusinessLogic.IGetDataRequest, OUTPUT DATASET-HANDLE phDataset ):
		DEFINE VARIABLE mobTReq AS Ccs.BusinessLogic.IGetDataTableRequest EXTENT NO-UNDO.
		DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
		DEFINE VARIABLE mchFill AS CHARACTER NO-UNDO.
		DEFINE VARIABLE mchFilter AS CHARACTER NO-UNDO.
		DEFINE VARIABLE mobDelegado AS nsra.dao.BaseDAODelegate NO-UNDO.
		DEFINE VARIABLE mhtTable AS HANDLE NO-UNDO.
		DEFINE VARIABLE mobResponse AS Ccs.utiles.DataResponse NO-UNDO.
		DEFINE VARIABLE mobTableData AS Ccs.utiles.TableResponse NO-UNDO.
		DEFINE VARIABLE minRows AS INTEGER NO-UNDO.
		mobResponse = NEW Ccs.utiles.DataResponse().
		mobTReq = poRequest:TableRequests.
		mchFill = chnDataSet:GET-BUFFER-HANDLE(1):NAME. 
		EXTENT(mobResponse:TableResponses) = EXTENT(mobTReq).
		DO minIndex = 1 TO EXTENT(mobTReq):
		  IF mchFill EQ mobTReq[minIndex]:TableName THEN DO:
		    /* entidad principal */
		    IF LENGTH(mobTReq[minIndex]:PagingContext) GT 0 THEN
		      cobDAO:cchNextBatch =  mobTReq[minIndex]:PagingContext.
		    IF mobTReq[minIndex]:NumRecords GT 0 THEN DO:
		      IF mobTReq[minIndex]:Skip GT 0 THEN
            cobDAO:cinBatchSize = mobTReq[minIndex]:NumRecords + mobTReq[minIndex]:Skip.
		      ELSE
            cobDAO:cinBatchSize = mobTReq[minIndex]:NumRecords.
		    END.
		    IF LENGTH(mobTReq[minIndex]:QueryString) EQ 0 THEN
		      mchFill = AssembleQuery(mobTReq[minIndex]:QueryDefinition).
		    ELSE
		      mchFill = mobTReq[minIndex]:QueryString.
		  END.
		  ELSE DO:
		    /* obtener el objeto que se encarga de esta tabla */
		    mobDelegado = encontrarDelegado(mobTReq[minIndex]:TableName).
		    IF NOT VALID-OBJECT(mobDelegado) THEN
		      NEXT.
        IF mobTReq[minIndex]:NumRecords GT 0 THEN DO:
          IF mobTReq[minIndex]:Skip GT 0 THEN
            mobDelegado:cinBatchSize = mobTReq[minIndex]:NumRecords + mobTReq[minIndex]:Skip.
          ELSE
            mobDelegado:cinBatchSize = mobTReq[minIndex]:NumRecords.
        END.
        IF LENGTH(mobTReq[minIndex]:QueryString) EQ 0 THEN
          mobDelegado:SetFilter(AssembleQuery(mobTReq[minIndex]:QueryDefinition)).
        ELSE
          mobDelegado:SetFilter(mobTReq[minIndex]:QueryString).
		  END.
		END.
    cobDAO:FillData(mchFill,TRUE).
		/* ya está hecho el llenado del DAO, obtener los datos para cada tabla */
		getDataSet(OUTPUT DATASET-HANDLE phDataSet).
    mchFill = chnDataSet:GET-BUFFER-HANDLE(1):NAME. 
    DO minIndex = 1 TO EXTENT(mobTReq):
      mobTableData = NEW Ccs.utiles.TableResponse().
      mobResponse:TableResponses[minIndex] = mobTableData.
      mobTableData:TableName = mobTReq[minINdex]:TableName.
      IF mchFill EQ mobTReq[minIndex]:TableName THEN DO:
        IF mobTReq[minIndex]:Skip GT 0 THEN DO:
          minIndex = mobTReq[minIndex]:Skip.
          cobDAO:FirstRow().
          DO WHILE minIndex GT 0:
            minIndex = minIndex - 1.
            cobDAO:NextRow().
          END.
        END.
        minRows = INTEGER(mobTReq[minIndex]:NumRecords).
        IF minRows LE 0 THEN
          minRows = 100000.
        cobDAO:FillTempTable(phDataSet:GET-BUFFER-HANDLE (mobTReq[minIndex]:TableName):TABLE-HANDLE,minRows,TRUE,FALSE,0,FALSE).
        mobTableData:NextPagingContext = cobDAO:cchNextBatch.
      END.
      ELSE DO:
        /* obtener el objeto que se encarga de esta tabla */
        mobDelegado = encontrarDelegado(mobTReq[minIndex]:TableName).
        IF NOT VALID-OBJECT(mobDelegado) THEN
          NEXT.
        mhtTable = phDataSet:GET-BUFFER-HANDLE (mobTReq[minIndex]:TableName).
        IF mobTReq[minIndex]:Skip GT 0 THEN
          mobDelegado:FillFullTempTable(mhtTable,INTEGER(mobTReq[minIndex]:NumRecords),FALSE,TRUE,?,0,TRUE).
        ELSE.
          mobDelegado:FillFullTempTable(mhtTable,INTEGER(mobTReq[minIndex]:NumRecords),TRUE,FALSE,?,0,FALSE).
      END.
    END.
		RETURN mobResponse.
	END METHOD.

  /*$
  [es]
  Devuelve una copia, de la copia local, del dataset de la clase DAO.
  El receptor es responsable del borrado de la copia.
  [en]
  Returns a copy, of the local copy, of DAO Dataset.
  Caller is responsible for the deletion of the copy.
  $*/
	METHOD PUBLIC VOID getDataset( OUTPUT DATASET-HANDLE phDataset ):
		CREATE DATASET phDataset.
		phDataSet:CREATE-LIKE(chnDataSet).
	END METHOD.
	/*$
	[es]
  Recorre todos los valores del arreglo y los procesa como igualdad al campo,
  o como criterios de rango que debe tener el campo.
  Devuelve la cadena correspondiente.
	[en]
	Process the array as a field equality, or a range criteria.
	Returns the corresponding query string.
	$*/
  METHOD PROTECTED CHARACTER getMultiQuery(INPUT ipchField AS CHARACTER, INPUT iplgRango AS LOGICAL,INPUT ipobArrayHolder AS CLASS Ccs.Common.Support.IPrimitiveArrayHolder):
    DEFINE VARIABLE mchValor AS CHARACTER EXTENT NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mchOp AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchQuery AS CHARACTER NO-UNDO.
    DEFINE VARIABLE mchHolder AS Ccs.Common.Support.ICharacterArrayHolder NO-UNDO.
    DEFINE VARIABLE mdaHolder AS Ccs.Common.Support.IDateArrayHolder NO-UNDO.
    DEFINE VARIABLE mdtHolder AS Ccs.Common.Support.IDateTimeArrayHolder NO-UNDO.
    DEFINE VARIABLE mdzHolder AS Ccs.Common.Support.IDateTimeTzArrayHolder NO-UNDO.
    DEFINE VARIABLE mdcHolder AS Ccs.Common.Support.IDecimalArrayHolder NO-UNDO.
    DEFINE VARIABLE minHolder AS Ccs.Common.Support.IIntegerArrayHolder NO-UNDO.
    DEFINE VARIABLE mliHolder AS Ccs.Common.Support.IInt64ArrayHolder NO-UNDO.
    DEFINE VARIABLE mlgHolder AS Ccs.Common.Support.ILogicalArrayHolder NO-UNDO.
    DEFINE VARIABLE mriHolder AS Ccs.Common.Support.IRowidArrayHolder NO-UNDO.
    
    IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.ICharacterArrayHolder) THEN DO:
      mchHolder = CAST(ipobArrayHolder,Ccs.Common.Support.ICharacterArrayHolder).
      EXTENT(mchValor) = EXTENT(mchHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateArrayHolder) THEN DO:
      mdaHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IDateArrayHolder).
      EXTENT(mchValor) = EXTENT(mdaHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateTimeArrayHolder) THEN DO:
      mdtHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IDateTimeArrayHolder).
      EXTENT(mchValor) = EXTENT(mdtHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateTimeTzArrayHolder) THEN DO:
      mdzHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IDateTimeTzArrayHolder).
      EXTENT(mchValor) = EXTENT(mdzHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDecimalArrayHolder) THEN DO:
      mdcHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IDecimalArrayHolder).
      EXTENT(mchValor) = EXTENT(mdcHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IInt64ArrayHolder) THEN DO:
      mliHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IInt64ArrayHolder).
      EXTENT(mchValor) = EXTENT(mliHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IIntegerArrayHolder) THEN DO:
      minHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IIntegerArrayHolder).
      EXTENT(mchValor) = EXTENT(minHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.ILogicalArrayHolder) THEN DO:
      mlgHolder = CAST(ipobArrayHolder,Ccs.Common.Support.ILogicalArrayHolder).
      EXTENT(mchValor) = EXTENT(mlgHolder:Value).
    END.
    ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IRowidArrayHolder) THEN DO:
      mriHolder = CAST(ipobArrayHolder,Ccs.Common.Support.IRowidArrayHolder).
      EXTENT(mchValor) = EXTENT(mriHolder:Value).
    END.  
    mchOp = 'EQ'.  
    DO minIndex = 1 TO EXTENT(mchValor):
      IF iplgRango THEN DO:
        IF minIndex EQ 1 OR mchOp EQ 'LT' THEN
          mchOp = 'GT'.
        ELSE
          mchOp = 'LT'.
      END.
      IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.ICharacterArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + QUOTER(mchHolder:Value[minIndex]).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + QUOTER(STRING(mdaHolder:Value[minIndex])).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateTimeArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + QUOTER(STRING(mdtHolder:Value[minIndex])).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDateTimeTzArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + QUOTER(STRING(mdzHolder:Value[minIndex])).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IDecimalArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + STRING(mdcHolder:Value[minIndex]).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IInt64ArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + STRING(mliHolder:Value[minIndex]).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IIntegerArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + STRING(minHolder:Value[minIndex]).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.ILogicalArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + STRING(mlgHolder:Value[minIndex]).
      ELSE IF TYPE-OF(ipobArrayHolder,Ccs.Common.Support.IRowidArrayHolder) THEN
        mchValor[minIndex] = ipchField + ' ' + mchOp + ' ' + STRING(mriHolder:Value[minIndex]).
    END.
    mchQuery = mchValor[1].
    DO minIndex = 2 TO EXTENT(mchValor):
      mchQuery = mchQuery + ' AND ' + mchValor[minIndex].
    END.
    RETURN mchQuery.
	END METHOD.
	/*$
	[es]
	Recibe una porción de una consulta y devuelve la cadena correspondiente, funciona recursivamente
	[en]
	Receives a query portion and returns the corresponding string query. Recursive.
	$*/
	METHOD PROTECTED CHARACTER buildQuery(INPUT ipobPorcion AS CLASS Ccs.BusinessLogic.IQueryEntry):
	  DEFINE VARIABLE mchQuery AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE mobGrupo AS Ccs.BusinessLogic.IQueryGroup NO-UNDO.
	  DEFINE VARIABLE mobPorcion AS Ccs.BusinessLogic.IQueryPredicate NO-UNDO.
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  DEFINE VARIABLE mlgCerrarPar AS LOGICAL NO-UNDO.
	  
	  IF TYPE-OF(ipobPorcion,Ccs.BusinessLogic.IQueryGroup) THEN DO:
	    mobGrupo = CAST(ipobPorcion,Ccs.BusinessLogic.IQueryGroup).
	    DO minIndex = 1 TO EXTENT(mobGrupo:Entries):
	      mlgCerrarPar = FALSE.
	      IF minIndex GT 1 THEN DO:
	        CASE mobGrupo:Entries[minIndex]:Join:
	         WHEN Ccs.BusinessLogic.JoinEnum:And THEN
             mchQuery = mchQuery + ' AND '.
           WHEN Ccs.BusinessLogic.JoinEnum:Or THEN
             mchQuery = mchQuery + ' OR '.
           WHEN Ccs.BusinessLogic.JoinEnum:AndNot THEN DO:
             mchQuery = mchQuery + ' AND NOT ( '.
             mlgCerrarPar = TRUE.
           END.
           WHEN Ccs.BusinessLogic.JoinEnum:OrNot THEN DO:
             mchQuery = mchQuery + ' OR NOT ( '.
             mlgCerrarPar = TRUE.
           END.
          END.	        
	      END.
	      ELSE IF mobGrupo:Entries[minIndex]:Join EQ Ccs.BusinessLogic.JoinEnum:Not THEN DO:
	       mchQuery = mchQuery + ' NOT ( '.
         mlgCerrarPar = TRUE.
	      END.
	      mchQuery = mchQuery + buildQuery(mobGrupo:Entries[minIndex]).
	      IF mlgCerrarPar THEN
	       mchQuery = mchQuery + ' )'.
	    END.
	  END.
	  ELSE DO:
	    mobPorcion = CAST(ipobPorcion,Ccs.BusinessLogic.IQueryPredicate).
	    mchQuery = mobPorcion:FieldName.
	    CASE mobPorcion:Operator:
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Begins THEN
         mchQuery = mchQuery + ' BEGINS ' + getHolderValue(mobPorcion:Value,TRUE).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Contains THEN
         mchQuery = mchQuery + ' CONTAINS ' + getHolderValue(mobPorcion:Value,TRUE).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Eq THEN
         mchQuery = mchQuery + ' EQ ' + getHolderValue(mobPorcion:Value,?).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Ge THEN
         mchQuery = mchQuery + ' GE ' + getHolderValue(mobPorcion:Value,?).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Gt THEN
         mchQuery = mchQuery + ' GT ' + getHolderValue(mobPorcion:Value,?).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:InList THEN
         mchQuery = getMultiQuery(mobPorcion:FieldName,FALSE,mobPorcion:Values).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:InRange THEN
         mchQuery = getMultiQuery(mobPorcion:FieldName,TRUE,mobPorcion:Values).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Le THEN
         mchQuery = mchQuery + ' LE ' + getHolderValue(mobPorcion:Value,?).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Lt THEN
         mchQuery = mchQuery + ' LT ' + getHolderValue(mobPorcion:Value,?).
       WHEN Ccs.BusinessLogic.QueryOperatorEnum:Matches THEN
         mchQuery = mchQuery + ' MATCHES "*' + getHolderValue(mobPorcion:Value,FALSE) + '*"'.
	    END.
	    
      IF mobPorcion:Join EQ Ccs.BusinessLogic.JoinEnum:Not THEN
       mchQuery = 'NOT (' + mchQuery + ')'.
	  END.
	  RETURN mchQuery.
	END METHOD.
  /*$
  [es]
  Recibe la definición "estructurada" de una consulta y la ensambla en algo entendible por la clase DAO.
  [en]
  Receives the "structured" query and assembles it to a query string usable by DAO classes.
  $*/
  METHOD PROTECTED CHARACTER AssembleQuery(INPUT ipobQueryParts AS CLASS Ccs.BusinessLogic.IQueryDefinition):
    DEFINE VARIABLE mchQuery AS CHARACTER NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    
    IF ipobQueryParts EQ ? THEN
      RETURN ''.
    mchQuery = buildQuery(ipobQueryParts:QuerySelection).
    DO minIndex = 1 TO EXTENT(ipobQueryParts:QuerySort):
      mchQuery = mchQuery + ' BY ' + ipobQueryParts:QuerySort[minIndex]:FieldName.
      IF ipobQueryParts:QuerySort[minIndex]:SortOrder EQ Ccs.BusinessLogic.SortOrderEnum:Descending THEN
        mchQuery = mchQuery + ' DESC'.
    END.
    RETURN mchQuery.
  END METHOD.
  /*$
  [es]
  Obtiene todos los métodos públicos de la clase DAO y "quita" los métodos conocidos genéricos,
  dejando los métodos específicos de la clase, como "operaciones con nombre", siempre y cuando
  respeten las indicaciones de la especificación:
  - Un parámetro de tipo Handle y, opcionalmente, un segundo parámetro de tipo objeto.
  - Devuelve un objeto
  [en]
  Obtains all the public methods of the DAO class, ignoring base known methods,
  and leaving class specific methods that comply with "NamedOperations" calling
  conventions:
     - A HANDLE parameter and, optionally, a second Object parameter.
     - Returns an object.  
  $*/
	METHOD PUBLIC CHARACTER EXTENT getNamedOperations(  ):
	  DEFINE VARIABLE mobMethods AS Progress.Reflect.Method EXTENT NO-UNDO.
	  DEFINE VARIABLE mobParams AS Progress.Reflect.Parameter EXTENT NO-UNDO.
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  DEFINE VARIABLE mchValidos AS CHARACTER NO-UNDO.
	  
	  IF EXTENT(cchNamedOperations) EQ 0 THEN DO:
      mobMethods = cobDAO:GetClass():GetMethods(Progress.Reflect.Flags:Public).
      DO minIndex = 1 TO EXTENT(mobMethods):
        IF LOOKUP(mobMethods[minIndex]:OriginatingClass:TypeName,'nsra.dao.BasicDAO,nsra.dao.BaseDAO') GT 0 THEN
          NEXT.
        IF mobMEthods[minIndex]:NumParameters GT 2 THEN
          NEXT.
        IF mobMethods[minIndex]:ReturnType NE Progress.Reflect.DataType:Void AND
           mobMethods[minIndex]:ReturnType NE Progress.Reflect.DataType:Object THEN
          NEXT.
        mobParams = mobMethods[minIndex]:GetParameters().
        IF mobParams[1]:DataType NE Progress.Reflect.DataType:DataSetHandle THEN
          NEXT.
        IF mobparams[2]:DataType NE Progress.Reflect.DataType:Object THEN
          NEXT.
        mchValidos = mchValidos + ',' + STRING(minIndex).
      END.
      IF mchValidos NE '' THEN DO:
        SUBSTRING(mchValidos,1,1) = ''.
        EXTENT(cchNamedOperations) = NUM-ENTRIES(mchValidos).
        DO minIndex = 1 TO NUM-ENTRIES(mchValidos):
          cchNamedOperations[minIndex] = mobMethods[INTEGER(ENTRY(minIndex,mchValidos))]:Name.
        END. 
      END.
    END.    
    RETURN cchNamedOperations.
	END METHOD.
  /*$
  [es]
  No implementado por el momento.
  [en]
  Not yet implemented.
  $*/
	METHOD PUBLIC Ccs.BusinessLogic.IGetResultCountResponse getResultCount( INPUT poRequest AS Ccs.BusinessLogic.IGetDataRequest ):		
		UNDO, THROW NEW Progress.Lang.AppError("METHOD NOT IMPLEMENTED").
	END METHOD.
  /*$
  [es]
  Obtiene la instancia DAO a utilizar, o explota.
  [en]
  Obtains the DAO instance to use, or explodes.
  $*/
	METHOD PUBLIC VOID initialize(  ):
	  IF NOT VALID-OBJECT(cobDAO) THEN
	   UNDO, THROW NEW Progress.Lang.AppError('UNABLE TO INSTANTIATE NSRA DAO CLASS').
	END METHOD.
	
	/*$
	[es]
	Recibe un buffer y arma una cadena para realizar un FillData, o LocateRow, en el DAO correspondiente.
	Al nivel de esta clase, que no sabe nada de nada, simplemente iguala todos los campos que sea posible (no muy largos).
	[en]
	Receives a buffer and puts together a string able to be use for a FillData, or LocateRow, in the DAO instance.
	At this class leve, which knows nothing at all, simply equals fields that are not too long to be used.
	$*/
  METHOD PROTECTED CHARACTER makeRowCriteria(INPUT iphbBuffer AS HANDLE):
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  DEFINE VARIABLE mchQuery AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE mhnField AS HANDLE NO-UNDO.
	  
	  DO minIndex = 1 TO iphbBuffer:NUM-FIELDS:
	    mhnField = iphbBuffer:BUFFER-FIELD(minIndex). 
	    IF LOOKUP(mhnField:DATA-TYPE,'CHARACTER,DATE,DATETIME,DATETIME-TZ,INTEGER,INT64,DECIMAL,LOGICAL') EQ 0 THEN
	      NEXT.
	    IF mchQuery NE '' THEN
	      mchQuery = mchQuery + ' AND '.
	    IF LOOKUP(mhnField:DATA-TYPE,'CHARACTER,DATE,DATETIME,DATETIME-TZ') EQ 0 THEN
       mchQuery = mchQuery + mhnField:NAME + ' EQ ' + mhnField:BUFFER-VALUE.
	    ELSE  
       mchQuery = mchQuery + mhnField:NAME + ' EQ ' + QUOTER(STRING(mhnField:BUFFER-VALUE)).
	  END.
	  RETURN mchQuery.
	END METHOD.
  /*$
  [es]
  Aplica los cambios recibidos en el DAO, dado que no se puede garantizar que este método sea llamado luego de
  la obtención de los datos, no queda más alternativa que realizar un llenado del DAO "línea por línea", antes
  de realizar los cambios.
  [en]
  Make changes in the DAO class. Due to the fact that there is no guarantee about the DAO contents, there is no
  other option than doing a "row by row" fill of DAO, before applying changes.
  $*/
	METHOD PUBLIC Progress.Lang.Object updateData( INPUT-OUTPUT DATASET-HANDLE phDataset, INPUT poUpdateDataRequest AS Ccs.BusinessLogic.IUpdateDataRequest ):
    DEFINE VARIABLE mhqQuery AS HANDLE NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE mhbBuffer AS HANDLE NO-UNDO.
    DEFINE VARIABLE mobSetter AS icomun.utiles.IAccesoGenericoServicio NO-UNDO.
    DEFINE VARIABLE mobDAO AS nsra.dao.BaseDAO NO-UNDO.
    
    CREATE QUERY mhqQuery.
    mhbBuffer = phDataset:GET-BUFFER-HANDLE (minIndex).
    mhqQuery:SET-BUFFERS(mhbBuffer).
    mhqQuery:QUERY-PREPARE("FOR EACH " + mhbBuffer:TABLE).
    mhqQuery:QUERY-OPEN().
    /* no tengo más alternativa que hacer un llenado fila por fila */
    cobDAO:EmptyData().
    DO WHILE mhqQuery:GET-NEXT():
      cobDAO:FillData(makeRowCriteria(mhbBuffer)).
    END.    
    DO minIndex = 1 TO phDataset:NUM-BUFFERS:
      mhbBuffer = phDataset:GET-BUFFER-HANDLE (minIndex).
      IF minIndex EQ 1 THEN
        mobDAO = cobDAO.
      ELSE
        mobDAO = encontrarDelegado(mhbBuffer:TABLE).
      IF NOT VALID-OBJECT(mobDAO) THEN
        NEXT.
      IF NOT TYPE-OF(mobDAO,icomun.utiles.IAccesoGenericoServicio) THEN
        NEXT.
      mobSetter = CAST(mobDAO,icomun.utiles.IAccesoGenericoServicio).
      mhqQuery:SET-BUFFERS(mhbBuffer).
      mhqQuery:QUERY-PREPARE("FOR EACH " + mhbBuffer:TABLE + ' WHERE ROW-STATE(' + mhbBuffer:TABLE + ') EQ ROW-DELETED').
      mhqQuery:QUERY-OPEN().
      DO WHILE mhqQuery:GET-NEXT():
        mobDAO:FindRow(makeRowCriteria(mhbBuffer)).
        mobSetter:DeleteIt().
      END.
      mhqQuery:QUERY-CLOSE().
      mhqQuery:QUERY-PREPARE("FOR EACH " + mhbBuffer:TABLE + ' WHERE ROW-STATE(' + mhbBuffer:TABLE + ') EQ ROW-CREATED').
      mhqQuery:QUERY-OPEN().
      DO WHILE mhqQuery:GET-NEXT():
        mobSetter:CreateIt().
        mobSetter:AssignValues(mhbBuffer,'').
      END.
      mhqQuery:QUERY-CLOSE().
      mhqQuery:QUERY-PREPARE("FOR EACH " + mhbBuffer:TABLE + ' WHERE ROW-STATE(' + mhbBuffer:TABLE + ') EQ ROW-MODIFIED').
      mhqQuery:QUERY-OPEN().
      DO WHILE mhqQuery:GET-NEXT():
        mobDAO:FindRow(makeRowCriteria(mhbBuffer)).
        mobSetter:AssignValues(mhbBuffer,'').
      END.
      mhqQuery:QUERY-CLOSE().
    END.
    cobDAO:SaveChanges().
	END METHOD.

END CLASS.