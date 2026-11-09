# Logger com Platform Events: arquitetura e decisões

> Escrito para: desenvolvedores Salesforce que vão manter ou revisar este projeto.
> Complementa o [README](../README.md). Este documento registra o raciocínio e os riscos, não só o que foi feito.

## 1. O problema

Quando a transação de negócio faz rollback, qualquer registro de log gravado **nessa mesma transação** é desfeito junto. Justamente nos erros que mais precisamos investigar, o log some. O objetivo do Logger é que a entrada de log sobreviva ao rollback do negócio, sem acoplar o negócio ao mecanismo de log.

## 2. Opções avaliadas

| # | Opção | Sobrevive ao rollback da transação de origem? | Consistência | Custo / limites | Veredito |
|---|---|---|---|---|---|
| A | DML direto em `Log__c` dentro do `Logger` | **Não**: o INSERT é desfeito com a transação | Forte, junto com o negócio | Consome DML e linhas da transação; contenção de lock se o log estiver na mesma tabela de negócio | Descartada para o caso de rollback |
| B | `Queueable` ou `@future` que grava o log | **Não**: o enfileiramento é desfeito junto com a transação, então o job nunca roda | Assíncrona, sem garantia de ordem | Limite de jobs enfileirados por transação; mais um job por erro | Descartada |
| C | Platform Event `Publish After Commit` consumido por trigger que faz o DML | **Não**: o evento só é publicado após o commit; se a transação faz rollback, o evento é descartado | Eventual; depois do commit | Mesmo custo do D, sem a vantagem de sobreviver | Descartada |
| D | Platform Event `Publish Immediately` consumido por trigger que faz o DML | **Sim, segundo a documentação de publicação imediata** (ver seção 2.1: as fontes divergem) | Eventual; o log pode existir mesmo quando o negócio foi revertido | Limite de chamadas de publicação por transação; limite de eventos por 24h da licença | **Escolhida**, com teste de regressão e validação na org |
| E | Capturar a exceção, `Database.rollback(sp)` e registrar o log depois | **Sim** para falhas **tratadas** (o log é criado depois da reversão). **Não** para exceção não tratada que derruba a transação inteira | Forte, na mesma transação | Depende de o código ter o `try/catch` no ponto certo | **Complemento obrigatório** da D |

### 2.1 Ponto de atenção: a documentação diverge

Ao pesquisar o comportamento de rollback para eventos com `Publish Immediately`, encontrei fontes conflitantes:

- Versões mais antigas da documentação dizem que eventos publicados não podem ser revertidos e que `Database.setSavepoint()`/`Database.rollback()` não se aplicam a eles.
- Versões mais novas dizem que é possível reverter eventos publicados com savepoint.
- A documentação atual descreve o `Publish Immediately` como fora dos limites da transação de banco, o que é a leitura que sustenta a escolha da opção D.

Por causa desse conflito, a escolha da opção D **não pode ser tratada como fato até ser validada na org**. Por isso o projeto tem o teste `LoggerTest.logFlushedBeforeBusinessRollbackStillPersists`: ele afirma exatamente essa premissa. Se ele falhar em uma org real, a arquitetura precisa ser revista antes de qualquer outra coisa.

