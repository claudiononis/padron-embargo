@EndUserText.label: 'Padron - cabecera (projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true

@UI.presentationVariant: [{
  sortOrder: [{ by: 'CreatedAt', direction: #DESC }],
  visualizations: [{ type: #AS_LINEITEM }],
  requestAtLeast: [ 'NombreArchivo' ]
}]

@UI.headerInfo: {
  typeName: 'Corrida',
  typeNamePlural: 'Corridas',
  title: { type: #STANDARD, value: 'NombreArchivo' },
  description: { type: #STANDARD, value: 'Estado' }
}


define root view entity ZC_PADRON_RUN
  provider contract transactional_query
  as projection on ZI_PADRON_RUN
{
      @UI.facet: [
        { id: 'Carga', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
          label: 'Parámetros de la corrida', position: 10, targetQualifier: 'Carga' },
        { id: 'Resultados', purpose: #STANDARD, type: #FIELDGROUP_REFERENCE,
          label: 'Resultados', position: 20, targetQualifier: 'Result' },
        { id: 'Log', purpose: #STANDARD, type: #LINEITEM_REFERENCE,
          label: 'Detalle por registro', position: 30, targetElement: '_Log' }
      ]

      @UI.hidden: true
  key RunId,

      @EndUserText.label: 'Sociedad'
      @UI: { lineItem: [{ position: 20, label: 'Sociedad' }],
             fieldGroup: [{ position: 10, qualifier: 'Carga', label: 'Sociedad' }] }
      CompanyCode,

      @EndUserText.label: 'Clave de bloqueo'
      @UI: { fieldGroup: [{ position: 20, qualifier: 'Carga', label: 'Clave de bloqueo' }] }
      BlockingReason,

      @EndUserText.label: 'Quitar bloqueo'
      @UI: { lineItem: [{ position: 35, label: 'Quitar bloqueo' }],
             fieldGroup: [{ position: 25, qualifier: 'Carga', label: 'Quitar bloqueo (desbloquear)' }] }
      QuitarBloqueo,

      @EndUserText.label: 'Modo test'
      @UI: { lineItem: [{ position: 30, label: 'Modo test' }],
             fieldGroup: [{ position: 30, qualifier: 'Carga', label: 'Modo test (no impacta S/4)' }] }
      ModoTest,

      @EndUserText.label: 'Nombre del archivo'
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.8
      @UI: { lineItem: [{ position: 10, label: 'Archivo' }],
             fieldGroup: [{ position: 40, qualifier: 'Carga', label: 'Nombre del archivo' }] }
      NombreArchivo,

      @EndUserText.label: 'Archivo del padrón'
      @UI: { fieldGroup: [{ position: 50, qualifier: 'Carga', label: 'Archivo del padrón (.txt)' }] }
      FileContent,

      @UI.hidden: true
      MimeType,

      @UI.hidden: true
      FileName,

      @UI.hidden: true
      @UI.multiLineText: true
      Contenido,

      @EndUserText.label: 'Estado'
      @UI: { lineItem:       [{ position: 40, label: 'Estado' }],
             identification: [{ type: #FOR_ACTION, dataAction: 'refrescar', label: 'Refrescar', position: 10 }],
             fieldGroup:     [{ position: 10, qualifier: 'Result', label: 'Estado' }] }
      Estado,

      @EndUserText.label: 'Total registros'
      @UI: { lineItem: [{ position: 50, label: 'Total' }],
             fieldGroup: [{ position: 20, qualifier: 'Result', label: 'Total registros' }] }
      TotalRegistros,

      @EndUserText.label: 'Coincidencias'
      @UI: { lineItem: [{ position: 60, label: 'Match' }],
             fieldGroup: [{ position: 30, qualifier: 'Result', label: 'Coincidencias' }] }
      TotalMatch,

      @EndUserText.label: 'Bloqueados'
      @UI: { lineItem: [{ position: 70, label: 'Bloqueados' }],
             fieldGroup: [{ position: 40, qualifier: 'Result', label: 'Bloqueados' }] }
      TotalBloqueados,

      @EndUserText.label: 'Desbloqueados'
      @UI: { lineItem: [{ position: 75, label: 'Desbloqueados' }],
             fieldGroup: [{ position: 45, qualifier: 'Result', label: 'Desbloqueados' }] }
      TotalDesbloqueados,

      @EndUserText.label: 'Errores'
      @UI: { lineItem: [{ position: 80, label: 'Errores' }],
             fieldGroup: [{ position: 50, qualifier: 'Result', label: 'Errores' }] }
      TotalErrores,

      @EndUserText.label: 'Ignorados'
      @UI: { fieldGroup: [{ position: 60, qualifier: 'Result', label: 'Ignorados (sin sociedad)' }] }
      TotalIgnorados,

      @UI.hidden: true
      CreatedBy,

      @UI.hidden: true
      CreatedAt,

      @UI.hidden: true
      LastChangedAt,

      _Log : redirected to composition child ZC_PADRON_LOG
}
