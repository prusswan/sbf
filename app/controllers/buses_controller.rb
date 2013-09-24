class BusesController < ApplicationController
  def getRoute
    render json: open("http://www.onemap.sg/BusServiceAPI/Service1.svc/getBR?svc=#{params[:service]}&dir=1&stp=1").read
  end
end
