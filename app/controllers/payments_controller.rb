# frozen_string_literal: true

class PaymentsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    payment_result = CloudPayment.proccess(
      user_uid: current_user.cloud_payments_uid,
      amount_cents: params[:amount] * 100,
      currency: 'RUB'
    )

    if payment_result[:status] == 'completed'
      product_access = ProductAccess.create(user: current_user, product: product)
      OrderMailer.product_access_email(product_access).deliver_later
      redirect_to :successful_payment_path
    else
      redirect_to :failed_payment_path, note: 'Что-то пошло не так'
    end
  end
end
