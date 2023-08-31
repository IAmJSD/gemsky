# frozen_string_literal: true

class SkeetPostContentsComponent < ViewComponent::Base
    def initialize(skeet_body:, user:, bluesky_user:, compact: false)
      @skeet_body = skeet_body
      @user = user
      @bluesky_user = bluesky_user
      @compact = compact
    end
  
    def skeet_hash
      return @skeet_hash unless @skeet_hash.nil?
      @skeet_hash = Digest::SHA256.hexdigest(@skeet_body[:uri])
    end
  
    def make_media_url_frame(media_url)
      encoded_media_url = ERB::Util.url_encode(media_url)
      "/components/skeet_media_frame/skeet-media-#{skeet_hash}/#{encoded_media_url}"
    end

    def skeet_action(action, data=nil, &block)
        if @user.nil?
            return tag.a(href: "/login?redirect_to=#{ERB::Util.url_encode(request.path)}") do
                block.call
            end
        end

        form_with(url: '/components/skeet_action', data: data, method: :patch) do |form|
            values = form.hidden_field(:skeet_action, value: action) +
                form.hidden_field(:did, value: @bluesky_user.did) +
                form.hidden_field(:post_uri, value: @skeet_body[:uri]) +
                form.hidden_field(:post_cid, value: @skeet_body[:cid])

            preexisting_uri = @skeet_body[:viewer][action.to_s]
            if preexisting_uri.present?
                values += form.hidden_field(:action_cid, value: preexisting_uri.split('/').last)
            end

            values + tag.button(type: 'submit') do
                block.call
            end
        end
    end
  end
  