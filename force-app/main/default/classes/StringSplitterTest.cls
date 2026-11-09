@IsTest
private class StringSplitterTest {

    @IsTest
    static void splitsByCommaAndTrimsItems() {
        List<String> items = StringSplitter.split(' ana , bruno,carla ', ',', true, true);
        Assert.areEqual(new List<String>{ 'ana', 'bruno', 'carla' }, items);
    }

    @IsTest
    static void removesEmptyItemsByDefaultFlags() {
        List<String> items = StringSplitter.split('a,,b, ,c', ',', true, true);
        Assert.areEqual(new List<String>{ 'a', 'b', 'c' }, items);
    }

    @IsTest
    static void keepsEmptyItemsWhenAsked() {
        List<String> items = StringSplitter.split('a,,b', ',', false, true);
        Assert.areEqual(new List<String>{ 'a', '', 'b' }, items);
    }

    @IsTest
    static void keepsSpacesWhenTrimIsOff() {
        List<String> items = StringSplitter.split(' a , b ', ',', true, false);
        Assert.areEqual(new List<String>{ ' a ', ' b ' }, items);
    }

    @IsTest
    static void treatsSeparatorAsLiteralNotRegex() {
        Assert.areEqual(new List<String>{ 'x', 'y' }, StringSplitter.split('x|y', '|', true, true));
        Assert.areEqual(new List<String>{ 'a', 'b' }, StringSplitter.split('a.b', '.', true, true));
        Assert.areEqual(new List<String>{ 'a', 'b' }, StringSplitter.split('a(b', '(', true, true));
    }

    @IsTest
    static void multiCharacterSeparatorWorks() {
        Assert.areEqual(new List<String>{ 'um', 'dois', 'tres' }, StringSplitter.split('um; dois; tres', '; ', true, true));
    }

    @IsTest
    static void blankInputGivesEmptyListAndEmptySeparatorKeepsWholeText() {
        Assert.isTrue(StringSplitter.split(null, ',', true, true).isEmpty());
        Assert.isTrue(StringSplitter.split('   ', ',', true, true).isEmpty());
        Assert.areEqual(new List<String>{ 'abc' }, StringSplitter.split('abc', '', true, true));
    }

    @IsTest
    static void textWithoutSeparatorIsSingleItem() {
        Assert.areEqual(new List<String>{ 'sozinho' }, StringSplitter.split('sozinho', ';', true, true));
    }
}
