import { LightningElement } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import CHARTJS from '@salesforce/resourceUrl/chartjs';
import getHistory from '@salesforce/apex/LimitMonitorController.getHistory';

const LIMIT_OPTIONS = [
    { label: 'Requisições de API diárias', value: 'DailyApiRequests' },
    { label: 'Armazenamento de dados (MB)', value: 'DataStorageMB' },
    { label: 'Armazenamento de arquivos (MB)', value: 'FileStorageMB' },
    { label: 'Execuções Apex assíncronas diárias', value: 'DailyAsyncApexExecutions' },
    { label: 'Jobs Bulk API v2 diários', value: 'DailyBulkV2QueryJobs' },
    { label: 'E-mails únicos diários', value: 'SingleEmail' }
];

const PERIOD_OPTIONS = [
    { label: 'Últimos 7 dias', value: '7' },
    { label: 'Últimos 30 dias', value: '30' }
];

const WARNING_PERCENT = 70;
const CRITICAL_PERCENT = 90;
const DEFAULT_ERROR = 'Não foi possível carregar o histórico. Tente novamente.';
const CHART_ERROR = 'Não foi possível carregar a biblioteca de gráficos.';

export default class LimitHistoryChart extends LightningElement {
    limitOptions = LIMIT_OPTIONS;
    periodOptions = PERIOD_OPTIONS;
    selectedLimit = 'DailyApiRequests';
    selectedDays = '30';

    points = [];
    isLoading = true;
    errorMessage;

    chartReady = false;
    needsDraw = false;
    chart;

    connectedCallback() {
        loadScript(this, CHARTJS)
            .then(() => {
                this.chartReady = true;
                return this.loadHistory();
            })
            .catch(() => {
                this.isLoading = false;
                this.errorMessage = CHART_ERROR;
            });
    }

    renderedCallback() {
        if (this.chartReady && this.needsDraw && this.hasPoints) {
            this.needsDraw = false;
            this.drawChart();
        }
    }

    disconnectedCallback() {
        this.destroyChart();
    }

    async loadHistory() {
        this.isLoading = true;
        this.errorMessage = undefined;
        try {
            const data = await getHistory({
                limitName: this.selectedLimit,
                days: Number(this.selectedDays)
            });
            this.points = data.map((point) => ({
                date: point.snapshotDate,
                percent: Number(point.percent)
            }));
            this.needsDraw = true;
        } catch (error) {
            this.points = [];
            this.errorMessage = error?.body?.message || DEFAULT_ERROR;
        } finally {
            this.isLoading = false;
        }
    }

    handleLimitChange(event) {
        this.selectedLimit = event.detail.value;
        this.loadHistory();
    }

    handlePeriodChange(event) {
        this.selectedDays = event.detail.value;
        this.loadHistory();
    }

    drawChart() {
        const canvas = this.template.querySelector('canvas');
        if (!canvas || !window.Chart) {
            return;
        }
        this.destroyChart();

        const labels = this.points.map((point) => this.formatDate(point.date));
        const values = this.points.map((point) => point.percent);
        const limits = this.points.map(() => WARNING_PERCENT);
        const criticals = this.points.map(() => CRITICAL_PERCENT);

        this.chart = new window.Chart(canvas, {
            type: 'line',
            data: {
                labels,
                datasets: [
                    {
                        label: 'Uso (%)',
                        data: values,
                        borderColor: '#0176d3',
                        backgroundColor: 'rgba(1, 118, 211, 0.15)',
                        fill: true,
                        tension: 0.25,
                        pointRadius: 3
                    },
                    {
                        label: `Atenção (${WARNING_PERCENT}%)`,
                        data: limits,
                        borderColor: '#dd7a01',
                        borderDash: [6, 4],
                        pointRadius: 0,
                        fill: false
                    },
                    {
                        label: `Crítico (${CRITICAL_PERCENT}%)`,
                        data: criticals,
                        borderColor: '#c23934',
                        borderDash: [6, 4],
                        pointRadius: 0,
                        fill: false
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                animation: false,
                scales: {
                    y: {
                        min: 0,
                        max: 100,
                        title: { display: true, text: '% de uso' }
                    }
                },
                plugins: {
                    legend: { position: 'bottom' }
                }
            }
        });
    }

    destroyChart() {
        if (this.chart) {
            this.chart.destroy();
            this.chart = undefined;
        }
    }

    formatDate(isoDate) {
        if (typeof isoDate !== 'string') {
            return String(isoDate);
        }
        const [year, month, day] = isoDate.split('-');
        return `${day}/${month}`;
    }

    get hasPoints() {
        return !this.isLoading && !this.errorMessage && this.points.length > 0;
    }

    get showEmpty() {
        return !this.isLoading && !this.errorMessage && this.points.length === 0;
    }

    get summaryText() {
        if (!this.hasPoints) {
            return '';
        }
        const latest = this.points[this.points.length - 1];
        const limitLabel = LIMIT_OPTIONS.find((option) => option.value === this.selectedLimit)?.label;
        return `${limitLabel}: último uso de ${latest.percent}% em ${this.formatDate(latest.date)}.`;
    }
}
