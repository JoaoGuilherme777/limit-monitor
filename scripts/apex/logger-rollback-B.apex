Logger.info('Teste.rollback', 'B: entrada com flush antes da falha');
Logger.flush();
Integer zero = 0;
Integer falha = 1 / zero;
