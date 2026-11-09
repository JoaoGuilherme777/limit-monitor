import { LightningElement } from 'lwc';
import search from '@salesforce/apex/LogViewerController.search';

const LEVEL_OPTIONS = [
    { label: 'Todos', value: '' },
    { label: 'DEBUG', value: 'DEBUG' },
    { label: 'INFO', value: 'INFO' },
    { label: 'WARN', value: 'WARN' },
    { label: 'ERROR', value: 'ERROR' }
];

const PAGE_SIZE_OPTIONS = [
    { label: '10 por página', value: '10' },
    { label: '20 por página', value: '20' },
    { label: '50 por página', value: '50' }
];

const COLUMNS = [
    { label: 'Registro', fieldName: 'name', type: 'text' },
    { label: 'Nível', fieldName: 'level', type: 'text' },
    { label: 'Origem', fieldName: 'source', type: 'text' },
    { label: 'Tipo', fieldName: 'sourceType', type: 'text' },
    { label: 'Mensagem', fieldName: 'message', type: 'text', wrapText: true },
    { label: 'Usuário', fieldName: 'userName', type: 'text' },
    {
        label: 'Data',
        fieldName: 'loggedAt',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        }
    }
];

const EMPTY_FILTERS = {
    level: '',
    source: '',
    startDate: '',
    endDate: '',
    userId: ''
};

export default class LogViewer extends LightningElement {
    levelOptions = LEVEL_OPTIONS;
    pageSizeOptions = PAGE_SIZE_OPTIONS;
    columns = COLUMNS;

    filters = { ...EMPTY_FILTERS };
    pageSize = 20;
    pageNumber = 1;
    totalCount = 0;
    rows = [];
    isLoading = false;
    errorMessage = '';
    hasSearched = false;

    connectedCallback() {
        this.runSearch();
    }

    // ----- Estado derivado -----

    get pageSizeValue() {
        return String(this.pageSize);
    }

    get totalPages() {
        return Math.max(1, Math.ceil(this.totalCount / this.pageSize));
    }

    get isFirstPage() {
        return this.isLoading || this.pageNumber <= 1;
    }

    get isLastPage() {
        return this.isLoading || this.pageNumber >= this.totalPages;
    }

    get hasRows() {
        return this.rows.length > 0;
    }

    get showEmptyState() {
        return this.hasSearched && !this.isLoading && !this.errorMessage && !this.hasRows;
    }

    get statusText() {
        if (this.isLoading) {
            return 'Carregando logs...';
        }
        return `${this.totalCount} registro(s). Página ${this.pageNumber} de ${this.totalPages}.`;
    }

    // ----- Handlers de filtro -----

    handleLevelChange(event) {
        this.filters = { ...this.filters, level: event.detail.value };
    }

    handleSourceChange(event) {
        this.filters = { ...this.filters, source: event.target.value };
    }

    handleStartDateChange(event) {
        this.filters = { ...this.filters, startDate: event.target.value };
    }

    handleEndDateChange(event) {
        this.filters = { ...this.filters, endDate: event.target.value };
    }

    handleUserChange(event) {
        this.filters = { ...this.filters, userId: event.detail.recordId || '' };
    }

    handleApplyFilters() {
        this.pageNumber = 1;
        this.runSearch();
    }

    handleClearFilters() {
        this.filters = { ...EMPTY_FILTERS };
        this.pageNumber = 1;
        this.runSearch();
    }

    // ----- Paginação -----

    handlePageSizeChange(event) {
        this.pageSize = Number(event.detail.value);
        this.pageNumber = 1;
        this.runSearch();
    }

    handlePrevious() {
        if (this.pageNumber > 1) {
            this.pageNumber -= 1;
            this.runSearch();
        }
    }

    handleNext() {
        if (this.pageNumber < this.totalPages) {
            this.pageNumber += 1;
            this.runSearch();
        }
    }

    // ----- Consulta -----

    async runSearch() {
        this.isLoading = true;
        this.errorMessage = '';
        try {
            const page = await search({
                filter: this.buildFilter(),
                pageSize: this.pageSize,
                pageNumber: this.pageNumber
            });
            this.rows = page.rows;
            this.totalCount = page.totalCount;
            this.pageNumber = page.pageNumber;
        } catch (error) {
            this.rows = [];
            this.totalCount = 0;
            this.errorMessage = this.extractErrorMessage(error);
        } finally {
            this.hasSearched = true;
            this.isLoading = false;
        }
    }

    buildFilter() {
        const f = this.filters;
        return {
            level: f.level || null,
            source: f.source ? f.source.trim() : null,
            startDate: f.startDate || null,
            endDate: f.endDate || null,
            userId: f.userId || null
        };
    }

    extractErrorMessage(error) {
        const body = error && error.body;
        if (body && typeof body.message === 'string' && body.message) {
            return body.message;
        }
        return 'Não foi possível carregar os logs. Tente novamente.';
    }
}
