{nsra/utiles/runlevel.i}
 /*------------------------------------------------------------------------
    File        : ServiceParams
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 11:40:34 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.utiles.IServiceParams.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.ServiceParams IMPLEMENTS IServiceParams:
  
  DEFINE PROTECTED TEMP-TABLE cttParams NO-UNDO
    FIELD inOrder AS INTEGER
    FIELD lgInput AS LOGICAL
    FIELD lgOutput AS LOGICAL
    FIELD chName AS CHARACTER
    FIELD chType AS CHARACTER
    FIELD chValue AS CHARACTER
    FIELD lcValue AS CLOB
    FIELD inInputOrder AS INTEGER
    FIELD inOutputOrder AS INTEGER
    INDEX ixParam IS PRIMARY IS UNIQUE inOrder
  {&END}

	DEFINE PUBLIC PROPERTY inputCount AS INTEGER NO-UNDO 
	GET:
	  DEFINE VARIABLE minCount AS INTEGER NO-UNDO.
	  FOR EACH cttParams WHERE cttParams.lgInput:
	    minCount = minCount + 1.
	  END.
	  RETURN minCount.
	END GET.

	DEFINE PUBLIC PROPERTY outputCount AS INTEGER NO-UNDO 
	GET:
    DEFINE VARIABLE minCount AS INTEGER NO-UNDO.
    FOR EACH cttParams WHERE cttParams.lgOutput:
      minCount = minCount + 1.
    END.
    RETURN minCount.
	END GET.
	
  DEFINE PUBLIC PROPERTY bothCount AS INTEGER NO-UNDO
  GET:
    DEFINE VARIABLE minCount AS INTEGER NO-UNDO.
    FOR EACH cttParams WHERE cttParams.lgOutput AND cttParams.lgInput:
      minCount = minCount + 1.
    END.
    RETURN minCount.
  END GET.

  DEFINE PUBLIC PROPERTY paramList AS Progress.Lang.ParameterList NO-UNDO
    GET:
      DEFINE VARIABLE mchMode AS CHARACTER NO-UNDO.
      paramList:Clear().
      FOR EACH cttParams BY cttParams.inOrder:
        ASSIGN
          mchMode = 'INPUT-OUTPUT' WHEN cttParams.lgInput AND cttparams.lgOutput
          mchMode = 'INPUT' WHEN cttparams.lgInput AND NOT cttParams.lgOutput
          mchMode = 'OUTPUT' WHEN cttParams.lgOutput AND NOT cttParams.lgInput
        {&END}
        IF cttParams.chType EQ 'LONGCHAR' THEN
          paramList:SetParameter(cttParams.inOrder,cttParams.chType,mchMode,cttParams.lcValue).
        ELSE
          paramList:SetParameter(cttParams.inOrder,cttParams.chType,mchMode,cttParams.chValue).
      END.
      RETURN paramList.
    END GET.
    PROTECTED SET(INPUT obParamList AS Progress.Lang.ParameterList):
      DELETE OBJECT paramList NO-ERROR.
      paramList = obParamList.
    END SET.
    
  DEFINE PUBLIC PROPERTY serviceName AS CHARACTER NO-UNDO
  GET.
  PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY serviceHandle AS HANDLE NO-UNDO
  GET.
  PROTECTED SET.
  
  DEFINE PUBLIC PROPERTY serviceObject AS Progress.Lang.Object NO-UNDO
  GET.
  PROTECTED SET.

	METHOD PUBLIC CHARACTER getInput( INPUT inOrder AS INTEGER ):
		FOR EACH cttParams WHERE cttParams.inInputOrder EQ inOrder:
		  RETURN cttParams.chValue.
		END.
		RETURN ?.
	END METHOD.

	METHOD PUBLIC CHARACTER getOutput( INPUT inOrder AS INTEGER ):
    FOR EACH cttParams WHERE cttParams.inOutputOrder EQ inOrder:
      RETURN cttParams.chValue.
    END.
    RETURN ?.		
	END METHOD.

  METHOD PUBLIC LONGCHAR getLongInput( INPUT inOrder AS INTEGER ):
    DEFINE VARIABLE mlcResult AS LONGCHAR NO-UNDO.
    FOR EACH cttParams WHERE cttParams.inInputOrder EQ inOrder:
      COPY-LOB cttParams.lcValue TO mlcResult.
      RETURN mlcResult.
    END.
    RETURN ?.
  END METHOD.

  METHOD PUBLIC LONGCHAR getLongOutput( INPUT inOrder AS INTEGER ):
    DEFINE VARIABLE mlcResult AS LONGCHAR NO-UNDO.
    FOR EACH cttParams WHERE cttParams.inOutputOrder EQ inOrder:
      COPY-LOB cttParams.lcValue TO mlcResult.
      RETURN mlcResult.
    END.
    RETURN ?.   
  END METHOD.

	METHOD PUBLIC VOID setInput( INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER ):
    FOR EACH cttParams WHERE cttParams.inInputOrder EQ inOrder:
      cttParams.chValue = chValue.
      LEAVE.
    END.
	END METHOD.

	METHOD PUBLIC VOID setOutput( INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER ):
    FOR EACH cttParams WHERE cttParams.inOutputOrder EQ inOrder:
      cttParams.chValue = chValue.
      LEAVE.
    END.
	END METHOD.

  METHOD PUBLIC VOID setLongInput( INPUT inOrder AS INTEGER, INPUT lcValue AS LONGCHAR):
    FOR EACH cttParams WHERE cttParams.inInputOrder EQ inOrder:
      COPY-LOB lcValue TO cttParams.lcValue.
      LEAVE.
    END.
  END METHOD.

  METHOD PUBLIC VOID setLongOutput( INPUT inOrder AS INTEGER, INPUT lcValue AS LONGCHAR ):
    FOR EACH cttParams WHERE cttParams.inOutputOrder EQ inOrder:
      COPY-LOB lcValue TO cttParams.lcValue.
      LEAVE.
    END.
  END METHOD.
  
  METHOD PUBLIC CHARACTER parameterType(INPUT inOrder AS INTEGER):
    FOR EACH cttParams WHERE cttParams.inOrder EQ inOrder:
      RETURN cttParams.chType.
    END.
    RETURN ?.
  END METHOD.
  METHOD PUBLIC CHARACTER parameterMode(INPUT inOrder AS INTEGER):
    FOR EACH cttParams WHERE cttParams.inOrder EQ inOrder:
      IF cttParams.lgInput AND cttParams.lgOutput THEN
        RETURN 'INPUT-OUTPUT'.
      IF cttParams.lgOutput THEN
        RETURN 'OUTPUT'.
      RETURN 'INPUT'.
    END.
    RETURN ?.
  END METHOD.  
	
	METHOD PROTECTED VOID setup():
    Ccs.utiles.Application:ExceptionManager:registerErrorClass(THIS-OBJECT:GetClass(),GET-CLASS(Ccs.utiles.ServiceParamsError)).    
    Ccs.utiles.Application:ExceptionManager:registerError(THIS-OBJECT:GetClass(),1,'No puede obtenerse la firma del servicio: &1').    
	END METHOD.
	
	METHOD PUBLIC VOID initialize(INPUT hnService AS HANDLE, INPUT chName AS CHARACTER):
	  DEFINE VARIABLE mchSignature AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
	  DEFINE VARIABLE mchEntry AS CHARACTER NO-UNDO.
	  DEFINE VARIABLE minInOrd AS INTEGER INITIAL 1 NO-UNDO.
	  DEFINE VARIABLE minOutOrd AS INTEGER INITIAL 1 NO-UNDO.
    
    setup().
    mchSignature = hnService:GET-SIGNATURE(chName).
    IF mchSignature EQ '' THEN DO:
      DEFINE VARIABLE mchError AS CHARACTER EXTENT 1 NO-UNDO.
      mchError[1] = chName.
      UNDO, THROW Ccs.utiles.Application:ExceptionManager:throwError(THIS-OBJECT:GetClass(),1,mchError).
    END.
    serviceHandle = hnService.
    serviceName = chName.    
    DO minIndex = 3 TO NUM-ENTRIES(mchSignature):
      mchEntry = ENTRY(minIndex, mchSignature).
      CREATE cttParams.
      ASSIGN 
        cttParams.inOrder = minIndex - 2
        cttParams.chName = ENTRY(2, mchEntry, " ")
        cttParams.chType = ENTRY(3, mchEntry, " ")
      {&END}
      IF LOOKUP('INPUT',ENTRY(1,mchEntry, " ")) GT 0 THEN ASSIGN
        cttParams.lgInput = TRUE
        cttParams.inInputOrder = minInOrd
        minInOrd = minInOrd + 1
      {&END}
      IF LOOKUP('OUTPUT',ENTRY(1,mchEntry, " ")) GT 0 THEN ASSIGN
        cttParams.lgOutput = TRUE
        cttParams.inOutputOrder = minOutOrd
        minOutOrd = minOutOrd + 1
      {&END}
    END.
    paramList = ?. 
	END METHOD.
	
  METHOD PUBLIC VOID initialize(INPUT obService AS Progress.Lang.Object, INPUT chName AS CHARACTER):
    DEFINE VARIABLE mobMethods AS CLASS Progress.Reflect.Method EXTENT NO-UNDO.
    DEFINE VARIABLE mobParams AS CLASS Progress.Reflect.Parameter EXTENT NO-UNDO.
    DEFINE VARIABLE mobParam AS Progress.Reflect.Parameter NO-UNDO.
    DEFINE VARIABLE minIndex AS INTEGER NO-UNDO.
    DEFINE VARIABLE minInOrd AS INTEGER INITIAL 1 NO-UNDO.
    DEFINE VARIABLE minOutOrd AS INTEGER INITIAL 1 NO-UNDO.
    
    setup().
    serviceObject = obService.
    serviceName = chName.
    mobMethods = obService:getClass():GetMethods().
    DO minIndex = 1 TO EXTENT(mobMethods):
      IF mobMethods[minIndex]:Name EQ chName THEN DO:
        mobParams = mobMethods[minIndex]:GetParameters().
        LEAVE.
      END.
    END.
    paramList = NEW Progress.Lang.ParameterList(EXTENT(mobParams)).
    DO minIndex = 1 TO EXTENT(mobParams):
      mobParam = mobParams[minIndex].
      CREATE cttParams.
      ASSIGN 
        cttParams.inOrder = minIndex
        cttParams.chName = mobParam:Name
        cttParams.chType = 'INTEGER' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Integer) EQ 1 
        cttParams.chType = 'INT64' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Int64) EQ 1 
        cttParams.chType = 'DATE' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Date) EQ 1 
        cttParams.chType = 'DATETIMETZ' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:DateTimeTZ) EQ 1 
        cttParams.chType = 'DATETIME' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:DateTime) EQ 1 
        cttParams.chType = 'LOGICAL' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Logical) EQ 1 
        cttParams.chType = 'LONGCHAR' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Longchar) EQ 1 
        cttParams.chType = 'CHARACTER' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Character) EQ 1 
        cttParams.chType = 'DECIMAL' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Decimal) EQ 1 OR mobParam:DataType:CompareTo(Progress.Reflect.DataType:Float) EQ 1 OR mobParam:DataType:CompareTo(Progress.Reflect.DataType:Double) EQ 1 
        cttParams.chType = 'HANDLE' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Handle) EQ 1 OR mobParam:DataType:CompareTo(Progress.Reflect.DataType:DataSetHandle) EQ 1 OR mobParam:DataType:CompareTo(Progress.Reflect.DataType:TableHandle) EQ 1
        cttParams.chType = 'Progress.Lang.Object' WHEN mobParam:DataType:CompareTo(Progress.Reflect.DataType:Object) EQ 1
      {&END}
      IF mobParam:Mode:CompareTo(Progress.Reflect.ParameterMode:Input) EQ 1 OR mobParam:Mode:CompareTo(Progress.Reflect.ParameterMode:InputOutput) EQ 1 THEN ASSIGN
        cttParams.lgInput = TRUE
        cttParams.inInputOrder = minInOrd
        minInOrd = minInOrd + 1
      {&END}
      IF mobParam:Mode:CompareTo(Progress.Reflect.ParameterMode:Output) EQ 1 OR mobParam:Mode:CompareTo(Progress.Reflect.ParameterMode:InputOutput) EQ 1 THEN ASSIGN
        cttParams.lgOutput = TRUE
        cttParams.inOutputOrder = minOutOrd
        minOutOrd = minOutOrd + 1
      {&END}
    END.
  END METHOD.
END CLASS.