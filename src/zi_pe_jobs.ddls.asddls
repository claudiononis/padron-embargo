@EndUserText.label: 'I Jobs Padron Embargo'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define root view entity ZI_PE_JOBS
  as select from zfi_pe_job as Job
  composition [0..*] of ZI_PE_JOBLOGENTRIES as _JobLogEntries
{
  key Job.id              as ID,
      Job.archivo         as archivo,
      Job.company_code    as companyCode,
      Job.quitar_bloqueo  as quitarBloqueo,
      Job.modo_test       as modoTest,
      Job.estado          as estado,
      Job.total           as total,
      Job.procesadas      as procesadas,
      Job.bloqueados      as bloqueados,
      Job.desbloqueados   as desbloqueados,
      Job.errores         as errores,
      Job.no_encontrados  as noEncontrados,
      Job.ya_en_estado    as yaEnEstado,
      Job.ignorados       as ignorados,
      Job.mensaje_error   as mensajeError,
      Job.creado_en       as creadoEn,
      Job.finalizado_en   as finalizadoEn,
      _JobLogEntries
}
