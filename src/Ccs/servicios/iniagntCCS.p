
/*------------------------------------------------------------------------
    File        : Ccs.servicios.iniagntCCS.p
    Purpose     : Setups NSRA to be run as a CCS compliant framework

    Syntax      :

    Description : It should be run as the initialization procedure for the Agent.

    Author(s)   : D. Abdala (Nómade Soft SRL)
    Created     : Fri Feb 16 18:30:00 ART 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */

ROUTINE-LEVEL ON ERROR UNDO, THROW.

/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */
DEFINE VARIABLE lobStartupMan AS Ccs.utiles.StartupManager NO-UNDO.
lobStartupMan = NEW Ccs.utiles.StartupManager().
lobStartupMan:initialize().
