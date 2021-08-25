module TldConcern
  AFRICA_TLDS = ["ac", "ao", "bf", "bi", "bj", "bw", "cd", "cf", "cg", "ci", "cm", "cv", "dj", "dz", "eg", "eh", "er", "et", "ga", "gh", "gm", "gn", "gq", "gw", "ke", "km", "lr", "ls", "ly", "ma", "mg", "ml", "mr", "mu", "mw", "mz", "na", "ne", "ng", "re", "rw", "sc", "sd", "sh", "sl", "sn", "so", "st", "sz", "td", "tg", "tn", "tz", "ug", "yt", "za", "zm", "zw"]

  NEW_ZEALAND_TLDS =["nz"]
  AUSTRALIA_TLDS = ["au"]

  AFRICA_RESELLER_TLDS = AFRICA_TLDS + NEW_ZEALAND_TLDS + AUSTRALIA_TLDS

  def self.tlds_for_africa_reseller
    AFRICA_RESELLER_TLDS
  end

  def tld
    self.domain.split(".").last
  end

  def for_africa_reseller?
    tld.in?(TldConcern.tlds_for_africa_reseller)
  end
end