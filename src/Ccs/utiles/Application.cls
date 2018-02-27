 
 /*------------------------------------------------------------------------
    File        : Ccs.Common.Application
    Purpose     : Extension of the provided general purpose interfaces
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Nov 28 11:33:04 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/
 
/*$
[es]
Brinda acceso a los objetos globales propios del marco NSRA.
[en]
Access to NSRA global objects.
$*/
USING Progress.Lang.*.

ROUTINE-LEVEL ON ERROR UNDO, THROW.

CLASS Ccs.utiles.Application FINAL: 
  /*$
  [es]
  Acceso a la interfaz de SessionManager propia de NSRA.
  [en]
  Access to NSRA SessionManager interface.
  $*/
  DEFINE STATIC PUBLIC PROPERTY SessionManager AS icomun.utiles.ISessionmanager NO-UNDO GET. SET.
  /*$
  [es]
  Acceso al protocolo que se esté usando a través de la clase base.
  [en]
  Access to the protocol in use, through the base class.
  $*/
  DEFINE STATIC PUBLIC PROPERTY Protocol AS nsra.utiles.BaseProtocol NO-UNDO GET. SET.
  /*$
  [es]
  Acceso al encargado de gestionar las traducciones de cadenas en forma dinámica.
  [en]
  Access to manager interface for handling dynamic string translations.
  $*/
  DEFINE STATIC PUBLIC PROPERTY TranslationManager AS Ccs.utiles.ITranslationManager NO-UNDO GET. SET.
  /*$
  [es]
  Acceso al gesto de excepciones que utilizan las clases Ccs (opcionalmente).
  [en]
  Access to manager for raising errors from Ccs classes (optionaly).
  $*/
  DEFINE STATIC PUBLIC PROPERTY ExceptionManager AS Ccs.utiles.IExceptionManager NO-UNDO GET. SET.
END CLASS.