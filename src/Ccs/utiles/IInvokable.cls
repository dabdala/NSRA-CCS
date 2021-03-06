
/*------------------------------------------------------------------------
    File        : Ccs.ServiceManager.IInvokable
    Purpose     : Provide an unified way of invoking services, without need to know
                  the actual implementation
    Syntax      : 
    Description : 
    Author(s)   : D. Abdala (N�made Soft SRL)
    Created     : Tue Nov 28 11:33:04 ART 2017
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.ServiceManager.*.
USING Ccs.utiles.*.
/*$
[es]
Interfaz que permite invocar un servicio, sin importar c�mo ha sido implementado.
De esta forma se pueden invocar servicios que han sido implementados como m�todos de objetos,
y tambi�n los que han sido implementados como procedimientos (internos/externos).
Incluso podr�an invocarse servicios que corresponden a servicios externos, como si fuesen
servicios locales.
[en]
This interface provides a way of invoking a service with independence of it implementation.
It can be implemented as an object method, a procedure, a remote service, and be invoked
in an unified way.
$*/
INTERFACE Ccs.utiles.IInvokable INHERITS Ccs.Common.IService:
  /*$
  [es]
  realiza la invocaci�n del servicio real, con los par�metros provistos.
  [en]
  Performs the invocation of the desired method/procedure, with the provided parameters.
  $*/
  METHOD PUBLIC VOID invoke(INPUT-OUTPUT obParams AS CLASS IServiceParams).  
  /*$
  [es]
  Devuelve una instancia de IServiceParams que contiene toda la informaci�n de los par�metros
  definidos para el servicio.
  Se puede utilizar para invocar el servicio, o para derivar nuevos par�metros para �ste.
  [en]
  Provides an IServiceParams instance corresponding to service parameters.
  It can be used for invocation, or to derive required invoke parameters for the service.
  $*/
  DEFINE PUBLIC PROPERTY serviceParams AS IServiceParams NO-UNDO
    GET.
END INTERFACE.