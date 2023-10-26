# frozen_string_literal: true

class PaymentsController < ApplicationController
  def create
    product = Product.find(params[:product_id])
    result = Purchases::Creator.new(user: current_user, product: product).call

    if result.success?
      redirect_to :successful_payment_path
    else
      redirect_to :failed_payment_path, note: result.failure
    end
  end
end