Fontes consultadas:
- [Enterprise Messaging Platform Events](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_intro_emp.htm)
- [Decoupled Publishing and Subscription](https://developer.salesforce.com/docs/atlas.en-us.platform_events.meta/platform_events/platform_events_considerations_decoupled_processes.htm)
- [EventBus Class](https://developer.salesforce.com/docs/atlas.en-us.264.0.apexref.meta/apexref/apex_class_System_eventbus.htm)
- [Transaction Control (Apex)](https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_transaction_control.htm)

## 3. Decisão final

**D + E combinadas:**

1. O código de negócio chama `Logger.error/info/...`. Isso só **enfileira em memória**: nenhum DML e nenhum evento nesse momento.
2. `Logger.flush()` publica o buffer como `Log_Event__e` com `Publish Immediately`, em lotes de 200.
3. `LogEventTrigger` (after insert) chama `LogEventHandler`, que grava os `Log__c` em outra transação.
4. Em tratamento de erro, o padrão recomendado é:

```apex
Savepoint sp = Database.setSavepoint();
try {
    // DML de negócio
} catch (Exception e) {
    Database.rollback(sp);
    Logger.error('MinhaClasse', e, recordId);
} finally {
    Logger.flush();
}
```

O `flush()` no `finally` garante a publicação mesmo quando o `catch` relança a exceção.

### 3.1 O que o projeto **não** protege

Exceção não tratada que derruba a transação inteira (por exemplo, validation rule ou erro em trigger antes do commit, sem `try/catch` no caminho) faz o rollback de tudo. Se o `flush()` não rodou antes, o log se perde. A mitigação é colocar o `try/finally` no ponto de entrada (controller, invocable, método de serviço). Não há como o Salesforce persistir algo depois de uma falha não tratada dentro da mesma transação.

## 4. Quando Platform Events são a escolha certa

**Usar quando:**
- Você precisa desacoplar quem produz o evento de quem consome (o produtor não conhece o consumidor).
- Você quer uma escrita que não disputa lock com as linhas de negócio.
- Você quer reagir em tempo real (um LWC ou outro sistema assinando o evento) ou fazer replay.
- O produtor pode estar em contexto onde DML direto é inviável ou arriscado (por exemplo, ao final de uma transação que já tem muito DML).

**Não usar quando:**
- Você precisa de **garantia transacional** com o dado de negócio na mesma transação. Nesse caso, use DML direto.
- Você precisa **consultar** o histórico com SOQL. Eventos não são armazenados para consulta; o replay tem janela limitada (72h). Por isso o consumidor grava em `Log__c`.
- Ordem global entre produtores importa. A ordem só é garantida dentro de um mesmo lote de publicação.
- O consumidor precisa de confiabilidade absoluta. Se o trigger do evento falhar, a plataforma reenfileira algumas vezes e depois descarta. Por isso o `LogEventHandler` nunca lança exceção.

## 5. Volume e limites

- **Buffer em memória:** nenhuma publicação por chamada de log. O `flush()` publica em lotes de 200 eventos por chamada de `EventBus.publish`. Ao atingir 200 entradas, o buffer é publicado automaticamente.
- **Limite de chamadas de publicação por transação** (o número de 150 aparece nas fontes consultadas; confirmar na documentação da versão alvo). Com lotes de 200, o teto prático fica na ordem de dezenas de milhares de entradas por transação.
- **Limite de eventos por 24h** depende da licença. Monitorar em Setup. Em volume alto, reduzir o nível mínimo (`Logger_Settings__mdt.Minimum_Level__c`) é a primeira alavanca.
- **Armazenamento:** `Log__c` cresce sem limite. Não há política de retenção neste projeto (decisão deliberada, por ser um projeto de portfólio). Em uma org de produção, seria preciso definir uma política de retenção e, em volume alto, solicitar índice customizado em `Logged_At__c` ao Salesforce.
- **Logs dentro de loops:** o padrão é acumular no buffer e não chamar `flush()` dentro do loop. O `Logger` já evita publicar a cada iteração; o `flush()` automático só ocorre a cada 200 entradas.
- **Tamanho:** mensagem e stack trace são truncados em 32.000 caracteres, abaixo do limite do campo.

## 6. Como impedir que o logger gere loop de logs

Três barreiras independentes:

1. **Guarda anti-loop:** `LogEventHandler.handle` ativa `Logger.setDispatchGuard(true)`. Qualquer `Logger.write` durante a persistência é descartado com `System.debug`, sem enfileirar.
2. **Handler sem `Logger`:** o handler grava com `Database.insert` diretamente. Assim ele nunca publica evento, nem indiretamente.
3. **Erros do handler não viram evento:** falhas são reportadas com `System.debug` e não relançadas. Relançar faria a plataforma reenfileirar o evento, o que pode virar um loop de reprocessamento.

Teste: `LoggerTest.dispatchGuardPreventsLogsFromBeingQueuedWhileHandlerRuns`.

## 7. Testabilidade

- `Test.startTest()` / `Test.stopTest()`: a entrega dos eventos acontece no `stopTest`, e a trigger roda nesse momento. Os asserts sobre `Log__c` ficam depois do `stopTest`.
- Override `@TestVisible` em `LogSettings` (nível mínimo) permite testar sem depender do registro de CMDT da org.
- Cenários de rollback são testados com savepoint real (`LoggerTest`).
- Testes de consulta rodam como um usuário com a permission set `Logger Viewer`, porque a consulta usa `USER_MODE`. Rodar como admin mascara erros de FLS (ver seção 9).
- Sem `SeeAllData`. Dados são criados em `@TestSetup` ou no próprio teste.

## 8. Segurança

| Ponto | Decisão |
|---|---|
| Visibilidade de `Log__c` | OWD `Private`. Leitura global apenas pela permission set `Logger Viewer` (ViewAll). |
| Escrita por código de usuário | `Logger Writer` concede create em `Log_Event__e`. |
| Consulta do LWC | `Database.queryWithBinds(..., AccessLevel.USER_MODE)`: CRUD, FLS e sharing do usuário. |
| Gravação do handler | `SYSTEM_MODE`, justificado: é persistência interna de uma entrada já autorizada na origem. O usuário de origem é preservado em `User__c`. |
| Injeção | Todos os filtros entram como bind variables. `LIKE` tem `%` e `_` escapados. |
| Usuário de origem | Capturado no momento do log, porque o trigger do evento roda como usuário de sistema. |
| Campos obrigatórios em permission set | Salesforce não aceita entrada de FLS para campo obrigatório. Eles ficam visíveis por herança do acesso de leitura ao objeto. |

## 9. Validação realizada e pendências

**Feito:**

- **Deploy real na org `DevEd`** (job `0Afg700000ItMNJCA3`, após validação em dry-run): 42/42 componentes, **23/23 testes Apex passando**, zero erros. Durante a validação, foram encontrados e corrigidos: `eventType` inválido (`Standard` não existe; o correto é `StandardVolume`), `nameField` em platform event, filtro em campo `LongTextArea`, FLS em campo obrigatório dentro de permission set, namespace `xsd` no CMDT, Bulk/Streaming API inconsistentes com Sharing em `Log__c`, e um teste que rodava como admin e mascarava erro de FLS.
- **Cobertura:** 95,3% das linhas nas classes `Log*`/`Logger*` (224/235). `Logger` isolado: 94,5%.
- **Jest (LWC):** 7/7 testes passando. Cobertura de linhas do `logViewer.js`: ~81%.
- **Code Analyzer:** nenhum achado de severidade 1 ou 2 nas classes do Logger. Restam 5 achados de severidade 3 (complexidade ciclomática e número de parâmetros) e achados de severidade 4 (ApexDoc e `System.debug`).

**Não validado ainda (pendências):**

1. **Rollback validado na org `DevEd`.** O roteiro abaixo foi executado: a conta gravada antes do rollback foi revertida e o `Log__c` sobreviveu. Isso é evidência em org real, mas ainda não cobre uma exceção não tratada que derruba a transação inteira (seção 3.1).
2. **Limites numéricos** citados neste documento: confirmar na documentação da versão alvo.
3. **Status do `Standard Volume`.** Uma fonte de blog (não oficial) de outubro de 2026 menciona planos de aposentadoria do Standard Volume Platform Event: [sfdcdevelopers.com](https://sfdcdevelopers.com/2026/10/07/standard-volume-platform-events-retirement-migration-plan/). Essa informação não foi confirmada na documentação oficial. Se o Standard Volume for aposentado, a opção D some: o único equivalente é o High Volume, que só suporta `Publish After Commit`. Nesse cenário, o projeto passa a depender da opção E.
4. **Deploy real** concluído na org `DevEd`. Os metadados estão em `projeto-entrevista/force-app/main/default/`.

**Roteiro de validação do rollback (executado na org `DevEd`: conta revertida, log persistido):**

```apex
// Anonymous Apex: sf apex run -o DevEd -f scripts/apex/rollback-probe.apex
Savepoint sp = Database.setSavepoint();
insert new Account(Name = 'Probe Rollback');
Logger.error('RollbackProbe', 'Publicado antes do rollback', null);
Logger.flush();
Database.rollback(sp);
```

Depois, em uma consulta separada: `SELECT Id FROM Account WHERE Name = 'Probe Rollback'` deve retornar zero linhas e `SELECT Id FROM Log__c WHERE Source__c = 'RollbackProbe'` deve retornar uma linha, após alguns segundos. Se o log não aparecer, a premissa da opção D está errada e a seção 3 precisa ser revisada.

## 10. Plano B (sem Platform Event)

Se o Standard Volume for aposentado ou a premissa da opção D não se confirmar, a arquitetura muda para:

- Erros tratados: manter o padrão da opção E (savepoint + `flush()` depois do rollback). Sem mudança no restante.
- Erros não tratados: aceitar a perda, ou registrar em um sistema externo via callout, com as restrições de callout após DML pendente.

Essa decisão deve ser tomada com dados do roteiro da seção 9, não por suposição.
