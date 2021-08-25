// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
// WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
// GO AFTER THE REQUIRES BELOW.
//

//= require rLog
//= require jquery
//= require jqueryMigrateMute
//= require 3p/jquery-migrate-1.1.0
//= require 3p/balance-text
//= require 3p/trumbowyg/trumbowyg
//= require 3p/trumbowyg/trumbowyg.upload
//= require 3p/trumbowyg/trumbowyg.giphy

//= require namespace
//= require 3p/modernizr
//= require turbolinks
//= require 3p/bootstrap-dropdown
//= require 3p/bootstrap-collapse
//= require nprogress
//= require nprogress-turbolinks
//= require 3p/cookies

//= require 3p/shims/array_includes
//= require 3p/shims/bind
//= require 3p/shims/forEach
//= require 3p/shims/map
//= require 3p/shims/trim
//= require 3p/shims/placeholder
//= require 3p/shims/filter

//= require 3p/handlebars

//= require 3p/jquery.mobile.events
//= require 3p/isotope
//= require 3p/isotope-centering

//= require 3p/base64.js
//= require 3p/bootstrap-tabs
//= require 3p/jquery-ui-1.10.1.custom
//= require 3p/bootstrap-tooltip
//= require 3p/ios-checkboxes
//= require 3p/jquery.actual
//= require 3p/jquery.infinitescroll
//= require 3p/jquery.livequery
//= require 3p/flot/jquery.flot
//= require 3p/flot/jquery.flot.time
//= require 3p/flot/jquery.flot.selection
//= require 3p/money.min
//= require 3p/polyfills/weakmap
//= require 3p/sweet-alert
//= require 3p/es6-promise/promise
//= require 3p/lazy.min

//# this is added implicitly by both isotope as well as infinitescroll. Placing this after those inclusions to override them.
//= require 3p/imagesloaded.pkgd

//= require jquery_ujs
//= require jquery-fileupload/basic
//= require jquery-fileupload/jquery.fileupload-process
//= require jquery-fileupload/jquery.fileupload-validate

//= require datatables
//= require lib/dataTableFilterDelay

//= require lib/swalHelpers
//= require lib/utils
//= require lib/browserDetector
//= require lib/mobile/base
//= require lib/Ajaxify
//= require lib/invite
//= require lib/IdpRedirecter
//= require lib/LitaTable
//= require lib/destroyIosCheckboxes
//= require lib/saveSelectValuesToDom
//= require lib/swalForm

//= require 3p/raphael/raphael
//= require 3p/justgage.1.0.1.js
//= require 3p/export-csv-html5
//= require 3p/momentjs/moment
//= require 3p/momentjs/moment-timezone-with-data

//= require lib/yammer/api

//= require lib/ui/teams/teams
//= require lib/ui/teams/teams-inline
//= require lib/ui/header
//= require lib/ui/grandeMenu
//= require lib/ui/cloneInput
//= require lib/ui/buttons
//= require lib/ui/barNotifications
//= require lib/ui/transitions
//= require lib/ui/passwordToggle
//= require lib/ui/graph
//= require lib/ui/graphData
//= require lib/ui/remoteOverlay
//= require lib/ui/formLoading
//= require lib/ui/BadgeList
//= require lib/ui/RecognitionPrivacyEnforcer
//= require lib/ui/remoteCheckboxToggle
//= require lib/ui/wysiwyg
//= require lib/ui/YammerGroupsSelect2
//= require lib/Cards
//= require lib/instantRecognition
//= require lib/Comments
//= require lib/errorList
//= require lib/FormErrors
//= require lib/CreditCardValidation
//= require lib/Uploader
//= require lib/Pagelet
//= require lib/gage
//= require lib/Select2
//= require lib/signature
//= require lib/DatePicker
//= require lib/DateRange
//= require lib/Post
//= require lib/Stream
//= require lib/CompanyAdmin
//= require lib/QuickNominations
//= require lib/analytics/piechart
//= require lib/rewards/variantListener
//= require lib/integrations
//= require lib/BadgesRemaining
//= require lib/policyPopup
//= require lib/AutoSaver
//= require lib/captcha
//= require lib/ScrollMenu

//= require pages/signups/requested
//= require pages/nomination
//= require pages/welcome/show
//= require pages/company
//= require pages/home/paymentConfirmation
//= require pages/subscriptions/subscription-new
//= require pages/subscriptions/subscription-show
//= require pages/admin_subscriptions/index
//= require pages/admin_subscriptions/subscriptions
//= require pages/users/users-show
//= require pages/users/users-edit
//= require pages/users/users-index
//= require pages/reports/index
//= require pages/admin_company/show
//= require pages/admin_index/index
//= require pages/admin_index/analytics
//= require pages/admin_index/graph
//= require pages/admin_index/engagement
//= require pages/badges/show
//= require pages/hall_of_fame/index
//= require pages/departments/index
//= require pages/contact
//= require pages/user_sessions/new
//= require pages/identity_providers/show
//= require pages/recognitions/index
//= require pages/recognitions/grid
//= require pages/recognitions/show
//= require pages/task_submission

//= require pages/teams/favorite_team
//= require pages/teams/show
//= require pages/teams/index

//= require pages/redemptions/index
//= require pages/company_admin/dashboards/show
//= require pages/company_admin/nominations/index
//= require pages/company_admin/rewards/index
//= require pages/company_admin/rewards/new
//= require pages/company_admin/rewards/dashboard

//= require pages/company_admin/company_roles
//= require pages/company_admin/anniversaries/settings
//= require pages/company_admin/anniversaries/notifications
//= require pages/company_admin/anniversaries/calendar
//= require pages/company_admin/accounts/show
//= require pages/company_admin/accounts_spreadsheet_importers/new
//= require pages/company_admin/documents/index.js
//= require pages/company_admin/comments/index
//= require pages/company_admin/custom_field_mappings/show
//= require pages/company_admin/customizations
//= require pages/company_admin/top_employees/index
//= require pages/company_admin/rewards/redemptions/index
//= require pages/company_admin/rewards/transactions/index
//= require pages/company_admin/rewards/rewards_budgets/index
//= require pages/company_admin/catalogs/index
//= require pages/company_admin/catalogs/new_edit
//= require pages/company_admin/recognitions/index
//= require pages/company_admin/settings/index
//= require pages/company_admin/tags
//= require pages/company_admin/tskz/tasks/new
//= require pages/company_admin/tskz/tasks/index
//= require pages/company_admin/tskz/completed_tasks/index
//= require pages/manager_admin/recognitions/index
//= require pages/manager_admin/redemptions/index
//= require pages/award_generator/service_anniversary


//= require pages/account_chooser/show

//= require lib/autocomplete/autocompleteInit
//= require lib/autocomplete/recognizeAutocomplete
//= require lib/autocomplete/simpleAutocomplete

//= require init

//= require lib/ui/drawer

//= require lib/oldBrowserMessage
//= require lib/defaultSwalConfirmation
