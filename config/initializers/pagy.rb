require "pagy/extras/overflow"
require "pagy/extras/pagy"

Pagy::DEFAULT[:items] = 50
Pagy::DEFAULT[:overflow] = :last_page
Pagy::DEFAULT[:size] = [1, 1, 1, 1]
