
# Guide for updating: https://stripe.com/docs/upgrades#api-changelog
Stripe.api_version = "2018-02-28"

Stripe.api_key = Recognize::Application.config.rCreds["stripe"]["secret_key"] rescue nil
STRIPE_PUBLIC_KEY = Recognize::Application.config.rCreds["stripe"]["public_key"] rescue nil
