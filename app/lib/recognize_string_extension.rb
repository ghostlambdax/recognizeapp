module RecognizeStringExtension
  def no_zeros
    self.gsub(/\.00?$/, '')
  end

  # Checks to see if a string represents an Integer. Accounts for prepended positive or negative symbol.
  # This method is useful when checking for an incoming param(in String format), which is supposed to be an Integer.
  # https://stackoverflow.com/questions/1235863/test-if-a-string-is-basically-an-integer-in-quotes-using-ruby
  def is_i?
    /\A[-+]?\d+\z/ === self
  end
end