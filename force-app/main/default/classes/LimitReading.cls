public with sharing class LimitReading {
    public String name { get; private set; }
    public Long used { get; private set; }
    public Long maximum { get; private set; }

    public LimitReading(String name, Long used, Long maximum) {
        this.name = name;
        this.used = used;
        this.maximum = maximum;
    }
}
