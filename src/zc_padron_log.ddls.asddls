@EndUserText.label: 'Padron - log de resultado (projection)'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true

define view entity ZC_PADRON_LOG
  as projection on ZI_PADRON_LOG
{
      @UI: { lineItem: [{ position: 10 }], identification: [{ position: 10 }] }
  key RunId,

      @UI: { lineItem: [{ position: 20 }], identification: [{ position: 20 }] }
  key LineNumber,

      @UI: { lineItem: [{ position: 30 }], identification: [{ position: 30 }] }
      Cuit,

      @UI: { lineItem: [{ position: 40 }], identification: [{ position: 40 }] }
      Supplier,

      @UI: { lineItem: [{ position: 50 }], identification: [{ position: 50 }] }
      CompanyCode,

      @UI: { lineItem: [{ position: 60 }], identification: [{ position: 60 }] }
      Resultado,

      @UI: { lineItem: [{ position: 70 }], identification: [{ position: 70 }] }
      Mensaje,

      @UI: { lineItem: [{ position: 80 }], identification: [{ position: 80 }] }
      CreatedAt,

      // vuelta hacia la cabecera (projection)
      _Run : redirected to parent ZC_PADRON_RUN
}
