
/*------------------------------------------------------------------------
    File        : Ccs.Common.IExceptionManager
    Purpose     : Having a global exception message management system.
    Syntax      : 
    Description : Handles exception messages based on exception code, localized and specific for the specified class.
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Feb 20 11:26:03 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.utiles.ITranslationManager.
USING Ccs.Common.IManager.
/*$
[es]
Mecanismo para manejar la generación de excepciones de forma centralizada, incluyendo la
traducción de mensajes entre el idioma de la aplicación y el del usuario.
[en]
Centralized error object instantiation, including messages translation from application
language to user language.
$*/
INTERFACE Ccs.utiles.IExceptionManager INHERITS IManager:
  /*$
  [es]
  Instancia global encargada de las traducciones, si existe una se utiliza.
  [en]
  Instance (IManager) used to translate error messages, if available.
  $*/
  DEFINE PUBLIC PROPERTY translationManager AS CLASS ITranslationManager NO-UNDO
    GET.   
  /*$
  [es]
  Devuelve una instancia Progress.Lang.AppError (o derivada de ésta), según la configuración
  establecida para ThrowingClass, con el mensaje correspondiente al código de error provisto,
  traducido si es posible y corresponde.
  $ThrowingClass
  Clase que ha generado el error.
  $messageCode
  Código del error generado.
  [en]
  Returns a Progress.Lang.AppError instance, or derived instance, with the message corresponding to the code
  for the throwing class.
  $ThrowingClass
  Class that is raising the error.
  $messageCode
  Numerical code of the error.
  $*/
  METHOD Progress.Lang.AppError throwError(INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER).
  /*$
  [es]
  Devuelve una instancia Progress.Lang.AppError, o derivada de ésta, según la configuración, con el mensaje
  de error correspondiente al código indicado, realizando las sustituciones de cadenas que correspondan, según
  las cadenas provistas.
  $ThrowingClass
  Clase que ha generado el error.
  $messageCode
  Código del error generado.
  $substitutions
  Cadenas a utilizar como sustitutos en el mensaje, que se espera tenga las posiciones de sustitución
  indicadas como para utilizar SUBSTITUTE().
  [en]
  Returns a Progress.Lang.AppError instance, or derived instance, with the message corresponding to the code
  for the throwing class. With the provided string substitutions.
  $ThrowingClass
  Class that is raising the error.
  $messageCode
  Numerical code of the error.
  $substitutions
  Char values to substitute in the message of the error. The message is supoused to have the format
  required to invoke SUBSTITUTE().
  $*/
  METHOD Progress.Lang.AppError throwError(INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER, INPUT substitutions AS CHARACTER EXTENT).
  /*$
  [es]
  Asocia un mensaje de error a un código de error, para la clase especificada.
  $ThrowingClass
  Clase que puede generar este error.
  $messageCode
  Código numérico del error.
  $messageDesc
  Mensaje de error correspondiente.
  [en]
  Associates an error message for the throwing class, with the error code.
  $ThrowingClass
  Class that may raise this error.
  $messageCode
  Numerical code of the error.
  $messageDesc
  Message of the error.
  $*/
  METHOD LOGICAL registerError(INPUT ThrowingClass AS Progress.Lang.Class, INPUT messageCode AS INTEGER, INPUT messageDesc AS CHARACTER).
  /*$
  [es]
  Asocia un tipo de clase de error a utilizar, para los errores generados por la clase especificada.
  Se va a utilizar este tipo de objeto para todas las excepciones generadas por la clase.
  $ThrowingClass
  Class que genera los errores.
  $ErrorClass
  Clase a utilizar (derivada de Progress.Lang.AppError) para los errores.   
  [en]
  Configures the type of instance to return for the errores raised by the throwing class.
  For classes that hasn't configured an error class, Progress.Lang.AppError is used.
  $ThrowingClass
  Class that is raising errors.
  $ErrorClass
  Class of the error instance to use for raising errors (derived from Progress.Lang.AppError). 
  $*/
  METHOD LOGICAL registerErrorClass( INPUT ThrowingClass AS Progress.Lang.Class, INPUT ErrorClass AS Progress.Lang.Class).
END INTERFACE.