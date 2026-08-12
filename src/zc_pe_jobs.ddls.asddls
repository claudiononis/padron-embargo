@EndUserText.label: 'C Jobs Padron Embargo'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZC_PE_JOBS
  as projection on ZI_PE_JOBS
{
  key ID,
      archivo,
      companyCode,
      quitarBloqueo,
      modoTest,
      estado,
      total,
      procesadas,
      bloqueados,
      desbloqueados,
      errores,
      noEncontrados,
      yaEnEstado,
      ignorados,
      mensajeError,
      creadoEn,
      finalizadoEn,
      _JobLogEntries
}
