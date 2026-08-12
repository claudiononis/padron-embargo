@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Padron - cabecera de corrida (interface)'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
  serviceQuality: #X,
  sizeCategory: #S,
  dataClass: #MIXED
}
define root view entity ZI_PADRON_RUN
  as select from zttxt_run
  composition [0..*] of ZI_PADRON_LOG as _Log
{
  key run_id              as RunId,
      company_code        as CompanyCode,
      modo_test           as ModoTest,
      quitar_bloqueo      as QuitarBloqueo,
      estado              as Estado,
      blocking_reason     as BlockingReason,
      contenido           as Contenido,
      @Semantics.largeObject: {
        mimeType: 'MimeType',
        fileName: 'FileName',
        contentDispositionPreference: #ATTACHMENT
      }
      file_content        as FileContent,
      mime_type           as MimeType,
      file_name           as FileName,
      nombre_archivo      as NombreArchivo,
      total_registros     as TotalRegistros,
      total_match         as TotalMatch,
      total_bloqueados    as TotalBloqueados,
      total_desbloqueados as TotalDesbloqueados,
      total_errores       as TotalErrores,
      total_ignorados     as TotalIgnorados,
      @Semantics.user.createdBy: true
      created_by          as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at          as CreatedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at     as LastChangedAt,

      _Log
}
