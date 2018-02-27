# NSRA-CCS
Common Component Specification implementation for NSRA framework

NSRA framework is an ABL implementation of OERA principles, for developing enterprise applications, specifically designed
for the modernization, integration and migration of legacy ABL applications.
It is a full-featured framework that delivers from UI transformations to multi-database integrity constraints.
As NSRA has its own implementation of all the OERA layers, including the common infrastructure (in itself built
as an NSRA module), already implements all CCS concepts (and a lot more).

The goal of this NSRA module (Ccs) is to provide access to NSRA through CCS interfaces.
In order to do so more interfaces than the specified by CCS were required and, of course, concrete implementations of all
the interfaces.

The Ccs NSRA module has a "mixed" structure, part of it respects the CCS guidelines and part of it NSRA conventions.
Feel free to move things around, as that doesn't really matters to NSRA.
The "new stuff" is in NSRA folders (servicios,config,utiles,dao), and the header comment has the CCS route that the
file should/may have.

In order to run the code, you need a full NSRA installation, one is provided as rcode:
- OpenEdge 11.6
- Windows 7x64
- Development

Being "Development" rcode means a lot of log information is output to file, so logs may reach GB sizes if not deleted
periodically (nsra/servicios/log folder).
A couple of database structure, along with data, is provided (and required).

The file ccs_test.zip contains everything to be able to run the tests (the few ones). After unzipping it, there is a 'dbs'
folder that has the .df and the .d required for both databases. Recreate both.

Open the file 'localrun.p' in the root folder, and run it, if no servers are started for the databases, connect them
to the session (DB Administrator / DB Dictionary) using 'nsradb' as logical name for nsra database.

Once the environment gets initialized you will be asked for a 'protocol file' to run, or a '.p' to run. As CCS has no
protocol recommendation yet, NSXML protocol is used. A 'protocol file' is an XML file located in 'nsra/servicios/inout'
folder, with an '.in' extension. Two of this files are provided, one for logging in (longin.in) and one for testing
'esVerificador' service, which is the simplest service to test (no params).

In order to be able to test 'esVerificador', you first need a valid session, so first run 'login', open the output file
'nsra/servicios/inout/login.out' and copy the resulting session id from this file, to the field '<session>' in the
'esverificador.in' file. Now you can run the service 'esVerificador'.

To run a '.p' file, write the relative path to it: Ccs/servicios/tests.p will run the couple of CCS tests implemented. 

------------
Implementación de "Common Component Specification" para el marco de trabajo NSRA.

NSRA es un marco de trabajo implementado en ABL, siguiendo los lineamientos de OERA, diseñado para el desarrollo de
aplicaciones empresariales, fundamentalmente para la modernización, integración y migración de aplicaciones antiguas.
Es un marco de trabajo completo, que implementa desde la traducción automatizada de la interfaz, hasta la especificación
de integridad referencial entre múltiples bases de datos.
Dado que NSRA tiene su propia implementación de todas las capas propuestas por OERA, lo que incluye la infraestructura común
(implementada como un módulo NSRA), ya implementa todos los conceptos que requiere CCS (y muchos más).

El objetivo de este módulo NSRA (Ccs) es proveer los mecanismos para poder acceder a todo lo implementado con NSRA, a
través de los mecanismos previstos por CCS.
Para poder hacerlo se han definido varias interfaces adicionales y, obviamente, implementaciones de todas las interfaces.

Este módulo tiene una estructura "mixta", en parte respeta los lineamientos de CCS y en parte las convenciones NSRA.
El código puede moverse libremente entre directorios, dado que a NSRA no le hace diferencia.
Todo "lo nuevo" se encuentra en los directorios de NSRA (servicios, config, utiles, dao), y los comentarios al principio
de cada archivo contienen la ruta que supongo debería tener el archivo si respetara los lineamientos CCS.

Para poder ejecutar el código se necesita una instalación completa de NSRA, la cual se provee como rcode:
 - OpenEdge 11.6
 - Windows 7x64
 - Desarrollo
 
Que sea de "Desarrollo" implica que se genera una tonelada de información en disco, que puede llegar a varios GB si no
se limpia periódicamente (directorio nsra/servicios/log).
Un par de estructuras de bases de datos, junto con los datos, también se proveen, ya que son necesarias.

El archivo ccs_test.zip contiene todo lo necesario para poder correr las pruebas implementadas. Luego de descomprimir
el archivo, recree las bases de datos que se encuentran en el directorio 'dbs', donde están los .df y los .d de cada
una.

Abra el archivo 'localrun.p' que se encuentra en la raiz y ejecútelo, si no se han levantado servidores para las
bases de datos, conéctelas a la sesión (con el DB Administrator o DB Dictionary), usando 'nsradb' como nombre
lógico para la base de datos nsra.

Una vez que se inicializa el entorno, se permite ingresar el nombre de un 'archivo de protocolo' a ejecutar, o un archivo
'.p' a ejecutar. Los 'archivos de protocolo' son archivos xml que se encuentran en el directorio 'nsra/servicios/inout'
y que deben tener extensión '.in'.

Dado que CCS no recomienda, actualmente, nada respecto del protocolo, se utiliza el protocolo NSXML para la ejecución.
Se proveen dos archivos NSXML, uno para el ingreso al sistema (inicio de sesión) y otro para ejecutar el servicio
'esVerificador', que es el servicio más simple de probar (no tiene parámetros). Para poder ejecutar 'esverificador.in'
primero debe ejecutar el servicio de ingreso, escribiendo 'login', luego abra el archivo de salida (login.out) y copie
el identificador de sesión de este archivo, al parámetro '<sesion>' del archivo 'esverificador.in'.

Para ejecutar un archivo '.p' escriba la ruta relativa, completa, al archivo: Ccs/servicios/tests.p ejecutar las dos
pruebas implementadas usando la interfaz CCS. 