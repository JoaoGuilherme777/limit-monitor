import { createElement } from 'lwc';
import LimitMonitorCards from 'c/limitMonitorCards';
import getCurrentLimits from '@salesforce/apex/LimitMonitorController.getCurrentLimits';

jest.mock(
    '@salesforce/apex/LimitMonitorController.getCurrentLimits',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe('c-limit-monitor-cards', () => {
    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllMocks();
    });

    it('mostra o card com rótulo, percentual e status', async () => {
        getCurrentLimits.mockResolvedValue([
            { name: 'DailyApiRequests', used: 75, maximum: 100, percent: 75, status: 'warning' }
        ]);

        const element = createElement('c-limit-monitor-cards', { is: LimitMonitorCards });
        document.body.appendChild(element);
        await flushPromises();

        const card = element.shadowRoot.querySelector('[role="group"]');
        expect(card).not.toBeNull();
        expect(card.getAttribute('aria-label')).toBe('Requisições de API diárias');
        expect(card.className).toContain('limit-card_warning');
        expect(element.shadowRoot.textContent).toContain('75.0%');
        expect(element.shadowRoot.textContent).toContain('Atenção');
    });

    it('mostra a mensagem de erro quando a chamada falha', async () => {
        getCurrentLimits.mockRejectedValue({ body: { message: 'Sem acesso aos limites' } });

        const element = createElement('c-limit-monitor-cards', { is: LimitMonitorCards });
        document.body.appendChild(element);
        await flushPromises();

        const alert = element.shadowRoot.querySelector('[role="alert"]');
        expect(alert).not.toBeNull();
        expect(alert.textContent).toContain('Sem acesso aos limites');
        expect(element.shadowRoot.querySelector('[role="group"]')).toBeNull();
    });

    it('mostra mensagem de vazio quando não há limites', async () => {
        getCurrentLimits.mockResolvedValue([]);

        const element = createElement('c-limit-monitor-cards', { is: LimitMonitorCards });
        document.body.appendChild(element);
        await flushPromises();

        expect(element.shadowRoot.textContent).toContain('Nenhum limite monitorado encontrado.');
    });

    it('mostra o spinner durante o carregamento', () => {
        getCurrentLimits.mockReturnValue(new Promise(() => {}));

        const element = createElement('c-limit-monitor-cards', { is: LimitMonitorCards });
        document.body.appendChild(element);

        expect(element.shadowRoot.querySelector('lightning-spinner')).not.toBeNull();
    });
});
