# Rascunho de post para LinkedIn

> Escrito para: público de LinkedIn (desenvolvedores e líderes técnicos Salesforce). Tom direto, pt-BR.

---

Meu log sumia justamente quando eu mais precisava dele. Esse foi o ponto de partida de um projeto pessoal: um Logger para Apex e Flow que sobrevive ao rollback da transação.

O problema é simples de descrever e traiçoeiro de resolver. Se a transação de negócio faz rollback, qualquer `Log__c` gravado nela também é desfeito. Então o erro que você queria investigar desaparece.

Testei as alternativas que costumam aparecer:

- **DML direto no logger:** some com o rollback.
- **Queueable ou @future:** o enfileiramento também é desfeito. O job nunca roda.
- **Platform Event com Publish After Commit:** só é publicado após o commit. Se houve rollback, é descartado.
- **Platform Event com Publish Immediately:** é a opção que, segundo a documentação, sobrevive ao rollback. Mas as versões da documentação divergem sobre isso. Então escrevi um teste que afirma exatamente essa premissa, e o roteiro para validar na org.
- **Savepoint + log depois do rollback:** funciona para erros tratados. Não funciona para exceção não tratada que derruba a transação inteira.

A arquitetura final combina a segunda opção de eventos com o savepoint: o código de negócio só enfileira em memória, o `flush()` publica em lote, um trigger grava o log em outra transação, e o `flush()` roda no `finally`.

Outras decisões que mais me fizeram pensar:

- **Guarda anti-loop:** o handler que grava os logs não pode gerar novos logs, senão vira loop. Ele grava com DML direto e tem uma guarda ativa durante a persistência.
- **Erro no handler não é relançado:** se o trigger do evento falhar, a plataforma reenfileira. Um erro relançado vira um ciclo de reprocessamento.
- **Segurança em duas camadas:** a gravação roda em system mode, porque é persistência interna de algo já autorizado. A leitura no LWC roda em `USER_MODE`, com bind variables e permission set separada.

Tenho um ponto de honestidade a registrar: validei o deploy e os 23 testes Apex em dry-run numa org de desenvolvimento, com cobertura de 95%. Mas o comportamento real do rollback de eventos ainda depende de uma verificação manual na org, e o documento de arquitetura deixa isso explícito.

Se você já lidou com logs sumindo em rollback, como resolveu? E se você tem experiência com o Standard Volume Platform Event no seu contexto, adoraria saber como está a migração.

Repositório: [link do GitHub]

#Salesforce #Apex #PlatformEvents #SalesforceDeveloper #Arquitetura
