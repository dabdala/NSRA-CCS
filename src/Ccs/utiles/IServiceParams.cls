
/*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.IServiceParams
    Purpose     : Give access to service parameters in order to be able to provide values
                  for them, in a generic manner.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (N�made Soft SRL)
    Created     : Tue Nov 28 11:27:59 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
/*$
[es]
Acceso gen�rico a la informaci�n de par�metros de un servicio.
Los servicios pueden ser m�todos de objetos, o procedimientos internos.
Seg�n c�mo est� implementado el servicio real al que pertenecen los par�metros
algunas propiedades ser�n v�lidas y otras no, pero los m�todos son siempre
v�lidos.
[en]
Generic access to parameters information for a service.
Services can be methods of objects, or internal procedures.
Based on actual service implementation some properties may be valid while others
are not.
Methods are always valids and functional.
$*/
INTERFACE Ccs.utiles.IServiceParams:
  /*$
  [es]
  Devuelve la cantidad de par�metros de entrada que tiene el servicio,
  esto incluye INPUT e INPUT-OUTPUT.
  [en]
  Returns the number of INPUT parameters, which includes INPUT-OUTPUT parameters.
  $*/
  DEFINE PUBLIC PROPERTY inputCount AS INTEGER NO-UNDO
    GET.
    
  /*$
  [es]
  Devuelve la cantidad de par�metros de salida que tiene el servicio,
  que incluye OUTPUT e INPUT-OUTPUT.
  [en]
  Returns the number of OUTPUT parameters, which includes INPUT-OUTPU parameters.
  $*/
  DEFINE PUBLIC PROPERTY outputCount AS INTEGER NO-UNDO
    GET.
  /*$
  [es]
  Cantidad de par�metros de entrada y salida (INPUT-OUTPUT) que tiene el servicio.
  [en]
  Returns the number of INPUT-OUTPUT parameters.
  $*/
  DEFINE PUBLIC PROPERTY bothCount AS INTEGER NO-UNDO
    GET.
  /*$
  [es]
  Devuelve una instancia de la clase propia de Progress para representar par�metros
  de un m�todo de clase. Cuando el servicio no es un m�todo de clase, devuelve ?.
  [en]
  Returns the built-in progress object for method parameters.
  If service is not an object method returns ?.
  $*/
  DEFINE PUBLIC PROPERTY paramList AS Progress.Lang.ParameterList NO-UNDO
    GET.
  /*$
  [es]
  Devuelve el nombre del servicio al que aplican los par�metros,
  que corresponde al nombre del m�todo de objeto, o nombre de procedimiento interno.
  [en]
  Returns the name of the service this parameters apply to,
  which is the name of the internal procedure, or the name of the object method.
  $*/
  DEFINE PUBLIC PROPERTY serviceName AS CHARACTER NO-UNDO
    GET.
  /*$
  [es]
  Devuelve el HANDLE al procedimiento que contiene el servicio a invocar.
  Es v�lido si el servicio es un procedimiento interno, ? si el servicio es un
  m�todo de clase.
  [en]
  Returns the HANDLE to the procedure holding the service to invoke (if aplicable).
  Valid if actual service is an internal procedure, ? if an object method.
  $*/
  DEFINE PUBLIC PROPERTY serviceHandle AS HANDLE NO-UNDO
    GET.
  /*$
  [es]
  Devuelve la instancia que implementa el m�todo a ser invocado como servicio.
  Si el servicio es un procedimiento interno, devuelve ?.
  [en]
  Returns the object which method is going to be invoked (if aplicable).
  If services is an internal procedure returns ?.
  $*/
  DEFINE PUBLIC PROPERTY serviceObject AS Progress.Lang.Object NO-UNDO
    GET.
  /*$
  [es]
  Establece el valor del par�metro de entrada correspondiente.
  Se considera par�metro de entrada a los INPUT y a los INPUT-OUTPUT.
  inOrder no es la posici�n del par�metro en la lista de par�metros,
  sino el orden en la "lista" de par�metros de entrada.
  [en]
  Sets the value for the INPUT / INPUT-OUTPUT parameter that has inOrder as INPUT order.
  inOrder is not the absolute position of the parameter, but its position in the
  "input list".
  $*/
  METHOD PUBLIC VOID setInput(INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER).
  /*$
  [es]
  Devuelve el valor de un par�metro de entrada.
  inOrder es la posici�n del par�metro en la "lista" de par�metros de entrada, no
  su posici�n absoluta en los par�metros del servicio.
  [en]
  Returns the parameter value for the INPUT /INPUT-OUTPUT parameter that has inOrder as INPUT order.
  inOrder is not the absolute position of the parameter in the service parameters, but in the
  "list" of input parameters.
  $*/
  METHOD PUBLIC CHARACTER getInput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Establece el valor de un par�metro de salida.
  inOrder no es la posici�n absoluta del par�metro en el servicio, sino en
  la "lista" de par�metros de salida.
  [en]
  Sets the value for the OUTPUT / INPUT-OUTPUT parameter that has inOrder as OUTPUT order.
  inOrder is not the parameter absolute position, but its position in the "output list".
  $*/
  METHOD PUBLIC VOID setOutput(INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER).
  /*$
  [es]
  Devuelve el valor de un par�metro de salida.
  inOrder no es la posici�n absoluta del par�metro en el servicio, sino en
  la "lista" de par�metros de salida.
  [en]
  Returns the parameter value for the OUTPUT / INPUT-OUTPUT parameter that has inOrder as OUTPUT order.
  inOrder is not the parameter absolute position, but its position in the "output list".
  $*/
  METHOD PUBLIC CHARACTER getOutput(INPUT inOrder AS INTEGER).  
  /*$
  [es]
  Lo mismo que setInput, pero para par�metros LONGCHAR.
  [en]
  Same as setInput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC VOID setLongInput(INPUT inOrder AS INTEGER, INPUT chValue AS LONGCHAR).
  /*$
  [es]
  Lo mismo que getInput, pero para par�metros LONGCHAR.
  [en]
  Same as getInput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC LONGCHAR getLongInput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Lo mismo que setOutput, pero para par�metros LONGCHAR.
  [en]
  Same as setOutput, buf for LONGCHAR parameters.
  $*/
  METHOD PUBLIC VOID setLongOutput(INPUT inOrder AS INTEGER, INPUT chValue AS LONGCHAR).
  /*$
  [es]
  Lo mismo que getOutput, pero para par�metros LONGCHAR.
  [en]
  Same as getOutput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC LONGCHAR getLongOutput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Devuelve el tipo de par�metro.
  inOrder es la posici�n absoluta del par�metro deseado.
  [en]
  Returns the data type of the parameter of absolute order inOrder.
  $*/
  METHOD PUBLIC CHARACTER parameterType(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Devuelve el modo del par�metro (INPUT, OUTPUT, INPUT-OUTPUT).
  inOrder es la posici�n absoluta del par�metro deseado.
  [en]
  Returns the mode (INPUT, OUTPUT, INPUT-OUTPUT) of the parameter of absolute order inOrder.
  $*/
  METHOD PUBLIC CHARACTER parameterMode(INPUT inOrder AS INTEGER).  
  /*$
  [es]
  Obtiene toda la informaci�n de los par�metros del servicio para un servicio que es
  un procedimiento interno.
  [en]
  Obtains all the information of required parameters to invoke the service chName (internal procedure)
  in the procedure hnService.
  $*/
  METHOD PUBLIC VOID initialize(INPUT hnService AS HANDLE, INPUT chName AS CHARACTER).
  /*$
  [es]
  Obtiene la informaci�n para invocar el m�todo del objeto provisto.
  [en]
  Obtains all the information of required parameters to invoke the service chName (object method)
  in the object obService.
  $*/
  METHOD PUBLIC VOID initialize(INPUT obService AS Progress.Lang.Object, INPUT chName AS CHARACTER).
END INTERFACE.