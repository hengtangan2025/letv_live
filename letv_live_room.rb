require 'digest/md5'
require 'uri'
require 'net/http'
require 'net/https'
require 'json'  

class LetvLiveRoom
  class << self
    def set_userid(str)
      @@userid = str
    end

    def set_secretkey(str)
      @@secretkey = str
    end
  end

  def initialize(live_name = nil, live_time = nil)
    live_name ||= [*('a'..'z'),*('A'..'Z'),*(0..9)].shuffle[0..9].join
    live_time ||= 40
    create_letv_live(live_name, live_time)
  end

  def create_letv_live(name, time)
    params = {
      :method => 'lecloud.cloudlive.activity.create',
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityName => name,
      :startTime => Time.now.strftime("%Y%m%d%H%M%S"),
      :endTime   => Time.at(Time.now.to_i + 60*time).strftime("%Y%m%d%H%M%S"),
      :liveNum => 1,
      :codeRateTypes => "10,13,16,19,22,25",
      :needRecord => 1,
      :needTimeShift => 0,
      :needFullView => 1,
      :activityCategory => "012",
      :playMode => 0
    }
    params[:sign] = make_sign_str(params)
    url = URI.parse("http://api.open.letvcloud.com/live/execute")
    Net::HTTP.start(url.host, url.port) do |http|
      req = Net::HTTP::Post.new(url.path)
      req.set_form_data(params)
      @activity_id = JSON.parse(http.request(req).body)["activityId"]
    end
    p @activity_id
    p "创建房间成功"
  end

  def make_sign_str(hash)
    Digest::MD5.hexdigest(hash.sort_by{|k,v| k}.map{|k,v| k.to_s + v.to_s}.join() + @@secretkey)
  end

  # 模块二
  def get_obs_url_and_code
    token_params = {
      :method => "lecloud.cloudlive.activity.getPushToken",
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id,
    }
    token_params[:sign] = Digest::MD5.hexdigest(token_params.sort_by{|k,v| k}.map{|k,v| k.to_s + v.to_s}.join() + @@secretkey)
    str = token_params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    @pushToken = JSON.parse(Net::HTTP.get(uri))["token"]
    p @pushToken
    p "成功获取token"

    push_url_params = {
      :method => "lecloud.cloudlive.activity.getPushUrl",
      :ver => '3.1',
      :userid => @@userid,
      :timestamp => Time.now.to_i * 1000,
      :activityId => @activity_id,
    }
    push_url_params[:sign] = Digest::MD5.hexdigest(push_url_params.sort_by{|k,v| k}.map{|k,v| k.to_s + v.to_s}.join() + @@secretkey)
    str = push_url_params.map{|k,v| "&" + k.to_s + "=" + v.to_s}.join()
    str[0] = ""
    uri = URI("http://api.open.letvcloud.com/live/execute" + "?" + str)
    @pushUrl = JSON.parse(Net::HTTP.get(uri))
    p @pushUrl["lives"][0]["pushUrl"]
    p "成功获取推流地址"
  end
  # 模块三

  # 模块四

  # 模块五

end

LetvLiveRoom.set_userid(823474)
LetvLiveRoom.set_secretkey("f9e35f28944743e38ceccf9ab00364ab")

# 模块一
activity = LetvLiveRoom.new("hello world1", 30)

# 模块二
activity.get_obs_url_and_code
