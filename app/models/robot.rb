class Robot < ApplicationRecord
  belongs_to :user

  #TODO link to credentials id
  has_and_belongs_to_many :accounts

  def to_h
    {
      "id" => id,
      "type" => driver,
      "debug" => false,
      "enabled" => state == 'enabled',
      "period" => interval,
      "params" => params && JSON.parse(params),
      "target" => target.to_h.merge({
                                      "market" => target_market.to_h,
                                      "debug" => false,
                                    }),
      "sources" => [
        source.to_h.merge({
                            "market" => source_market.to_h,
                            "debug" => false,
                          }),
      ]
    }
  end
end
