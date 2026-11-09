/**
 * Gera slugs para URLs e identificadores: remove acentos, põe em minúsculas
 * e troca qualquer sequência de caracteres não alfanuméricos por um separador.
 * Ex.: "Ação & Solução  2026!" -> "acao-solucao-2026" (com separador '-').
 * Lógica pura, sem SOQL nem DML.
 */
public inherited sharing class SlugGenerator {
    public static final String DEFAULT_SEPARATOR = '-';

    private static final String ACCENTED =
        'àáâãäåèéêëìíîïòóôõöùúûüçñ' + 'ÀÁÂÃÄÅÈÉÊËÌÍÎÏÒÓÔÕÖÙÚÛÜÇÑ';
    private static final String UNACCENTED =
        'aaaaaaeeeeiiiiooooouuuucn' + 'AAAAAAEEEEIIIIOOOOOUUUUCN';
    private static final String ALLOWED_CHARACTERS = 'abcdefghijklmnopqrstuvwxyz0123456789';

    public static String generate(String text, String separator) {
        if (String.isBlank(text)) {
            return '';
        }
        String sep = separator == null ? DEFAULT_SEPARATOR : separator;

        String cleaned = removeAccents(text).toLowerCase();
        List<String> words = new List<String>();
        String currentWord = '';

        for (Integer i = 0; i < cleaned.length(); i++) {
            String character = cleaned.substring(i, i + 1);
            if (ALLOWED_CHARACTERS.contains(character)) {
                currentWord += character;
            } else if (String.isNotEmpty(currentWord)) {
                words.add(currentWord);
                currentWord = '';
            }
        }
        if (String.isNotEmpty(currentWord)) {
            words.add(currentWord);
        }
        return String.join(words, sep);
    }

    @TestVisible
    private static String removeAccents(String text) {
        String result = '';
        for (Integer i = 0; i < text.length(); i++) {
            String character = text.substring(i, i + 1);
            Integer position = ACCENTED.indexOf(character);
            result += position >= 0 ? UNACCENTED.substring(position, position + 1) : character;
        }
        return result;
    }
}
