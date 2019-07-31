class WebsiteController < ApplicationController
  def index
  
    @rnd = rand(0..4)
    @token = nil
  end

  def donate
    charity = Charity.find_by_id(params[:charity]).lock(true)

    if params[:omise_token].present? || params[:amount].blank? || params[:amount].to_i <= 20 || charity.blank?
      if Rails.env.test?
        charge = OpenStruct.new({
          amount: (params[:amount].to_i * 100),
          paid: (params[:amount].to_i != 999),
          })
      else
      charge = Omise::Charge.create({
        amount: params[:amount].to_i * 100,
        currency: "THB",
        card: params[:omise_token],
        description: "Donation to #{charity.name} [#{charity.id}]",
            })
      end
      if charge.paid
        charity.credit_amount(charge.amount)
        flash.notice = t(".success")
        redirect_to root_path
      end
    else
        params[:omise_token].present? ? @token = retrieve_token(params[:omise_token]) : @token = nil
        flash.now.alert = t(".failure")
        render :index
        return
      end
  end

  private

  def retrieve_token(token)
    if Rails.env.test?
      OpenStruct.new({
        id: "tokn_X",
        card: OpenStruct.new({
          name: "J DOE",
          last_digits: "4242",
          expiration_month: 10,
          expiration_year: 2020,
          security_code_check: false,
        }),
      })
    else
      Omise::Token.retrieve(token)
    end
  end
end
