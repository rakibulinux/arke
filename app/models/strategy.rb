class Strategy < ApplicationRecord
  belongs_to :user

  #TODO link to credentials id
  belongs_to :source, class_name: :Account
  belongs_to :source_market, class_name: :Market
  belongs_to :target, class_name: :Account
  belongs_to :target_market, class_name: :Market

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
