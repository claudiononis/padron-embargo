@EndUserText.label: 'I JobLogEntries Padron Embargo'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZI_PE_JOBLOGENTRIES
  as select from zfi_pe_joblog as Log
  association to parent ZI_PE_JOBS as _Job
    on $projection.job_ID = _Job.ID
{
  key Log.id           as ID,
      Log.job_id       as job_ID,
      Log.numero_linea as numeroLinea,
      Log.cuit         as cuit,
      Log.proveedor    as proveedor,
      Log.razon_social as razonSocial,
      Log.accion       as accion,
      Log.resultado    as resultado,
      Log.mensaje      as mensaje,
      Log.ts           as timestamp,
      _Job
}
