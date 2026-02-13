require 'grape'
require 'ipaddr'

module App
  module API
    module V1
      class Ips < Grape::API
        resource :ips do
          desc 'Create a new IP address'
          params do
            requires :ip, type: String, desc: 'IPv4 or IPv6 address'
            optional :enabled, type: Boolean, default: true, desc: 'Enable stats collection'
          end
          post do
            ip = App::Ip.create(
              address: params[:ip],
              enabled: params[:enabled]
            )
            
            status 201
            ip.to_api_hash
          end

          route_param :id, type: Integer do
            desc 'Enable stats collection for IP'
            post :enable do
              ip = App::Ip.with_pk!(params[:id])
              ip.update(enabled: true)
              status 201
              ip.to_api_hash
            end

            desc 'Disable stats collection for IP'
            post :disable do
              ip = App::Ip.with_pk!(params[:id])
              ip.update(enabled: false)
              status 201
              ip.to_api_hash
            end

            desc 'Delete an IP address'
            delete do
              ip = App::Ip.with_pk!(params[:id])
              ip.destroy
              status 204
            end
          end
        end
      end
    end
  end
end
