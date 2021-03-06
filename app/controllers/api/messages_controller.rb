require 'net/http'
require 'json'

class Api::MessagesController < ApplicationController
  after_action :change_seen, only: [:index], unless: -> {@messages.empty?}
  after_action :sendNotification, only: [:create], unless: -> {@message.nil?}

  def index
    if(params[:group_id])
      group = Group.find_by_id(params[:group_id])
      @messages = group.messages.order('created_at DESC').limit(50)
    else
      @messages = Message
      .where('(from_id=? AND to_id=?) OR (to_id=? AND from_id=?)', params[:from_id], params[:to_id], params[:from_id], params[:to_id])
      .order('created_at DESC')
      .limit(50)
    end
    @messages = @messages.offset(params[:page].to_i) if params[:page] && params[:page].to_i >= 0
    if @messages
      render json: @messages
    else
      render @messages.errors.full_message, status: 422
    end
  end

  def show
    # message_id is from_id and this only returns unseen messages
    merchant = Merchant.find_by_uuid(params[:merchant_id])
    @messages = merchant.messages.where(to_id: params[:id], seen: false)
    render json: @messages
  end

  def create
    @merchant = Merchant.find_by_uuid(params[:merchant_id])
    @message = @merchant.messages.new(message_params)
    @message[:group_id] = params[:group_id]
    if @message.save
      render json: @message
    else
      render @message.errors.full_message, status: 422
    end
  end

  def update
  end

  def change_seen
    count = 0
    @messages.each do |m|
      count += 1 if m.seen == true
      break if count > 3
      m.update_attributes(seen: true) if m.from_id == params[:to_id]
    end
  end

  def sendNotification
    @aId = 'ZTV4YF8S118QM'
    @mId = params[:merchant_id]
    @appSecret = 'a879d787-2258-0130-a591-43edd500fd89'
    uri = URI("https://sandbox.dev.clover.com/v3/apps/" + @aId + "/merchants/" + @mId + "/notifications?access_token=" + @appSecret)
    req = Net::HTTP::Post.new(uri)

    req.body = {
      "event": "create_message",
      "data": @message.to_json
    }.to_json
    req.content_type = 'application/json'
    res = Net::HTTP.start(uri.host, uri.port,
      :use_ssl => uri.scheme == 'https') do |http|
      http.request(req)
    end

    case res
    when Net::HTTPSuccess, Net::HTTPRedirection
      puts res.body
      # OK
    else
      puts res.value
    end
  end

  private
  def message_params
    params.require(:message).permit(:body, :group_id, :to_id, :from_id, :merchant_id)
  end
end
