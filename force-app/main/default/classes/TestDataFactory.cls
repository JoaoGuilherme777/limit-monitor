/**
 * Criação de dados para testes. Não usa SeeAllData: todo dado é criado dentro do teste.
 */
@IsTest
public class TestDataFactory {

    public static Account createAccount(String name, String industry) {
        Account account = new Account(Name = name, Industry = industry);
        insert account;
        return account;
    }

    public static List<Contact> createContacts(Id accountId, Integer quantity) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < quantity; i++) {
            contacts.add(new Contact(FirstName = 'Teste', LastName = 'Contato ' + i, AccountId = accountId));
        }
        insert contacts;
        return contacts;
    }
}
