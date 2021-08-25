window.R = window.R || {};

window.R.paymentConfirmation = function() {
  var inputHelpers = window.R.forms.CreditCardValidation("#payment-form", submit);
  var stripeTimer = 0;

  function setStripe() {
    if (window.Stripe && $("#stripe-key").length > 0) {
      clearTimeout(stripeTimer);
      Stripe.setPublishableKey( $("#stripe-key").prop('content') );
    } else {
      stripeTimer = setTimeout(setStripe, 50);
    }
  }

  setStripe();

  function submit(form) {
      var $form = $(form);
      // remove the input field names for security
      // we do this *before* anything else which might throw an exception
      inputHelpers.removeInputNames(); // THIS IS IMPORTANT!

      // clear any previous payment errors (populated manually on stripe response.error)
      $(".payment-errors").html('');

      // disable the button rightaway (formLoading comes into action only after the stripe request completes)
      $(form['submit-button']).attr("disabled", "disabled").addClass('form-loading-button');

      // given a valid form, submit the payment details to stripe
      Stripe.createToken({
          number: $('.card-number').val(),
          cvc: $('.card-cvc').val(),
          exp_month: $('.card-expiry-month').val(),
          exp_year: $('.card-expiry-year').val()
      }, function(status, response) {
          if (response.error) {
              // re-enable the submit button
              window.recognize.patterns.formLoading.resetButton();                                // subscription #edit page
              $(form['submit-button']).removeAttr("disabled").removeClass('form-loading-button'); // subscription #new page

              // show the error
              $(".payment-errors").html(response.error.message);

              // we add these names back in so we can revalidate properly
              inputHelpers.addInputNames();
          } else {
              // token contains id, last4, and card type
              var token = response['id'];

              // insert the stripe token
              var input = $("<input name='subscription[stripe_card_token]' value='" + token + "' type=hidden />");
              $form.append(input);

              if ($form.data("remote") === true) {
                $.rails.handleRemote( $form );
              } else {
                form.submit();
              }
          }
      });
      
      return false;
  }
};