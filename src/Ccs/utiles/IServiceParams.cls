
/*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.IServiceParams
    Purpose     : Give access to service parameters in order to be able to provide values
                  for them, in a generic manner.
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 11:27:59 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
/*$
[es]
Acceso genérico a la información de parámetros de un servicio.
Los servicios pueden ser métodos de objetos, o procedimientos internos.
Según cómo esté implementado el servicio real al que pertenecen los parámetros
algunas propiedades serán válidas y otras no, pero los métodos son siempre
válidos.
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
  Devuelve la cantidad de parámetros de entrada que tiene el servicio,
  esto incluye INPUT e INPUT-OUTPUT.
  [en]
  Returns the number of INPUT parameters, which includes INPUT-OUTPUT parameters.
  $*/
  DEFINE PUBLIC PROPERTY inputCount AS INTEGER NO-UNDO
    GET.
    
  /*$
  [es]
  Devuelve la cantidad de parámetros de salida que tiene el servicio,
  que incluye OUTPUT e INPUT-OUTPUT.
  [en]
  Returns the number of OUTPUT parameters, which includes INPUT-OUTPU parameters.
  $*/
  DEFINE PUBLIC PROPERTY outputCount AS INTEGER NO-UNDO
    GET.
  /*$
  [es]
  Cantidad de parámetros de entrada y salida (INPUT-OUTPUT) que tiene el servicio.
  [en]
  Returns the number of INPUT-OUTPUT parameters.
  $*/
  DEFINE PUBLIC PROPERTY bothCount AS INTEGER NO-UNDO
    GET.
  /*$
  [es]
  Devuelve una instancia de la clase propia de Progress para representar parámetros
  de un método de clase. Cuando el servicio no es un método de clase, devuelve ?.
  [en]
  Returns the built-in progress object for method parameters.
  If service is not an object method returns ?.
  $*/
  DEFINE PUBLIC PROPERTY paramList AS Progress.Lang.ParameterList NO-UNDO
    GET.
  /*$
  [es]
  Devuelve el nombre del servicio al que aplican los parámetros,
  que corresponde al nombre del método de objeto, o nombre de procedimiento interno.
  [en]
  Returns the name of the service this parameters apply to,
  which is the name of the internal procedure, or the name of the object method.
  $*/
  DEFINE PUBLIC PROPERTY serviceName AS CHARACTER NO-UNDO
    GET.
  /*$
  [es]
  Devuelve el HANDLE al procedimiento que contiene el servicio a invocar.
  Es válido si el servicio es un procedimiento interno, ? si el servicio es un
  método de clase.
  [en]
  Returns the HANDLE to the procedure holding the service to invoke (if aplicable).
  Valid if actual service is an internal procedure, ? if an object method.
  $*/
  DEFINE PUBLIC PROPERTY serviceHandle AS HANDLE NO-UNDO
    GET.
  /*$
  [es]
  Devuelve la instancia que implementa el método a ser invocado como servicio.
  Si el servicio es un procedimiento interno, devuelve ?.
  [en]
  Returns the object which method is going to be invoked (if aplicable).
  If services is an internal procedure returns ?.
  $*/
  DEFINE PUBLIC PROPERTY serviceObject AS Progress.Lang.Object NO-UNDO
    GET.
  /*$
  [es]
  Establece el valor del parámetro de entrada correspondiente.
  Se considera parámetro de entrada a los INPUT y a los INPUT-OUTPUT.
  inOrder no es la posición del parámetro en la lista de parámetros,
  sino el orden en la "lista" de parámetros de entrada.
  [en]
  Sets the value for the INPUT / INPUT-OUTPUT parameter that has inOrder as INPUT order.
  inOrder is not the absolute position of the parameter, but its position in the
  "input list".
  $*/
  METHOD PUBLIC VOID setInput(INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER).
  /*$
  [es]
  Devuelve el valor de un parámetro de entrada.
  inOrder es la posición del parámetro en la "lista" de parámetros de entrada, no
  su posición absoluta en los parámetros del servicio.
  [en]
  Returns the parameter value for the INPUT /INPUT-OUTPUT parameter that has inOrder as INPUT order.
  inOrder is not the absolute position of the parameter in the service parameters, but in the
  "list" of input parameters.
  $*/
  METHOD PUBLIC CHARACTER getInput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Establece el valor de un parámetro de salida.
  inOrder no es la posición absoluta del parámetro en el servicio, sino en
  la "lista" de parámetros de salida.
  [en]
  Sets the value for the OUTPUT / INPUT-OUTPUT parameter that has inOrder as OUTPUT order.
  inOrder is not the parameter absolute position, but its position in the "output list".
  $*/
  METHOD PUBLIC VOID setOutput(INPUT inOrder AS INTEGER, INPUT chValue AS CHARACTER).
  /*$
  [es]
  Devuelve el valor de un parámetro de salida.
  inOrder no es la posición absoluta del parámetro en el servicio, sino en
  la "lista" de parámetros de salida.
  [en]
  Returns the parameter value for the OUTPUT / INPUT-OUTPUT parameter that has inOrder as OUTPUT order.
  inOrder is not the parameter absolute position, but its position in the "output list".
  $*/
  METHOD PUBLIC CHARACTER getOutput(INPUT inOrder AS INTEGER).  
  /*$
  [es]
  Lo mismo que setInput, pero para parámetros LONGCHAR.
  [en]
  Same as setInput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC VOID setLongInput(INPUT inOrder AS INTEGER, INPUT chValue AS LONGCHAR).
  /*$
  [es]
  Lo mismo que getInput, pero para parámetros LONGCHAR.
  [en]
  Same as getInput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC LONGCHAR getLongInput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Lo mismo que setOutput, pero para parámetros LONGCHAR.
  [en]
  Same as setOutput, buf for LONGCHAR parameters.
  $*/
  METHOD PUBLIC VOID setLongOutput(INPUT inOrder AS INTEGER, INPUT chValue AS LONGCHAR).
  /*$
  [es]
  Lo mismo que getOutput, pero para parámetros LONGCHAR.
  [en]
  Same as getOutput, but for LONGCHAR parameters.
  $*/
  METHOD PUBLIC LONGCHAR getLongOutput(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Devuelve el tipo de parámetro.
  inOrder es la posición absoluta del parámetro deseado.
  [en]
  Returns the data type of the parameter of absolute order inOrder.
  $*/
  METHOD PUBLIC CHARACTER parameterType(INPUT inOrder AS INTEGER).
  /*$
  [es]
  Devuelve el modo del parámetro (INPUT, OUTPUT, INPUT-OUTPUT).
  inOrder es la posición absoluta del parámetro deseado.
  [en]
  Returns the mode (INPUT, OUTPUT, INPUT-OUTPUT) of the parameter of absolute order inOrder.
  $*/
  METHOD PUBLIC CHARACTER parameterMode(INPUT inOrder AS INTEGER).  
  /*$
  [es]
  Obtiene toda la información de los parámetros del servicio para un servicio que es
  un procedimiento interno.
  [en]
  Obtains all the information of required parameters to invoke the service chName (internal procedure)
  in the procedure hnService.
  $*/
  METHOD PUBLIC VOID initialize(INPUT hnService AS HANDLE, INPUT chName AS CHARACTER).
  /*$
  [es]
  Obtiene la información para invocar el método del objeto provisto.
  [en]
  Obtains all the information of required parameters to invoke the service chName (object method)
  in the object obService.
  $*/
  METHOD PUBLIC VOID initialize(INPUT obService AS Progress.Lang.Object, INPUT chName AS CHARACTER).
END INTERFACE.