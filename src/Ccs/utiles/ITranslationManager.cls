
/*------------------------------------------------------------------------
    File        : Ccs.Common.ITranslationManager
    Purpose     : Abstract the translation process from the implementation.
    Syntax      : 
    Description : Provides string translation from source language to destination language.
    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Tue Feb 20 11:29:21 ART 2018
    Notes       : 
  ----------------------------------------------------------------------*/

USING Progress.Lang.*.
USING Ccs.Common.IManager.
/*$
[es]
Permite establecer el idioma origen de las cadenas, y el idioma destino al cual
se quieren traducir.
Se espera que al solicitar una traducción se devuelva la más apropiada disponible, si existe una.
[en]
Allows for string translation, setting the strings language and the desired language.
A translation should be provided if available.
$*/
INTERFACE Ccs.utiles.ITranslationManager INHERITS IManager:
  /*$
  [es]
  Idioma en que han sido escritas las cadenas.
  Puede ser el código de idioma, o el código y la localización: es, es_ar, en, en_us, etc.
  [en]
  Language in which application strings are written.
  It can be the lang code, or the lang_locale code: es, es_ar, en, en_us, etc. 
  $*/  
  DEFINE PUBLIC PROPERTY sourceLang AS CHARACTER NO-UNDO
    GET.
  /*$
  [es]
  Idioma al cual se quieren traducir las cadenas.
  Puede ser el código de idioma, o el código y la localización: es, es_ar, en, en_us, etc.
  [en]
  Language to which each string will be translated.
  It can be the lang code, or the lang_locale code: es, es_ar, en, en_us, etc. 
  $*/
  DEFINE PUBLIC PROPERTY destinationLang AS CHARACTER NO-UNDO
    GET.
    SET.
  /*$
  [es]
  Devuelve la mejor traducción disponible para la cadena.
  Dado que una misma cadena puede tener múltiples traducciones, se espera que
  se devuelva una de ellas, cuál no está definido.
  Si no existe una traducción, se espera que se devuelva la cadena a traducir.
  [en]
  Translates a string to the closest match for it.
  The sourceMessage may colide (several translations for the same sourceMEssage),
  wich to return is not defined.
  If no translation is available, then sourceMessage must be returned.
  $*/
  METHOD PUBLIC CHARACTER translate(INPUT sourceMEssage AS CHARACTER).
  /*$
  [es]
  Devuelve la traducción para el mensaje identificado por el código provisto.
  Si no existe traducción, se espera que devuelva la cadena correspondiente al mensaje sin traducir.
  Si no existe el identificador puede devolver ?.
  [en]
  Returns the translation for the message identified by the provided Id.
  No colission is possible, but ? return is feasible if provided id doesn't exists.
  If no translation is available, original message should be returned.
  $*/
  METHOD PUBLIC CHARACTER translate(INPUT messageId AS INTEGER).
  /*$
  [es]
  Devuelve la traducción para el mensaje identificado por el identificador.
  Si no existe el identificador devuelve la traducción del mensaje provisto.
  [en]
  If there is a translation for the messageId, then it is returned, if not
  then defaultMessage translation is returned.
  $*/
  METHOD PUBLIC CHARACTER translate(INPUT messageId AS INTEGER, INPUT defaultMessage AS CHARACTER). 
END INTERFACE.