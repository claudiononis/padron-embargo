@EndUserText.label: 'Parametros de procesamiento del padron'
define abstract entity ZD_PADRON_PROC_PARAM
{
  @EndUserText.label: 'Sociedad'
  company_code     : abap.char(4);

  @EndUserText.label: 'Clave de bloqueo'
  blocking_reason  : abap.char(1);

  @EndUserText.label: 'Modo test (no impacta S/4)'
  modo_test        : abap_boolean;

  @EndUserText.label: 'Quitar bloqueo por diferencia'
  desbloquear      : abap_boolean;

  @EndUserText.label: 'Nombre del archivo'
  nombre_archivo   : abap.char(255);

  @EndUserText.label: 'Contenido del archivo TXT'
  @UI.multiLineText: true
  contenido        : abap.string(0);
}
