import { createElement } from 'lwc';
import LogViewer from 'c/logViewer';
import search from '@salesforce/apex/LogViewerController.search';

jest.mock(
    '@salesforce/apex/LogViewerController.search',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

// Drena a fila de microtasks (sem setTimeout, que a regra no-async-operation do LWC restringe).
async function flushPromises() {
    for (let i = 0; i < 5; i++) {
        await Promise.resolve();
    }
}

function pageOf(rows, totalCount, pageNumber = 1) {
    return { rows, totalCount, pageNumber, pageSize: 20 };
}

describe('c-log-viewer', () => {
    beforeEach(() => {
        search.mockReset();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    it('carrega a primeira página ao conectar e mostra o total', async () => {
        search.mockResolvedValue(
            pageOf([{ id: 'a1', name: 'LOG-0001', level: 'ERROR', source: 'X', message: 'm' }], 1)
        );

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        expect(search).toHaveBeenCalledTimes(1);
        expect(search).toHaveBeenCalledWith({
            filter: { level: null, source: null, startDate: null, endDate: null, userId: null },
            pageSize: 20,
            pageNumber: 1
        });
        const status = element.shadowRoot.querySelector('[role="status"] p');
        expect(status.textContent).toContain('1 registro(s)');
        const table = element.shadowRoot.querySelector('lightning-datatable');
        expect(table).not.toBeNull();
        expect(table.data).toHaveLength(1);
    });

    it('mostra estado vazio quando a consulta não retorna linhas', async () => {
        search.mockResolvedValue(pageOf([], 0));

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector('lightning-datatable')).toBeNull();
        expect(element.shadowRoot.textContent).toContain('Nenhum log encontrado');
    });

    it('exibe mensagem de erro vinda do Apex e não exibe tabela', async () => {
        search.mockRejectedValue({ body: { message: 'Use filtros de período para acessar registros mais antigos.' } });

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert).not.toBeNull();
        expect(alert.textContent).toContain('filtros de período');
        expect(element.shadowRoot.querySelector('lightning-datatable')).toBeNull();
    });

    it('usa mensagem genérica quando o erro não tem corpo legível', async () => {
        search.mockRejectedValue(new Error('boom'));

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.querySelector('[role="alert"]').textContent).toContain('Tente novamente');
    });

    it('avança para a próxima página no servidor', async () => {
        search.mockResolvedValueOnce(pageOf([{ id: 'a1' }], 25, 1));
        search.mockResolvedValueOnce(pageOf([{ id: 'b1' }], 25, 2));

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        const next = element.shadowRoot.querySelector('[data-id="next"]');
        next.click();
        await flushPromises();

        expect(search).toHaveBeenCalledTimes(2);
        expect(search.mock.calls[1][0].pageNumber).toBe(2);
    });

    it('aplica filtros enviados ao Apex, com origem sem espaços', async () => {
        search.mockResolvedValue(pageOf([], 0));

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        const source = element.shadowRoot.querySelector('[data-id="source"]');
        source.value = '  Faturamento  ';
        source.dispatchEvent(new CustomEvent('change', { bubbles: true }));

        const level = element.shadowRoot.querySelector('[data-id="level"]');
        level.dispatchEvent(new CustomEvent('change', { detail: { value: 'ERROR' } }));

        const apply = element.shadowRoot.querySelector('[data-id="apply"]');
        apply.click();
        await flushPromises();

        const lastCall = search.mock.calls[search.mock.calls.length - 1][0];
        expect(lastCall.filter.level).toBe('ERROR');
        expect(lastCall.filter.source).toBe('Faturamento');
        expect(lastCall.pageNumber).toBe(1);
    });

    it('desabilita "Anterior" na primeira página', async () => {
        search.mockResolvedValue(pageOf([{ id: 'a1' }], 5, 1));

        const element = createElement('c-log-viewer', { is: LogViewer });
        document.body.appendChild(element);
        await flushPromises();

        const previous = element.shadowRoot.querySelector('[data-id="previous"]');
        expect(previous.disabled).toBe(true);
    });
});
