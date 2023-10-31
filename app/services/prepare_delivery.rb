class PrepareDelivery
  ValidationError = Class.new StandardError

  RESULT = Struct.new(:truck, :weight, :order_number, :destination_address, :status) do
    def success
      self.status = :ok
      self.to_h
    end

    def failure
      self.status = :error
      self.to_h
    end
  end

  def initialize(order, destination_address, delivery_date)
    @order = order
    @destination_address = destination_address
    @delivery_date = delivery_date
  end

  def perform
    validate_delivery_date!
    validate_destination_address!
    find_truck!

    result.success
  rescue ValidationError
    result.failure
  end

  private

  attr_reader :order, :destination_address, :delivery_date

  def validate_delivery_date!
    raise ValidationError, 'Дата доставки уже прошла' if delivery_date < Time.current
  end

  def validate_destination_address!
    missing_parts = []
    missing_parts << 'город' if destination_address.city.empty?
    missing_parts << 'улица' if destination_address.street.empty?
    missing_parts << 'дом' if destination_address.house.empty?

    raise ValidationError, "Отсутствует(ют) #{missing_parts.join(', ')} в адресе" unless missing_parts.empty?
  end

  def find_truck!
    truck || raise(ValidationError, 'Нет машины')
  end

  def truck
    @truck ||= Truck.where('capacity >= ?', products_weight).order(:capacity).first
  end

  def products_weight
    @products_weight ||= order.products.sum(&:weight)
  end

  def result
    @result ||= RESULT.new(truck, products_weight, order.id, destination_address, :processing)
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
