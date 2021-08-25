# frozen_string_literal: true

class Constants

  EMAIL_REGEX = /\A
                  [A-Z0-9_.&%+\-']+   # mailbox
                  @
                  (?:[A-Z0-9\-]+\.)+  # subdomains
                  (?:[A-Z]{2,25})     # TLD
                  \z
                  /ix

end
