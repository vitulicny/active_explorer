class BadGuy < ActiveRecord::Base
  include ActiveExplorer

  has_many :bad_thoughts  # Table `bad_thoughts` does not exist on purpose.
end