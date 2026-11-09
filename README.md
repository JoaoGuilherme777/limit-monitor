# Limit Monitor

Monitora os limites da org Salesforce: mostra o uso atual em cards, guarda um histórico diário em gráfico e cria um alerta quando um limite passa do threshold configurado.

## Como funciona

- **Snapshot diário:** um job grava o uso de cada limite em `Limit_Snapshot__c`, às 07:00.
- **Cards e histórico:** o LWC `limitMonitorCards` mostra o uso atual, e o `limitHistoryChart` mostra o histórico em gráfico (Chart.js).
- **Alertas:** um Flow chama o `LimitAlertService` quando um snapshot chega a 70% ou mais. Se o uso passou do threshold do limite, é criado um `Limit_Alert__c` e uma notificação é enviada ao usuário.
- **Thresholds:** ficam em `Limit_Threshold__mdt`, com flag para ativar ou desativar.

Os cards usam faixas fixas: normal abaixo de 70%, atenção de 70% a 90% e crítico acima de 90%.

## Deploy

Pré-requisitos: Salesforce CLI e uma Developer Edition.

```bash
sf org login web --alias DevEd --set-default --instance-url https://login.salesforce.com
sf project deploy start --source-dir force-app --target-org DevEd --test-level RunLocalTests
sf org assign permset --name Limit_Monitor_User --target-org DevEd
sf apex run --file scripts/apex/limit-monitor-schedule.apex --target-org DevEd
```

Depois, adicione os componentes **Limit Monitor Cards** e **Limit History Chart** em uma página do Lightning App Builder.

Se o deploy falhar dizendo que há job agendado, suspenda os jobs em *Setup → Tarefas agendadas*, faça o deploy de novo e rode o último comando.

## Testes

- Apex: 17 testes do Limit Monitor, todos passando na org. Cobertura de 90% a 100% nas classes do projeto.
- Jest (LWC): 7 testes, passando.

Os testes Apex não usam `SeeAllData`. O cálculo e as regras de alerta são testados com dados criados no próprio teste.

## Limitações

- A notificação vai só para o usuário que executa o job.
- Não há envio por e-mail.
- Só `DailyApiRequests` tem threshold cadastrado. Os outros limites não geram alerta até que um registro seja criado em `Limit_Threshold__mdt`.
- A análise estática (PMD, CPD e SFGE) não foi concluída.
