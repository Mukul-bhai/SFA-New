public with sharing class ProductSearchController {

    @AuraEnabled(cacheable=true)
    public static List<Product2> searchProducts(String searchTerm) {

        if (String.isBlank(searchTerm)) {
            return new List<Product2>();
        }

        String searchKey = '%' + searchTerm.trim() + '%';

        return [
            SELECT Id, Name, ProductCode
            FROM Product2
            WHERE Name LIKE :searchKey or ProductCode LIKE:searchkey
            ORDER BY Name
            LIMIT 50
        ];
    }
}