module Api
  module V2
    module Documentation
      def core_description
        <<-TEXT
## [Overview]()
- The Recognize API is a RESTful api that is organized around resources such as Users and Recognitions.
- Requests must be authenticated via an access token. See [Authentication](#-authentication-).
- Responses contain metadata about the response as well as the entity or a collection of entities.

## [Base Endpoint]()

+ Production: https://recognizeapp.com/api/v2
+ Sandbox: https://demo.recognizeapp.com/api/v2

## [Authentication]()
- Recognize api requests must be authenticated via an OAuth2 token.
- OAuth2 tokens come in three flavors: User tokens, Company tokens, and Trusted App tokens.
- Authenticate api requests by passing the token in the header:

    <pre>Authentication: Bearer {token}</pre>

  ### User tokens
    - Authentication can occur via Authorization Code Grant or Password Credentials Grant. Contact us if you want Authorization Code Grant flow.

    - Password Credentials Grant: http://oauthlib.readthedocs.org/en/latest/oauth2/grants/password.html

    <pre>/auth?email=&lt;email&gt;&password=&lt;password&gt;</pre>

    <div>
      <script type='text/javascript'>
      function open_resource() {
        var endpoint = $(event.target).attr('href');
        var str = "a[href='"+ endpoint + "']"
        $(".top-level-endpoints").find(str).trigger('click');
        $(endpoint).find(".content").css({display: "block"})
      }
      </script>
      <a href="#resource_auth" onclick="open_resource()">See more here</a>
    </div>

  ### Company tokens
    - If authenticating with a company token, the header 'X-Auth-Email' may optionally be sent to identify the user to act as:
    <pre>X-Auth-Email: sandra@example.com</pre>

    - If no X-Auth-Email is set, the requests will default to the token owner account which may be an individual user or system level account.

  ### Trusted App Tokens
    - Are given out to verified platform partner applications and give broad access.
    - Please contact support@recognizeapp.com to request access.

## [Core Response]()

  <pre>{ "ok" => String, "type" => String }</pre>

  + "ok" is one of "success" or "error".
  + "type" is the entity specification of the rest of the payload.

## [Response Entities]()

  + Entities describe the structure of the payload that is sent in a response and is specified by the "type" attribute.
  + The actual data of the response will be accessible via a key that is correlated to the request. Eg. "user" or "recognitions".

  ### Collection Entity

    + A response that describes a collection or list of entities.
      <pre>"page" => Integer - the number of the page
      "count" => Integer
      "total_pages" => Integer
      "total_count" => Integer
      </pre>

  ### Recognition Entity

    + A response that describes a recognition.

       ```javascript
       #{ Api::V2::Endpoints::Recognitions::Entity.documentation }
       ```

  ### User Entity

    + A response that describes a user.

       ```javascript
       #{ Api::V2::Endpoints::Users::Entity.documentation }
       ```

TEXT
      end
    end
  end
end
