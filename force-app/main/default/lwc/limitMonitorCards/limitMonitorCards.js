import { LightningElement } from 'lwc';
import getCurrentLimits from '@salesforce/apex/LimitMonitorController.getCurrentLimits';

const LABELS = {
    DailyApiRequests: 'Requisições de API diárias',
    DataStorageMB: 'Armazenamento de dados (MB)',
    FileStorageMB: 'Armazenamento de arquivos (MB)',
    DailyAsyncApexExecutions: 'Execuções Apex assíncronas diárias',
    DailyBulkV2QueryJobs: 'Jobs Bulk API v2 diários',
    SingleEmail: 'E-mails únicos diários'
};

const STATUS_LABELS = {
    ok: 'Normal',
    warning: 'Atenção',
    critical: 'Crítico'
};

const DEFAULT_ERROR = 'Não foi possível carregar os limites. Tente novamente.';

export default class LimitMonitorCards extends LightningElement {
    cards = [];
    isLoading = true;
    errorMessage;

    connectedCallback() {
        this.load();
    }

    async load() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            const data = await getCurrentLimits();
            this.cards = data.map((card) => this.toViewModel(card));
        } catch (error) {
            this.cards = [];
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
        } finally {
            this.isLoading = false;
        }
    }

    toViewModel(card) {
        const percent = Number(card.percent);
        return {
            key: card.name,
            name: card.name,
            label: LABELS[card.name] || card.name,
            percentLabel: `${percent.toFixed(1)}%`,
            usageText: `${card.used} de ${card.maximum}`,
            barValue: Math.min(percent, 100),
            statusLabel: STATUS_LABELS[card.status] || card.status,
            cardClass: `limit-card limit-card_${card.status}`
        };
    }

    handleRefresh() {
        this.load();
    }

    get hasCards() {
        return this.cards.length > 0;
    }

    get showEmpty() {
        return !this.isLoading && !this.errorMessage && !this.hasCards;
    }
}
