/**
 * Divide um texto em uma lista pelo separador informado.
 * Usa indexOf/substring em vez de regex: o separador é tratado como texto literal
 * (ex.: "|", ".", "(" funcionam sem escape).
 * Lógica pura, sem SOQL nem DML.
 */
public inherited sharing class StringSplitter {
    public static List<String> split(String text, String separator, Boolean removeEmpty, Boolean trimItems) {
        List<String> items = new List<String>();
        if (String.isBlank(text)) {
            return items;
        }
        if (String.isEmpty(separator)) {
            addItem(items, text, removeEmpty, trimItems);
            return items;
        }

        String remaining = text;
        while (true) {
            Integer position = remaining.indexOf(separator);
            if (position < 0) {
                addItem(items, remaining, removeEmpty, trimItems);
                break;
            }
            addItem(items, remaining.substring(0, position), removeEmpty, trimItems);
            remaining = remaining.substring(position + separator.length());
        }
        return items;
    }

    private static void addItem(List<String> items, String rawItem, Boolean removeEmpty, Boolean trimItems) {
        String item = trimItems ? rawItem.trim() : rawItem;
        if (removeEmpty && String.isBlank(item)) {
            return;
        }
        items.add(item);
    }
}
