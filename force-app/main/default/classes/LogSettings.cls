/**
 * Leitura centralizada da configuração do Logger (Logger_Settings__mdt, registro 'Default').
 * Valores ausentes ou inválidos caem em padrões seguros, para que o logger nunca quebre a transação de negócio.
 */
public with sharing class LogSettings {

    public static final Integer DEFAULT_RETENTION_DAYS = 90;
    public static final LogLevel DEFAULT_MINIMUM_LEVEL = LogLevel.INFO;

    @TestVisible private static Integer retentionDaysOverride;
    @TestVisible private static LogLevel minimumLevelOverride;

    private static Logger_Settings__mdt cachedDefault;
    private static Boolean defaultLoaded = false;

    public static Integer getRetentionDays() {
        if (retentionDaysOverride != null) {
            return retentionDaysOverride;
        }
        Logger_Settings__mdt settings = loadDefault();
        if (settings == null || settings.Retention_Days__c == null || settings.Retention_Days__c < 1) {
            return DEFAULT_RETENTION_DAYS;
        }
        return settings.Retention_Days__c.intValue();
    }

    public static LogLevel getMinimumLevel() {
        if (minimumLevelOverride != null) {
            return minimumLevelOverride;
        }
        Logger_Settings__mdt settings = loadDefault();
        return settings == null ? DEFAULT_MINIMUM_LEVEL : parseLevel(settings.Minimum_Level__c, DEFAULT_MINIMUM_LEVEL);
    }

    public static LogLevel parseLevel(String value, LogLevel fallback) {
        if (String.isBlank(value)) {
            return fallback;
        }
        try {
            return LogLevel.valueOf(value.trim().toUpperCase());
        } catch (Exception e) {
            return fallback;
        }
    }

    private static Logger_Settings__mdt loadDefault() {
        if (!defaultLoaded) {
            List<Logger_Settings__mdt> rows = [
                SELECT Retention_Days__c, Minimum_Level__c
                FROM Logger_Settings__mdt
                WHERE DeveloperName = 'Default'
                WITH USER_MODE
                LIMIT 1
            ];
            cachedDefault = rows.isEmpty() ? null : rows[0];
            defaultLoaded = true;
        }
        return cachedDefault;
    }
}
