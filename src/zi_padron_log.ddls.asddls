@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Padron - log de resultado (interface)'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define view entity ZI_PADRON_LOG
  as select from zttxt_log
  association to parent ZI_PADRON_RUN as _Run
    on $projection.RunId = _Run.RunId
{
  key run_id        as RunId,
  key line_number   as LineNumber,
      cuit          as Cuit,
      supplier      as Supplier,
      company_code  as CompanyCode,
      resultado     as Resultado,
      mensaje       as Mensaje,
      @Semantics.systemDateTime.createdAt: true
      created_at    as CreatedAt,

      // asociación de vuelta hacia la cabecera
      _Run
}
