@IsTest
private class SlugGeneratorTest {

    @IsTest
    static void removesAccentsAndSpecialCharacters() {
        Assert.areEqual('acao-solucao-2026', SlugGenerator.generate('Ação & Solução 2026!', null));
        Assert.areEqual('sao-paulo', SlugGenerator.generate('São Paulo', null));
    }

    @IsTest
    static void handlesUppercaseAccentsAndCedilla() {
        Assert.areEqual('coracao-ect', SlugGenerator.generate('CORAÇÃO ÊCT', null));
        Assert.areEqual('nino-acucar', SlugGenerator.generate('Niño Açúcar', null));
    }

    @IsTest
    static void collapsesRunsOfSeparatorsAndTrimsEdges() {
        Assert.areEqual('a-b-c', SlugGenerator.generate('  --a!!  b...c--  ', null));
    }

    @IsTest
    static void usesCustomSeparatorAndEmptySeparator() {
        Assert.areEqual('meu_projeto_v2', SlugGenerator.generate('Meu Projeto v2', '_'));
        Assert.areEqual('meuprojetov2', SlugGenerator.generate('Meu Projeto v2', ''));
    }

    @IsTest
    static void nullSeparatorFallsBackToDefault() {
        Assert.areEqual('a-b', SlugGenerator.generate('a b', null));
    }

    @IsTest
    static void blankOrSymbolOnlyInputReturnsEmptyString() {
        Assert.areEqual('', SlugGenerator.generate(null, null));
        Assert.areEqual('', SlugGenerator.generate('   ', null));
        Assert.areEqual('', SlugGenerator.generate('!@#$%', null));
    }
}
