@EndUserText.label: 'I JobLogEntries Padron Embargo'
@AccessControl.authorizationCheck: #NOT_REQUIRED
define view entity ZC_PE_JOBLOGENTRIES
  as projection on ZI_PE_JOBLOGENTRIES
{
  key ID,
      job_ID,
      numeroLinea,
      cuit,
      proveedor,
      razonSocial,
      accion,
      resultado,
      mensaje,
      timestamp,
      _Job
}
