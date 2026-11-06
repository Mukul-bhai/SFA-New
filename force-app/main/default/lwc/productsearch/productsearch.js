import { LightningElement } from 'lwc';
import searchProducts from '@salesforce/apex/ProductSearchController.searchProducts';

export default class Productsearch extends LightningElement {
    searchKey = '';
    products = [];
    error;
    hasSearched = false;

    get noResults() {
        return this.hasSearched &&
            !this.error &&
            this.products.length === 0;
    }

    handleSearch(event) {
        this.searchKey = event.target.value;
        this.error = undefined;
        this.hasSearched = false;

        const term = this.searchKey.trim();

        if (!term) {
            this.products = [];
            return;
        }

        searchProducts({ searchTerm: term })
            .then(result => {
                console.log('Apex response:', JSON.stringify(result));

                this.products = result.map(product => ({
                    ...product,
                    url: '/lightning/r/Product2/' +
                        product.Id + '/view'
                }));

                this.hasSearched = true;
            })
            .catch(error => {
                console.error(
                    'Product search failed:',
                    JSON.stringify(error)
                );

                this.products = [];
                this.error = error;
                this.hasSearched = true;
            });
    }
}