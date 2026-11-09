import { createElement } from 'lwc';
import LimitHistoryChart from 'c/limitHistoryChart';
import getHistory from '@salesforce/apex/LimitMonitorController.getHistory';

jest.mock(
    '@salesforce/apex/LimitMonitorController.getHistory',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-limit-history-chart', () => {
    beforeEach(() => {
        window.Chart = jest.fn(() => ({ destroy: jest.fn() }));
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
        delete window.Chart;
    });

    it('desenha o gráfico com os pontos retornados', async () => {
        getHistory.mockResolvedValue([
            { snapshotDate: '2026-11-06', percent: 40.5 },
            { snapshotDate: '2026-11-07', percent: 72.0 }
        ]);

        const element = createElement('c-limit-history-chart', { is: LimitHistoryChart });
        document.body.appendChild(element);
        await flushPromises();

        expect(getHistory).toHaveBeenCalledWith({ limitName: 'DailyApiRequests', days: 30 });
        expect(window.Chart).toHaveBeenCalledTimes(1);
        const config = window.Chart.mock.calls[0][1];
        expect(config.data.labels).toEqual(['06/11', '07/11']);
        expect(config.data.datasets[0].data).toEqual([40.5, 72]);
    });

    it('mostra o estado vazio quando não há snapshots', async () => {
        getHistory.mockResolvedValue([]);

        const element = createElement('c-limit-history-chart', { is: LimitHistoryChart });
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Ainda não há snapshots para este período.');
        expect(window.Chart).not.toHaveBeenCalled();
    });

    it('mostra a mensagem de erro quando a chamada falha', async () => {
        getHistory.mockRejectedValue({ body: { message: 'Limite não monitorado' } });

        const element = createElement('c-limit-history-chart', { is: LimitHistoryChart });
        document.body.appendChild(element);
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert).not.toBeNull();
        expect(alert.textContent).toContain('Limite não monitorado');
        expect(window.Chart).not.toHaveBeenCalled();
    });
});
