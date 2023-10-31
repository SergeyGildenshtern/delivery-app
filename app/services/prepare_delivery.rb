class PrepareDelivery
  class ValidationError < StandardError; end

  RESULT = Struct.new(:truck, :weight, :order_number, :address, :status) do
    def success
      self.status = :ok
      self.to_h
    end

    def failure
      self.status = :error
      self.to_h
    end
  end

  def initialize(order, address, date)
    @order = order
    @address = address
    @date = date
  end

  def perform
    validate_date!
    validate_address!
    find_truck!

    result.success
  rescue ValidationError
    result.failure
  end

  private

  attr_reader :order, :address, :date

  def validate_date!
    raise ValidationError, 'Дата доставки уже прошла' if date < Time.current
  end

  def validate_address!
    raise ValidationError, 'Нет адреса' if address.city.empty? || address.street.empty? || address.house.empty?
  end

  def find_truck!
    truck || raise(ValidationError, 'Нет машины')
  end

  def truck
    @truck ||= Trucks.where('capacity >= ?', products_weight).order(:capacity).first
  end

  def products_weight
    @products_weight ||= order.products.sum(&:weight)
  end

  def result
    @result ||= RESULT.new(truck, products_weight, order.id, address, :processing)
  end
end

class Order
  def id
    'id'
  end

  def products
    [OpenStruct.new(weight: 20), OpenStruct.new(weight: 40)]
  end
end

class Address
  def city
    "Ростов-на-Дону"
  end

  def street
    "ул. Маршала Конюхова"
  end

  def house
    "д. 5"
  end
end

PrepareDelivery.new(Order.new, Address.new, Date.tomorrow).perform
