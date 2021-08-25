window.R = window.R || {};
window.R.pages = window.R.pages || {};

window.R.pages["company_admin_catalogs-index"] = (function() {
    var Catalog = function() {
        this.addEvents();
    };

    Catalog.prototype.addEvents = function() {
        new R.CompanyAdmin();
        this.initPieCharts();
    };

    Catalog.prototype.initPieCharts = function() {
        if (window.R.company &&
            window.R.company.catalog_dashboard &&
            window.R.company.catalog_dashboard.pieChartDataGiftCards) {

            R.analytics.piechart({
                data: window.R.company.catalog_dashboard.pieChartDataCompanyRewards,
                container: 'company-reward-redemption-catalog-distribution',
                lang: {
                    noData: "No company fulfilled rewards have been approved yet."
                }
            });

            R.analytics.piechart({
                data: window.R.company.catalog_dashboard.pieChartDataGiftCards,
                container: 'giftcard-redemption-catalog-distribution',
                lang: {
                    noData: "No gift cards have been approved yet."
                }
            });
        }
    };

    Catalog.prototype.removeEvents = function() {};

    return Catalog;
})();

