Note: In process of integrating multi-currency in a company, a latter migration (20170827145712_rename_columns_with_dollar_to_currency.rb) renames `points_to_dollar_ratio` to `points_to_currency_ratio` and `has_set_points_to_dollar_ratio` to `has_set_points_to_currency_ratio'. Also, the accompanying code changes replaces every relevant instance of the word `dollar` to `currency`.

Rewards migrations
1. Move rewards#points to deprecated points
2. **Update rewards#value with deprecated points * default company points to dollar ratio - NOTE: transient migration
3a. Update redemptions#points_redeemed with reward#deprecated points
3b. **Update redemptions#value_redeemed with reward#value
4. **Create reward variants for each reward with reward#value
5. Update redemptions with first reward variant created in previous step
6. Update users redeemed_points and redeemable_points cache columns
7. Update redemptions to be already approved by System user
8. Set existing companies to #has_set_points_dollar_ratio flag to false



# Should never adjust points for legacy redemptions. Points spent are points spent. 
# However, we can what the value of that redemption was. 

+ Hold off creating variants, until ratio is set
+ When ratio is set: go through rewards, and setup variants for rewards that don't have variants (which will be all of them during first run)
+ Redemptions: value_redeemed? - maybe show placeholder until ratio is set

# When ratio is changed after first setup of rewards
# + Update variant values and points

Examples (implicit 100 points/dollar):

Redemptions
$20 gift card: 2000 points
$30 Sweatshirt: 3000 points
$5 Mug: 500 points

On initial migration (1 point/dollar):
$20 gift: 20 points
$30 Sweathshirt: 30 points
$5 Mug: 5 points