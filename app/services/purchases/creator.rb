# frozen_string_literal: true

module Purchases
  class Creator
    include Dry::Monads[:result, :do]

    def initialize(user, product)
      @user = user
      @product = product
    end

    def call
      yield make_payment
      grant_access

      yield request_for_delivery
      yield create_delivery
      notify_user
    rescue StandardError => e
      payment.refund
      Failure(e.message)
    end

    private

    attr_reader :user, :product, :payment, :delivery

    def make_payment
      @payment = CloudPayment.proccess(
        user_uid: user.cloud_payments_uid,
        amount_cents: product.amount,
        currency: 'RUB'
      )
      @payment.success? ? Success(:ok) : Failure(:failed_payment)
    end

    def grant_access
      ProductAccess.create!(user: user, product: product)
    end

    def request_for_delivery
      response = Sdek.setup_delivery(address: user.address, person: user, weight: product.weight)
      response.success? ? Success(:ok) : Failure(:delivery_unavailable)
    end

    def create_delivery
      @delivery = Delivery.create(user: user, product: product)
      @delivery.persisted? ? Success(:ok) : Failure(:failed_create_delivery)
    end

    def notify_user
      OrderMailer.delivery_email(delivery).deliver_later
      Success(:ok)
    end
  end
end
