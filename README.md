Recognize
=========

1. install OS dependencies (see Dependencies section below)
2. clone app: `git clone git@github.com:Recognize/recognize.git`
3. activate ruby env (if using an env such as rvm or rbenv)
4. install app dependencies: `bundle install`
5. setup app configs: `cp config/\*.yml.sample to .yml`
6. init app: `bin/rake recognize:init`

## Running server
+ Create hostname to l.recognizeapp.com
+ Run server on port 50000

    ````
    bundle exec rails s -p50000 (if using ngrok)
    bin/rails_ssl(SSL - need self signed cert and key in ~/.ssl)
    ````

## Running server with docker

For this environment you need docker and docker compose installed.

Environment variables are the following:
+ *DATABASE_MYSQL_USERNAME*: Set the username of the database. `config/database.yml`
+ *DATABASE_MYSQL_PASSWORD*: Set the password of the user in `config/database.yml`
+ *DATABASE_MYSQL_HOST*: Set the host where database is hosted in `config/database.yml`
+ *BUNDLE_PATH*: When we use volume to use our code in the dockerize environment we need to move our gems installation folder, we set this variable to the new location
+ *START_UP*: We can choose over ssl or ngrok by setting one of these as an environment. By default it is ssl.

#### Mac/Win Os
+ install [docker-sync](http://docker-sync.io/) to use a volume sync without the file system cause by [this](https://stackoverflow.com/questions/46406980/rails-assets-are-very-slow-on-macox-docker).
+ Run the following commands

    ````
    cd nclouds
    docker-compose build
    docker-compose run --rm recognize ./nclouds/start_env.sh
    docker-compose up recognize
    ````

#### Linux OS
+ Comment all about the volume `recognize-sync` on `nclouds/docker-compose.yml` and run the following commands

    ````
    cd nclouds
    docker-compose build
    docker-compose run --rm recognize ./nclouds/start_env.sh
    docker-compose up recognize
    ````
#### Resetting Docker environment
+ Stop containers

    ````
    docker stop $(docker ps -a -q)
    ````

+ Remove containers

    ````
    docker rm $(docker ps -a -q)
    ````

+ Clean up unused volumes

    ````
    docker volume prune
    ````

## Running tests
To run tests:
```
  RAILS_ENV=test bin/rake recognize:init   # if app/env not already setup.
  bundle exec rspec spec                   # see notes below first
```
Note: you may want to start with a subset of tests:
  + single test (should take ~4min): `bundle exec rspec spec/models/recognition_spec.rb`
  + all model tests (should take ~30min): `bundle exec rspec spec/models`

If tests run significantly slower you likely have the 'nobarrier' issue - this [Stack Overflow article](https://stackoverflow.com/questions/10583669/rspec-incredibly-slow-after-installing-ubuntu-12-04?utm_medium=organic&utm_source=google_rich_qa&utm_campaign=google_rich_qa) provides some background but essentially the MySQL data volume needs to be mounted on a partition with nobarrier/barrier=0. This can be accomplished in several ways (see the article for options) but if you do not want or cannot enable nobarrier on the partition where mysql data is stored you have two less intrusive options - both require a separate partition (EXT4 recommended) mounted with the nobarrier flag:
1. modify your mysql configuration to set the --datadir option (point this to the separate EXT4 nobarrier partition)
2. use a docker/docker-compose based mysql db which mounts the separate EXT4 nobarrier partition as the `/var/lib/mysql` volume

## Dependencies
Note: See [this wiki page](https://github.com/Recognize/recognize/wiki/Development-environment-setup-(installation)-Issues) for non-dependencies related development environment setup/installation issues.

+ chromedriver
+ v8
    + At the time of updating this README, v8@3.15 was used.
+ libv8, rubyracer (versions below may change)
  + gem install libv8 -v '3.16.14.13' -- --with-system-v8
  + gem install therubyracer -v '0.12.2' -- --with-v8-dir=$(brew --prefix v8-315)
    + the `--with-v8-dir` should point to the version of v8 installed earlier
  + https://stackoverflow.com/questions/23536893/therubyracer-gemextbuilderror-error-failed-to-build-gem-native-extension
+ Mysql (v5.7.x, ideally 5.7.19+)
+ ImageMagick
+ Redis
++ If you are on Apple M1, you may have to do env -i /usr/local/bin/redis-server --daemonize yes
+ CurrencyLayer API key (optional for currency conversion)
+ Mimemagic:
  + Mac: brew install shared-mime-info
  + Linux: should already be installed

### Linux - Debian
You will need the following packages for debian based systems:
+ `libmysqlclient-dev ruby-chromedriver-helper libv8-dev chromedriver`

If you need a non-standard ruby version (you likely will) your best bet is likely [rvm](https://rvm.io/) or [rbenv](https://github.com/rbenv). You will also need to ensure your ruby environment is active before doing app work (e.g. like `bundle install`).

To activate a ruby environment:
+ in rvm: `source $(rvm 2.7.2 do rvm env --path)`

You will also need to set several environment variables for the app. You can do this in many ways (e.g. add to your ~/.bashrc, ~/.profile, etc.) or you can create a .env file in the project root as follows:
```
# export RAILS_ENV=test

# use 127.0.0.1 if using docker based mysql.
export DATABASE_MYSQL_HOST=127.0.0.1
# use localhost if using a locally installed/running mysql.
#export DATABASE_MYSQL_HOST=localhost
export DATABASE_MYSQL_DATABASE=recognize
export DATABASE_MYSQL_USERNAME=root
export DATABASE_MYSQL_PASSWORD=root

export aws_elasticache_endpoint=localhost
```
After creating the above file, simply `source .env` in your shell to set all variables.


## Mailcatcher(for local mail delivery)

    gem install mailcatcher


## Currency Conversion
+ Create free account at: https://currencylayer.com
+ Add api key in credentials.yml (see credentials.yml.sample for key namespace)
+ Example
  ````
  Money.from_amount(500, "USD").exchange_to("EUR")
  ````
## Recaptcha
+ Create free account at: https://www.google.com/recaptcha/admin
+ Add api key in credentails.yml(see credentails.yml.sample for key namespace)
+ More details at: https://github.com/Recognize/recognize/wiki/Recaptcha

## Bootstrapping Rewards for a company

+ Via rake task
  ````
  bin/rake recognize:bootstrap_rewards
  ````

+ From the rails console

  ````
  [1] pry(main)> Company.find(1).primary_funding_account.save
  [2] pry(main)> Rewards::FundsAccountService.manual_credit(Company.find(1).primary_funding_account, 100, 'seed deposit')

  ````

## (If previous rewards step didn't work) Sycnhronizing Provider Rewards (This step still doesn't create rewards admin. If you do this alone it will be broken to approve redemptions)

+ Add TangoCard V2 API credentials to config/credentials.yml:

  ````
  tangocard:
    endpoint: <API_ENDPOINT_URL>
    username: <API_USERNAME>
    password: <API_PASSWORD>
  ````

+ From the rails console, setup up the TangoCard reward provider:

  ````
  [1] pry(main)> tango = Rewards::RewardService.create_reward_provider('tango_card')
  [2] pry(main)> tango.activate!

  ````

+ From the rails console, sync available provider rewards:

  ````
  [1] pry(main)> Rewards::RewardService.sync_provider_rewards
  ````

+ ProviderRewards can be fetched through the RewardService -

  ````
  [1] pry(main)> Rewards::RewardService.provider_rewards
  ````

+ Sync'd rewards are availble as Rewards::ProviderReward model objects. Each ProviderReward can have one or more ProviderRewardVariant.

  ````
  [2] pry(main)> Rewards::ProviderReward.first
  ProviderReward Load (0.7ms)  SELECT  `provider_rewards`.* FROM `provider_rewards`   ORDER BY `provider_rewards`.`id` ASC LIMIT 1
=> #<Rewards::ProviderReward id: 11, provider_key: "B418491", name: "Amazon.com", disclaimer: "<p>*Amazon.com is not a sponsor of this promotion....", description: "<p>Amazon.com Gift Cards* never expire and can be ...", short_description: "<p>Amazon.com Gift Cards* never expire and can be ...", terms: nil, image_url: "https://dwwvg90koz96l.cloudfront.net/images/brands...", status: "active", reward_provider_id: 1, created_at: "2016-10-18 21:31:43", updated_at: "2016-10-18 21:31:43">
  ````

  ````
  [3] pry(main)> Rewards::ProviderReward.first.provider_reward_variants.first
  Rewards::ProviderReward Load (0.5ms)  SELECT  `provider_rewards`.* FROM `provider_rewards`   ORDER BY `provider_rewards`.`id` ASC LIMIT 1
  ProviderRewardVariant Load (0.7ms)  SELECT  `provider_reward_variants`.* FROM `provider_reward_variants`  WHERE `provider_reward_variants`.`provider_reward_id` = 11  ORDER BY `provider_reward_variants`.`face_value` ASC LIMIT 1
=> #<ProviderRewardVariant id: 23, provider_key: "U157189", name: "Amazon.com Gift Card", currency_code: "USD", status: "active", value_type: "VARIABLE_VALUE", reward_type: "gift card", face_value: nil, min_value: #<BigDecimal:7fa29a8be680,'0.1E-1',9(18)>, max_value: #<BigDecimal:7fa29a8be608,'0.1E4',9(18)>, countries: "US", provider_reward_id: 11, created_at: "2016-10-18 21:31:43", updated_at: "2016-10-18 21:31:43">
  ````

## Additional Information
### CA Bundle
The CA bundle is referred from the local.yml and is used to verify external HTTPS request.
```
ca_cert_file: '/opt/local/share/curl/curl-ca-bundle.crt'
```
There is usually no CA certificate bundle on OS X, because SSL libraries typically use Apple's Security Framework internally. It can be obtained from
https://curl.haxx.se/ca/cacert.pem

### Adding hosts for OAuth
Google: https://console.developers.google.com/
O365: https://apps.dev.microsoft.com/
Yammer: https://yammer.com - login using dev@recognizeapp.com Yammer account, Go to Apps -> My Apps
````

<h2>Localization</h2>
For any existing strings or tests, you can use the _ method in ruby to write new strings. Existing strings may use I18n.t() or t().

````
<%= _('This is my new string!') %>
````

And that's it. Then in the terminal you write:

````
rake translation:sync
````

If you wait a minute and do another sync then you'll get the Google Translations for all the languages we support for that new string you made. Commit the new file changes to your repo.

https://translation.io/rails/usage

## Webhooks
Webhook Endpoints table has an encrypted column, which is handled by the [Lockbox gem](https://github.com/ankane/lockbox) and requires a master key.
+ Add master key in `credentials.yml`. (see below for key namespace)

The key can be generated with the following command:
```ruby
Lockbox.generate_key
```
Or the following sample key can be used for local environment:
```
lockbox:
  master_key: "0000000000000000000000000000000000000000000000000000000000000000"
```