
/*------------------------------------------------------------------------
    File        : Ccs.Common.IContext
    Purpose     : Generic methods to set and retrieve data from an "storage" instance
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 10:59:25 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
/*$
[es]
Métodos genéricos para almacenar y recuperar información arbitraria, asociada a algún tipo de contexto
de ejecución.
[en]
Generic methods to store and retrieve arbitrary information, associated to some execution context.
$*/
INTERFACE Ccs.utiles.IContext:  
  /*$
  [es]
  Devuelve el valor asociado al nombre provisto.
  Devuelve ? si no existe uno.
  [en]
  Retrieves the value associated to the specified name.
  Returns ? if none exists.
  $*/
  METHOD PUBLIC CHARACTER getValue(INPUT chName AS CHARACTER).
  
  /*$
  [es]
  Asocia el valor provisto, al nombre indicado.
  Devuelve el valor previo asociado al nombre, si existe uno,
  ? si no existía una asociación previa.
  [en]
  Sets the value associated to the specified name.
  Returns the previous value, or ? if none existed.
  $*/
  METHOD PUBLIC CHARACTER setValue(INPUT chName AS CHARACTER , INPUT chValue AS CHARACTER).  
  
END INTERFACE.